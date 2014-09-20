#!/bin/sh

# general mail retriefing script by luc

tag=mailwrapper

fetchmail_v1 () {
  fetchmail -d0 --nodetach #|logger -t $tag
  ret=$?
  case $ret in
    0|1)
      #logger -t $tag fetchmail returned with status $ret.
      return 0
      ;;
    *)
      logger -t $tag -p user.error fetchmail returned with status $ret.
      return $ret
      ;;
  esac
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

fetchmail_v1
