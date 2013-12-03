#/bin/sh

# Print a file over ssh.
# $1: the server name (possibly an alias from ~/.ssh/config
# $2: the file
# optional: ${@:3:}: options to the remote lp

PROG=`basename "$0"`

if [ $# -lt 2 ] || [ "$1" = -h ]; then
  echo "usage: $PROG (user@host|host) file [lp-options]" >&2
  exit 1
fi
HOST="$1"
FILE="$2"
shift 2
if [ -f "$FILE" ]; then
  ssh "$HOST" "lp -o sides=two-sided-long-edge ${1+"$@"} -- -" < "$FILE"
else
  echo "Error: $FILE is not a valid file." 1>&2
  exit 1
fi
