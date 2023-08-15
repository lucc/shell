#!/usr/bin/env python3

import base64
from datetime import datetime
import io
import mailbox
from pathlib import Path
import re
from shutil import copyfile
from subprocess import run


def cropped(file: Path) -> Path:
    return file.with_suffix(".cropped.pdf")
def copy(src: Path, dest: Path) -> None:
    if not dest.exists():
        copyfile(src, dest)

search_terms = ["is:attachment", "from:deutschlandticket", "date:-1month..",
                'subject:"Dein Deutschlandticket ist da!"']
proc = run(["notmuch", "search", "--output=files"] + search_terms,
           capture_output=True)

files: list[Path] = []
regex = re.compile(r"[^\d](\d{4}-\d\d|\d\d\.\d{4})[^\d]")

for file in proc.stdout.decode().splitlines():
    with open(file, "r") as fp:
        content = fp.read()
    mail = mailbox.MaildirMessage(content)
    mailpart = mail.get_payload()[1]
    if mailpart.get_content_type() == "application/pdf" and (
            match := regex.search(mailpart.get_param("name"))):
        payload = io.BytesIO(mailpart.get_payload().encode())
        if "-" in match.group(1):
            year, month = match.group(1).split("-")
        else:
            month, year = match.group(1).split(".")
        filename = f"deutschlandticket-{year}-{month}.pdf"
        out = Path.home() / "ticket" / filename
        files += [out]
        if not out.exists():
            with out.open(mode="wb") as fp:
                base64.decode(payload, fp)
            print(f"Extracted {out}.")
            run(["pdfcrop", "--clip", "--margins", "-260 -110 -20 -370", out,
                 cropped(out)])
        else:
            print(f"{out} already exists.")
    else:
        print(f"Error processing {file}, no pdf at second mime multipart.")

kindle = Path("/run/media/luc/Kindle/documents")
if kindle.exists():
    for src in files:
        target = kindle / src.name
        copy(src, target)
        copy(cropped(src), cropped(target))
    now = datetime.now()
    for ticket in kindle.glob("deutschlandticket-*.pdf"):
        year, month = ticket.name.split(".")[0].split("-")[1:]
        if (int(year), int(month)) < (now.year, now.month):
            print(f"Removing {ticket}")
            ticket.unlink()

run(["notmuch", "tag", "-inbox", "-unread"] + search_terms,
    capture_output=True)
