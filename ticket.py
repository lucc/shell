#!/usr/bin/env python3

"""Extract pdf tickets from emails and copy them to the ebook reader."""

import argparse
import itertools
import json
import logging
import mailbox
import re
import shutil
from calendar import monthrange
from contextlib import contextmanager
from datetime import date, datetime
from email.message import Message
from pathlib import Path
from subprocess import DEVNULL, run
from typing import Generator

search_terms = ["is:attachment", "AND", "is:inbox", "AND", "(",
                # tickets from bahn.de
                "from:buchungsbestaetigung@bahn.de",
                "OR", "from:noreply@deutschebahn.com",
                "OR", "from:noreply@booking.flixbus.com", # tickets from flixbus
                "OR", "is:ticket", # other manually marked tickets
                ")"]
deutschlandticket_re = re.compile(r"DTicket.*(\d{4}-\d\d)\.pdf").fullmatch


def get_emails() -> list[str]:
    """Get a list of mails from notmuch from which to export tickets"""
    proc = run(["notmuch", "search", "--output=files"] + search_terms,
               capture_output=True)
    return proc.stdout.decode().splitlines()


def untag_emails() -> None:
    """Untag the relevant mails in notmuch"""
    logging.debug("Removing processed mails from the inbox.")
    run(["notmuch", "tag", "-inbox", "-unread", "+ticket"] + search_terms,
        capture_output=True)


def get_attachments(mailfile: str) -> Generator[Message, None, None]:
    """Read a mail from a maildir and get all pdf attachments from it"""
    with open(mailfile, "r") as fp:
        content = fp.read()
    mail = mailbox.MaildirMessage(content)
    for part in mail.get_payload():
        if part.get_content_type() == "application/pdf":
            yield part


def extract_filename(mailpart: Message) -> str | None:
    """Get the filename from a mail attachment, handle special cases"""
    filename = mailpart.get_filename()
    if filename and (match := deutschlandticket_re(filename)):
        year, month = match.group(1).split("-")
        return f"deutschlandticket-{year}-{month}.pdf"
    return filename


date_re = re.compile(r"(?:\b|_)(\d{4}-\d\d(-\d\d)?|\d\d\.\d\d\.\d{4})")


def get_date(name: str) -> date | None:
    """Extract a date from a string

    >>> get_date("foo")
    >>> get_date("foo 2023-12 bar")
    datetime.date(2023, 12, 31)
    >>> get_date("foo 2023-12-23 bar")
    datetime.datetime(2023, 12, 23, 0, 0)
    >>> get_date("foo 23.12.2023 bar")
    datetime.datetime(2023, 12, 23, 0, 0)
    >>> get_date("23.12.2023 24.12.2023")
    >>> get_date("123-2024-01-12")
    datetime.datetime(2024, 1, 12, 0, 0)
    >>> get_date("01235-2024-01-12")
    datetime.datetime(2024, 1, 12, 0, 0)
    >>> get_date("123.20.01.2024")
    datetime.datetime(2024, 1, 20, 0, 0)
    >>> get_date("Ticket_123456789_31.12.2024.pdf")
    datetime.datetime(2024, 12, 31, 0, 0)
    """
    match date_re.findall(name):
        case []:
            logging.warning("No dates found in %s", name)
        case [(str(d), str(day))] if "." in d:
            day, month, year = d.split(".")
            return date(year=int(year), month=int(month), day=int(day))
        case [(str(d), "")]:
            year, month = d.split("-")
            return date(
                year=int(year),
                month=int(month),
                day=monthrange(int(year), int(month))[1],
            )
        case [(str(d), str(day))]:
            year, month, *_ = d.split("-")
            day = day[1:]
            return date(year=int(year), month=int(month), day=int(day))
        case _:
            logging.warning("Found more than one date in %s", name)
    return None


def get_date_from_pdf(name: Path) -> date | None:
    return get_date_from_pdf_text(name) or get_date_itinerary(name)


