#!/bin/sh

# http://ask.libreoffice.org/en/question/2641/convert-to-command-line-parameter/
# http://ask.libreoffice.org/en/question/1686/how-to-not-connect-to-a-running-instance/

prog=`basename "$0"`
help () {
	awk -P -v PROG="$prog" '
		BEGIN{
			printf("Usage: %s OPTION FILE [ FILE ... ]\n", PROG)
			print("Valid options are:")
		}

		/^case "\$1" in$/,/^esac$/{
			if(/^[[:space:]]+-/){
				gsub(/\|/, ", ", $1)
				sub(/)/, "", $1)
				gsub(/;;$/, "", $2)
				sub(/^help.*/, "display this help and exit", $2)
				sub(/cmd=office2/, "convert files to ", $2)
				sub(/pdf_2$/, "pdf (pdf export converter)))", $2)
				printf("%-20s %s\n", $1, $2)
			}
		}
	' "$prog"

	exit $1
}
office2 () {
  # find path to LO
  local lo=
  if [ `uname` = Darwin ]; then
    lo=/Applications/LibreOffice.app/Contents/MacOS/soffice
  else
    lo=libreoffice
  fi
  type="$1"
  shift
  "$lo"                                                      \
    --nologo                                                 \
    --nodefault                                              \
    --nolockcheck                                            \
    --nofirststartwizard                                     \
    -env:UserInstallation=file:///tmp/LibO_Conversion$RANDOM \
    --convert-to "$type"                                     \
    --outdir ./                                              \
    "$@"
}

office2pdf_2 () { office2 pdf:writer_pdf_Export "$@"; }

if [ `uname` = Darwin ]; then
  apple_textutil () {
    textutil -cat txt
  }
fi

office2csv  () { office2 csv      "$@"; }
office2docx () { office2 docx     "$@"; }
office2ods  () { office2 ods      "$@"; }
office2odt  () { office2 odt      "$@"; }
office2pdf  () { office2 pdf      "$@"; }
office2tex  () { office2 tex      "$@"; }
office2txt  () { office2 txt:Text "$@"; }

case "$1" in
  -h|--help)       help 0;;
  -t|--txt|--text) cmd=office2txt;;
  --tex)           cmd=office2tex;;
  -c|--csv)        cmd=office2csv;;
  --ods)           cmd=office2ods;;
  --odt)           cmd=office2odt;;
  -p|--pdf)        cmd=office2pdf;;
  --pdf2)          cmd=office2pdf_2;;
  --docx)          cmd=office2docx;;
  *)               help 2 >&2;;
esac
shift
$cmd "$@"
