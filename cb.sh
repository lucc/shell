#!/bin/sh

# BUGS:
# if /bin/sh is dash the variable substitution ${this##*$'\n'} does not work.

# author: luc
# version: 5

version1 () {
base_url='http://crunchbanglinux.org/forums/users/-/-1/num_posts/DESC/page/'
search_url='http://crunchbanglinux.org/forums/userlist.php?username='
rss_url='http://crunchbanglinux.org/forums/feed/rss/'

CON=`printf "\033[31m"`
COFF=`printf "\033[0m"`

this=
user= 
#declare -i page= count= posts=
page=
count=
posts=

# reverse info (supply a position at $2 and get the username
if [ "$1" = -r ] ; then
  ((page = $2 / 50 + 1, count = $2 % 50, count == 0 ? count = 50, --page : 0))
  this=`curl --silent "${base_url}${page}" | sed -n '/table/,/table/{/td class="tc[02]/s/.*">\([^><]*\).*/\1/p;}' | sed -n "$((count * 2 - 1)){p;n;p;}"`
  user=${this%$'\n'*}
  posts=${this##*$'\n'}
elif ! curl --silent "${search_url}${1:-luc}" | grep "td class=\"tc0.*${1:-luc}"; then
  echo "The user ${1:-luc} does not seem to exist." 1>&2
  exit 1
else
  user=${1:-luc}
  while page=$(($page+1)) ; do
    this=`curl --silent "${base_url}${page}/" | sed "/td class.*$user/{n;n;q;}" | sed -n '/table/,${/td class="tc[02]/s/.*">\([^><]*\).*/\1/p;}'`
    echo "$this" | grep "$user" && break
  done
  count=$((`echo "$this" | wc -l` / 2))
  #posts=${this##*$'\n'}
  #posts="${posts/,}"
fi >/dev/null

#echo "$user is #$(((page - 1) * 50 + count)) with $posts posts."
echo "$user is #$(((page - 1) * 50 + count)) with ${this##*$'\n'} posts."
}

# get the list of recently active topics from CB-website. (with author, title
# and link)
#
#curl --silent $URL | \
#  sed -n '/<item>$/,/<\/item>$/ {
#	    s/^[[:space:]]*//;
#	    /^<title>/ {
#	      s/<title><!\[CDATA\[\(.*\)\]\]><\/title>$/'"$CON"'\1'"$COFF"'/
#	      h
#	    }
#	    /^<link>/ {
#	      s/^<link>\(.*\)\/new\/posts\/<\/link>$/\1\
#		/
#	      H
#	    }
#	    /^<author>/ {
#	      s/<author>.*(\(.*\)).*<\/author>$/\1: /
#	      G
#	      s/\n//
#	      p
#	    }
#	  } '

version2_load_vars () {
  base=http://crunchbang.org/forums/userlist.php
  sorted="${base}?sort_by=num_posts&sort_dir=DESC&p="
  search="${base}?username="
  #page="${base}?p="
  default_user=luc
}

version2_clean_input () {
  grep 'td class="tc[l3]"' | sed -E -e 's#(</a>){0,1}</td>$##'       \
                                    -e 's/^.*>//'                    \
                                    -e 's/([0-9]+),([0-9]{3})/\1\2/' \

}

version2_search_user () {
  # this function only returns an exit status but no output
  # the user to search for has to be $1
  curl --silent "${search}${1:-$default_user}" | \
    grep "td class=\"tcl.*${1:-$default_user}" >/dev/null 2>&1
}

version2_reverse_querry () {
  # we need $1
  local page=$(($1 / 50 + 1))
  local count=$(($1 % 50))
  if [ $count -eq 0 ]; then
    count=50
    ((page--))
  fi
  local this="`curl --silent "$sorted$page" | version2_clean_input | sed -n "$((count * 2 - 1)){p;n;p;}"`"
  local user=${this%$'\n'*}
  local posts=${this##*$'\n'}
  version2_output
}

version2_output () {
  #echo "$user is #$(((page - 1) * 50 + count)) with $posts posts."
  echo "$user is #$(((page - 1) * 50 + count)) with ${this##*$'\n'} posts."

}

version2 () {
  version2_load_vars

  this=
  user= 
  #declare -i page= count= posts=
  count=
  posts=

  # reverse info (supply a position at $2 and get the username
  if [ "$1" = -r ] ; then
    version2_reverse_querry "$2"
    exit
  elif ! version2_search_user "$1"; then
    echo "The user ${1:-$default_user} does not seem to exist." 1>&2
    exit 1
  else
    user=${1:-$default_user}
    while page=$(($page + 1)) ; do
      this=`curl --silent "$sorted$page" | sed "/td class.*$user/{n;n;q;}" | version2_clean_input`
      echo "$this" | grep "$user" && break
    done
    count=$((`echo "$this" | wc -l` / 2))
    #posts=${this##*$'\n'}
    #posts="${posts/,}"
  fi >/dev/null

  version2_output
}

version2 "$@"