def get_date_from_pdf_text(name: Path) -> date | None:
    info = run(["pdfinfo", name], capture_output=True)
    lines = info.stdout.decode().splitlines()
    try:
        field, title = lines[0].split(maxsplit=1)
        field2, producer = lines[1].split(maxsplit=1)
    except (IndexError, ValueError):
        return None
    if (
        field != "Title:"
        or field2 != "Producer:"
        or producer != "INFINICA"
        or not title.startswith("Deutsche Bahn")
    ):
        return None
    text = run(["pdftotext", name, "/dev/stdout"], capture_output=True)
    lines = text.stdout.decode().splitlines()
    if match := re.match(r"^Gültigkeit: .* bis (.*)", lines[1]):
        return get_date(match.group(1))


def get_date_itinerary(name: Path) -> date | None:
    """
    https://apps.kde.org/de/itinerary/
    """
    data = run(["kitinerary-extractor", name], capture_output=True)
    j = json.loads(data.stdout)
    if isinstance(j, list):
        for item in j:
            if valid := item.get("validUntil"):
                return parse_itinerary_date_time_value(valid)
            if valid := item.get("validFrom"):
                return parse_itinerary_date_time_value(valid)
            if res := item.get("reservationFor"):
                for key in ["arrivalTime", "departureDay", "startDate"]:
                    if key in res:
                        return parse_itinerary_date_time_value(res[key])
    logging.error("Can not parse itinerary output: %s", j)


def parse_itinerary_date_time_value(value: dict[str, str] | str) -> date:
    if isinstance(value, str):
        return datetime.fromisoformat(value).date()
    if isinstance(value, dict):
        if value.get("@type") == "QDateTime":
            return datetime.fromisoformat(value["@value"]).date()
    raise ValueError(f"Can not parse date/time value: {value}")


def from_notmuch_to_disk(folder: Path) -> None:
    """Save pdf tickets from notmuch to disk"""
    for file in get_emails():
        for mailpart in get_attachments(file):
            filename = extract_filename(mailpart)
            if filename:
                out = folder / filename
                if not out.exists():
                    payload = mailpart.get_payload(decode=True)
                    with out.open(mode="wb") as fp:
                        fp.write(payload)
                    logging.info("Extracted %s.", out)
                    if filename.startswith("deutschlandticket"):
                        cropped = out.with_suffix(".cropped.pdf")
                        run(["pdfcrop", "--clip", "--margins",
                             "-260 -110 -20 -370", out, cropped])
                else:
                    logging.debug("%s already exists.", out)
            else:
                logging.warning("No attachment filename found in %s.", file)


@contextmanager
def mounted(device: Path, mountpoint: Path) -> Generator[None, None, None]:
    """A contextmanager to mount and unmount the ebook reader with udisksctl"""
    if unmount := not mountpoint.exists():
        run(["udisksctl", "mount", "--block-device", device])
    yield
    if unmount:
        run(["udisksctl", "unmount", "--block-device", device])


def parse_file(*names: Path) -> None:
    """Parse files and print info about them"""
    for name in names:
        date = get_date_from_pdf(name)
        print(name, date)


def find_external_devices() -> Generator[Path | str, None, None]:
    """Yield devices that can be connected to, paths are mountable devices,
    strings are adb phones"""
    kindle_device = Path("/dev/disk/by-label/Kindle")
    if kindle_device.exists():
        yield kindle_device
    adb = run(["adb", "devices"], capture_output=True)
    devices = adb.stdout.decode().splitlines()[1:]
    for device in devices:
        if device:
            yield device.split()[0]


