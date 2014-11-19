#!/bin/sh

# general mail retriefing script by luc

tag=mailwrapper

mktemp_wrapper () {
  mktemp -t $$XXXXXXXXXXXX
}

logger_wrapper () {
  logger -t $tag "$@"
}

conditional_logger_wrapper () {
  local file=`mktemp_wrapper`
  local ret=0
  "$@" > "$file"
  ret=$?
  if [ $ret -ne 0 ]; then
    logger_wrapper -p user.error < "$file"
  fi
  rm -f "$file"
  return $ret
}

fetchmail_wrapper () {
  fetchmail --nodetach --daemon 0 "$@"
  ret=$?
  case $ret in
    0)  return 0;; # successfully retrieved some massages
    1)  return 0;; # no new messages
    #11) return 0;; # DNS error at startup (could not resolve host)
    *)
      logger_wrapper -p user.error fetchmail returned with status $ret.
      return $ret
      ;;
  esac
}

fetchmail_cert () {
  fetchmail_wrapper                              \
    --sslcertck                                  \
    --sslcertfile                                \
    /usr/local/Cellar/mutt/1.5.23_2/share/doc/mutt/samples/ca-bundle.crt \
    --sslcertpath ~/.homesick/repos/secure/certs \
    "$@"

}

fetchmail_log_1 () {
  fetchmail_cert "$@" | logger_wrapper
}

fetchmail_log_2 () {
  fetchmail_wrapper "$@" | logger_wrapper
}

fetchmail_log_3 () {
  conditional_logger_wrapper fetchmail_cert -v
}

getmail_v1 () {
    getmail             \
    --verbose           \
    --verbose           \
    --rcfile=aol        \
    --rcfile=campus     \
    --rcfile=fachschaft \
    --rcfile=fgmail     \
    --rcfile=gmail42    \
    --rcfile=gmx        \
    --rcfile=cipifi     \
    --rcfile=lastfm     \
    --rcfile=lgmail     \
    --rcfile=cipmath    \
    --rcfile=web        \

}

getmail_conditional_logger_wrapper () {
  local account="$1"
  shift
  conditional_logger_wrapper getmail --rcfile="$account" "$@"
}

#logger_wrapper Looking for new mail ...
fetchmail_log_3
