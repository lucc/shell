#!/usr/bin/env python3

"""Extract pdf tickets from emails and copy them to the ebook reader."""

import argparse
from calendar import monthrange
from contextlib import contextmanager
from datetime import datetime
import mailbox
from email.message import Message
import logging
from pathlib import Path
import re
import shutil
from subprocess import run
from typing import Generator


search_terms = ["is:attachment", "AND", "(",
                "OR", # tickets from bahn.de
                "(", "is:inbox", "from:buchungsbestaetigung@bahn.de", ")",
                "OR",
                "(", "is:inbox", "from:noreply@deutschebahn.com", ")",
                "OR", # tickets from flixbus
                "(", "is:inbox", "from:noreply@booking.flixbus.com", ")",
                "OR", # other manually marked tickets
                "(", "is:inbox", "AND", "is:ticket", ")"
                ")"]
deutschlandticket_re = re.compile(r"DTicket.*(\d{4}-\d\d)\.pdf").fullmatch


def get_emails() -> list[str]:
    """Get a list of mails from notmuch from which to export tickets"""
    proc = run(["notmuch", "search", "--output=files"] + search_terms,
               capture_output=True)
    return proc.stdout.decode().splitlines()


def untag_emails() -> None:
    """Untag the relevant mails in notmuch"""
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


def extract_filename(mailpart: Message) -> str|None:
    """Get the filename from a mail attachment, handle special cases"""
    filename = mailpart.get_filename()
    if filename and (match := deutschlandticket_re(filename)):
        year, month = match.group(1).split("-")
        return f"deutschlandticket-{year}-{month}.pdf"
    return filename


date_re = re.compile(r"(?:\b|_)(\d{4}-\d\d(-\d\d)?|\d\d\.\d\d\.\d{4})")
def get_date(name: str) -> datetime|None:
    """Extract a date from a string

    >>> get_date("foo")
    >>> get_date("foo 2023-12 bar")
    datetime.datetime(2023, 12, 31, 0, 0)
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
        case [(str(date), str(day))] if "." in date:
            day, month, year = date.split(".")
            return datetime(year=int(year), month=int(month), day=int(day))
        case [(str(date), "")]:
            year, month = date.split("-")
            return datetime(year=int(year), month=int(month), day=monthrange(int(year), int(month))[1])
        case [(str(date), str(day))]:
            year, month, *_ = date.split("-")
            day = day[1:]
            return datetime(year=int(year), month=int(month), day=int(day))
        case _:
            logging.warning("Found more than one date in %s", name)
    return None


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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(format='%(levelname)-8s%(message)s',
                        level=logging.DEBUG if args.verbose else logging.INFO)
    folder = Path.home() / "ticket"
    from_notmuch_to_disk(folder)

    now = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    todo: list[Path] = []
    for pdf in folder.glob("*.pdf"):
        date = get_date(pdf.name)
        if date and date < now:
            if pdf.name.startswith("deutschlandticket") and pdf.name.endswith(".cropped.pdf"):
                logging.info("Deleting old cropped ticket %s.", pdf)
                pdf.unlink()
            else:
                target = folder / str(date.year)
                target.mkdir(exist_ok=True)
                logging.info("Moving old ticket %s to %s.", pdf.name, target)
                shutil.move(pdf, target)
        else:
            todo.append(pdf)

    device = Path("/dev/disk/by-label/Kindle")
    kindle = Path("/run/media/luc/Kindle/documents")
    if device.exists():
        with mounted(device, kindle):
            tickets = kindle / "tickets"
            tickets.mkdir(exist_ok=True)
            for ticket in tickets.glob("*.pd[fr]"):
                date = get_date(ticket.name)
                if date and date < now:
                    logging.info("Removing old %s from ebook reader.", ticket)
                    ticket.unlink()
            for pdf in todo:
                date = get_date(pdf.name)
                target = tickets / pdf.name
                if date and date >= now:
                    if not target.exists():
                        logging.info("Copying %s to ebook reader.", pdf)
                        shutil.copyfile(pdf, target)
                    else:
                        logging.debug("%s already exists.", target)
                else:
                    logging.info("Ticket to old or without date: %s", pdf)

    untag_emails()


if __name__ == "__main__":
    main()