def clean_up_files_in_ticket_folder(folder: Path, now: date) -> list[tuple[Path, date | None]]:
    """Rename and move the files in the local ticket folder
    Return a list of ticket files and dates that are still relevant"""
    todo: list[tuple[Path, date | None]] = []
    for pdf in folder.glob("*.pdf"):
        if d := get_date(pdf.name):
            if d < now:
                if pdf.name.startswith("deutschlandticket") and pdf.name.endswith(".cropped.pdf"):
                    logging.info("Deleting old cropped ticket %s.", pdf)
                    pdf.unlink()
                else:
                    target = folder / str(d.year)
                    target.mkdir(exist_ok=True)
                    logging.info("Moving old ticket %s to %s.", pdf.name, target)
                    shutil.move(pdf, target)
                continue
            todo.append((pdf, d))
        elif d := get_date_from_pdf(pdf):
            stem = f"{pdf.stem}-{d.isoformat()}"
            target = pdf.with_stem(stem)
            logging.info("Moving ticket %s to %s.", pdf.name, target)
            shutil.move(pdf, target)
            todo.append((target, d))

            # TODO check if we can use ebook-convert to convert directly from
            # pdf to mobi
            lines = run(["pdftohtml", "-stdout", "-dataurls", target, stem],
                capture_output=True).stdout.decode().splitlines()
            img_indices = [index for index, line in enumerate(lines) if "<img" in line]
            # keep the second image, remove all others
            del img_indices[1]
            html = target.with_suffix(".clean.html")
            mobi = html.with_suffix(".mobi")
            logging.debug("Generating html version %s", html)
            with html.open("w") as fp:
                fp.writelines(line for index, line in enumerate(lines) if index not in img_indices)
            logging.debug("Generating ebook version %s", mobi)
            run(["ebook-convert", html, mobi, "--title", target.stem], stdout=DEVNULL)
            todo.append((mobi, d))
        else:
            todo.append((pdf, d))
    return todo


def sync_to_kindle(device: Path, todo: list[tuple[Path, date | None]], now: date) -> None:
    """Sync the files from the local folder to some external devices"""
    kindle = Path("/run/media/luc/Kindle/documents")
    with mounted(device, kindle):
        tickets = kindle / "tickets"
        tickets.mkdir(exist_ok=True)
        for ticket in itertools.chain(tickets.glob("*.pd[fr]"),
                                      tickets.glob("*.mobi"),
                                      tickets.glob("*.mbp"),
                                      ):
            if (d := get_date(ticket.name)) and d < now:
                logging.info("Removing old %s from ebook reader.", ticket)
                ticket.unlink()
        for pdf, d in todo:
            target = tickets / pdf.name
            if d and d >= now:
                if not target.exists():
                    logging.info("Copying %s to ebook reader.", pdf)
                    shutil.copyfile(pdf, target)
                else:
                    logging.debug("%s already exists.", target)
            else:
                logging.info("Ticket too old or without date: %s", pdf)


def sync_to_phone(todo: list[tuple[Path, date | None]]) -> None:
    # TODO check adb-sync
    # TODO remove old tickets, check --delete and a ticket subfolder
    if todo:
        logging.info("Syncing tickets to phone.")
        run(["adb", "push", "--sync", *(path for path, _date in todo),
             "/sdcard/Documents/Tickets/"], check=True)


def handle_tickets() -> None:
    folder = Path.home() / "ticket"
    from_notmuch_to_disk(folder)

    now = date.today()
    todo = clean_up_files_in_ticket_folder(folder, now)

    for device in find_external_devices():
        if isinstance(device, Path):
            sync_to_kindle(device, todo, now)
        else:
            sync_to_phone(todo)

    untag_emails()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--parse", nargs="+", type=Path,
                        help="""parse the given files and print info, no other
                        actions are performed""")
    args = parser.parse_args()
    logging.basicConfig(format='%(levelname)-8s%(message)s',
                        level=logging.DEBUG if args.verbose else logging.INFO)
    logging.debug("Parsed command line: %s", args)
    if args.parse:
        parse_file(*args.parse)
    else:
        handle_tickets()


if __name__ == "__main__":
    main()
