#!/bin/sh

# define a cleanup function
trap_cleanup () {
  echo Moving savedstate.sav ... >&2
  mv savedstate.sav "$pdf".`date_function`.sav
  exit
}

date_function () { date +%F.%H%M%S; }

crack_file () { local pdf="$1"; }

mail_function () {
  :
  log=`ls $pdf.*.log | tail -1`
  mail -s'pdfcrack: password found' $USER <<EOF
file: $pdf
date: `date_function`
password: `tail -2 $log`
EOF
}

if [ $# -ne 1 -o "$1" = -h -o "$1" = --help ]; then
  echo "Usage: `basename $0` dir"
  echo "Specify only the directory where the pdfs and state files reside."
  exit 1
fi

cd -- "$1" || exit 2
pwd

# install a trap for signals
trap trap_cleanup INT TERM

# crack all pdf in the folder
for pdf in *.pdf; do
  save=`ls "$pdf".*.sav 2>/dev/null | tail -1`
  # try to load saved states
  if [ -f "$save" ]; then
    pdfcrack --loadState="$save"
  else
    # try to find the user password in the filename
    password="${pdf%.pdf}"
    password="${password##*.}"
    if [ "${password}.pdf" = "$pdf" ]; then
      # no password found in filename
      pdfcrack -f "$pdf" && mail_function
    else
      # password found in filename
      pdfcrack -f "$pdf" --password="$password" && mail_function
    fi
  fi 2>&1 | tee -i "$pdf".`date_function`.log
done
