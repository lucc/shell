#!/bin/sh

sig_exit=10
start=`date +%F.%H%M%S`

# define a cleanup function
trap_cleanup () {
  # setting up a trap to ignore all signals during cleanup.
  trap 'echo Cleaning up, please wait ...' INT HUP QUIT
  local filename=savedstate-${start}.sav
  # do the actual file copying inside a loop just in case it will be
  # interrupted by another signal
  while [ ! -r "$filename" ] || ! diff savedstate.sav "$filename" >/dev/null; do
    cp -f savedstate.sav "$filename"
  done
  exit $sig_exit
}

mail_function () {
  :
  log=`ls $pdf.*.log | tail -1`
  mail -s'pdfcrack: password found' $USER <<EOF
file: $pdf
start: $start
password: `tail -2 $log`
EOF
}

pdfcrack_function () {
  local logfile="${logfile:-pdfcrack.log}"
  nice -n 19 pdfcrack "$@" 2>&1 | tee -ai "$logfile"
}

usage () {
  echo "Usage: `basename $0` dir ..."
  echo "Specify one ore more directories to work in (one after another)."
  echo "Each directory MUST contain a file 'file.pdf' and can contain any of"
  echo "'savedstate.sav', 'userpass.txt', 'ownerpass.txt' and 'pdfcrack.log'."
  echo "All other files will be ignored."
  echo "TODO"
}

old_loop () {
for pdf in *.pdf; do
  save=`ls "$pdf".*.sav 2>/dev/null | tail -1`
  # try to load saved states
  if [ -f "$save" ]; then
    pdfcrack --loadState="$save"
  else
    # no password found in filename
    pdfcrack -f "$pdf" && mail_function
  fi 2>&1 | tee -ai "$pdf.log"
done
}

# parse command line and print usage information
if [ $# -eq 0 ]; then
  usage >&2
  exit 2
elif [ "$1" = -h -o "$1" = --help ]; then
  usage
  exit
fi

# install a trap for signals
trap trap_cleanup INT TERM

# crack all pdf in the folder
for dir; do
  cd "$dir" || continue
  if [ -f ownerpass.txt ]; then
    echo This file is cracked.
  elif [ -f savedstate.sav ]; then
    pdfcrack_function --loadState=savedstate.sav
  elif [ -f userpass.txt ]; then
    userpass=`cat userpass.txt`
    pdfcrack_function --password="$userpass" -f file.pdf
  else
    pdfcrack_function --owner -f file.pdf
    if [ $? -eq 0 ]; then
      tail -n 5 pdfcrack.log > ownerpass.txt
    fi
  fi
  cd - 1>/dev/null 2>&1
done
