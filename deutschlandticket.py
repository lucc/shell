#!/usr/bin/env python3

import base64
import io
import mailbox
from pathlib import Path
from shutil import copyfile
from subprocess import run


def cropped(file: Path) -> Path:
    return file.with_suffix(".cropped.pdf")
def copy(src: Path, dest: Path) -> None:
    if not dest.exists():
        copyfile(src, dest)


proc = run(["notmuch", "search", "--output=files", "is:attachment",
            "from:deutschlandticket", "date:-1month..",
            'subject:"Dein Deutschlandticket ist da!"'], capture_output=True)

files: list[Path] = []

for file in proc.stdout.decode().splitlines():
    with open(file, "r") as fp:
        content = fp.read()
    mail = mailbox.MaildirMessage(content)
    mailpart = mail.get_payload()[1]
    if mailpart.get_content_type() == "application/pdf":
        payload = io.BytesIO(mailpart.get_payload().encode())
        filename = mailpart.get_param("name")
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
