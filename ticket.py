#!/usr/bin/env python3

"""Extract pdf tickets from emails and copy them to the ebook reader."""

import argparse
import itertools
import json
import logging
import mailbox
import os
import re
import shutil
import tempfile
from calendar import monthrange
from contextlib import contextmanager
from datetime import date, datetime
from email.message import Message
from pathlib import Path
from subprocess import DEVNULL, run
from typing import Generator, Iterable

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


def get_dates(name: str) -> Generator[date, None, None]:
    """Extract dates from a string

    >>> list(get_dates("foo"))
    []
    >>> list(get_dates("foo 2023-12 bar"))
    [datetime.date(2023, 12, 31)]
    >>> list(get_dates("foo 2023-12-23 bar"))
    [datetime.date(2023, 12, 23)]
    >>> list(get_dates("foo 23.12.2023 bar"))
    [datetime.date(2023, 12, 23)]
    >>> list(get_dates("23.12.2023 24.12.2023"))
    [datetime.date(2023, 12, 23), datetime.date(2023, 12, 24)]
    >>> list(get_dates("123-2024-01-12"))
    [datetime.date(2024, 1, 12)]
    >>> list(get_dates("01235-2024-01-12"))
    [datetime.date(2024, 1, 12)]
    >>> list(get_dates("123.20.01.2024"))
    [datetime.date(2024, 1, 20)]
    >>> list(get_dates("Ticket_123456789_31.12.2024.pdf"))
    [datetime.date(2024, 12, 31)]
    """
    for match in date_re.findall(name):
        match match:
            case (str(d), str(day)) if "." in d:
                day, month, year = d.split(".")
                yield date(year=int(year), month=int(month), day=int(day))
            case (str(d), ""):
                year, month = d.split("-")
                yield date(
                    year=int(year),
                    month=int(month),
                    day=monthrange(int(year), int(month))[1],
                )
            case (str(d), str(day)):
                year, month, *_ = d.split("-")
                day = day[1:]
                yield date(year=int(year), month=int(month), day=int(day))


def get_dates_itinerary(name: Path) -> Generator[date, None, None]:
    """
    https://apps.kde.org/de/itinerary/
    """
    data = run(["kitinerary-extractor", name], capture_output=True)
    j = json.loads(data.stdout)
    if isinstance(j, list):
        for item in j:
            if valid := item.get("validUntil"):
                yield parse_itinerary_date_time_value(valid)
            if valid := item.get("validFrom"):
                yield parse_itinerary_date_time_value(valid)
            if res := item.get("reservationFor"):
                for key in ["arrivalTime", "departureDay",
                            "endDate", "startDate"]:
                    if key in res:
                        yield parse_itinerary_date_time_value(res[key])


def parse_itinerary_date_time_value(value: dict[str, str] | str) -> date:
    if isinstance(value, str):
        return datetime.fromisoformat(value).date()
    if isinstance(value, dict):
        if value.get("@type") == "QDateTime":
            return datetime.fromisoformat(value["@value"]).date()
    raise ValueError(f"Can not parse date/time value: {value}")


def get_dates_from_pdf(name: Path) -> Generator[date, None, None]:
    text = run(["pdftotext", name, "/dev/stdout"], capture_output=True)
    yield from get_dates(text.stdout.decode())
    yield from get_dates_itinerary(name)


def max_date(dates: Iterable[date]) -> date | None:
    """Get the highest date from any iterable of dates"""
    return max(list(dates), default=None)


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


def parse_file(*names: Path, all_dates: bool) -> None:
    """Parse files and print info about them"""
    for name in names:
        dates = sorted(d for d in get_dates_from_pdf(name))
        if not all_dates:
            dates = [max_date(dates)]
        print(name, *dates)


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
        if d := max_date(get_dates(pdf.name)):
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
        elif d := max_date(get_dates_from_pdf(pdf)):
            stem = f"{pdf.stem}-{d.isoformat()}"
            target = pdf.with_stem(stem)
            logging.info("Moving ticket %s to %s.", pdf.name, target)
            shutil.move(pdf, target)
            todo.append((target, d))

            #mobi = convert_pdf_to_ebook(target, stem)
            #todo.append((mobi, d))
        else:
            todo.append((pdf, d))
    return todo


def convert_pdf_to_ebook(pdf: Path, stem: str) -> Path:
    """Convert a qr-code inside a pdf into an ebook"""
    # TODO check if we can use ebook-convert to convert directly from
    # pdf to mobi
    lines = run(["pdftohtml", "-stdout", "-dataurls", pdf, stem],
        capture_output=True).stdout.decode().splitlines()
    img_indices = [index for index, line in enumerate(lines) if "<img" in line]
    # keep the second image, remove all others (this is for DB tickets and may
    # fail if there is no second image)
    del img_indices[1]
    html = pdf.with_suffix(".clean.html")
    mobi = html.with_suffix(".mobi")
    logging.debug("Generating html version %s", html)
    with html.open("w") as fp:
        fp.writelines(line for index, line in enumerate(lines) if index not in img_indices)
    logging.debug("Generating ebook version %s", mobi)
    run(["ebook-convert", html, mobi, "--title", pdf.stem], stdout=DEVNULL)
    return mobi


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
            if (d := max_date(get_dates(ticket.name))) and d < now:
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


def sync_to_phone(folder: Path, todo: list[tuple[Path, date | None]]) -> None:
    """Sync files with the ticket folder on an android phone"""
    logging.info("Syncing tickets to phone.")
    target = "/sdcard/Documents/Tickets"
    with tempfile.TemporaryDirectory(dir=folder) as src:
        for file, _date in todo:
            os.link(file, os.path.join(src, file.name))
        run(["adb-sync", "--delete", "--dry-run", src+"/", target], check=True)


def handle_tickets() -> None:
    folder = Path.home() / "ticket"
    from_notmuch_to_disk(folder)

    now = date.today()
    todo = clean_up_files_in_ticket_folder(folder, now)

    for device in find_external_devices():
        if isinstance(device, Path):
            sync_to_kindle(device, todo, now)
        else:
            sync_to_phone(folder, todo)

    untag_emails()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--parse", nargs="+", type=Path,
                        help="""parse the given files and print info, no other
                        actions are performed""")
    parser.add_argument("--all-dates", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(format='%(levelname)-8s%(message)s',
                        level=logging.DEBUG if args.verbose else logging.INFO)
    logging.debug("Parsed command line: %s", args)
    if args.parse:
        parse_file(*args.parse, all_dates=args.all_dates)
    else:
        handle_tickets()


if __name__ == "__main__":
    main()
