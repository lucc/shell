#!/bin/sh

notmuch () {
  command notmuch show --format=json --body=false --entire-thread=false $@
}
jq () {
  command jq '[
	        .. |
		.headers? |
		objects |
		.From, .To, .Cc, .["Reply-To"] |
		strings
	      ] |
	      unique |
	      join(", ")'
}
sort () {
  command sort --unique --ignore-case
}
sed1 () {
  command sed 's/^"/To: /;s/"$//;s/\\"/"/g'
}
fetchaddr () {
  /usr/lib/fetchaddr -d '' -x to
}
awk () {
  command awk -F '\t' -v q=\' -v qq=\" -v la=\< -v ra=\> '
    function quotematch(one, two) {
      return    one    ==    two    ||
	        one    ==  q two q  ||
	        one    == qq two qq ||
	      q one q  ==    two    ||
	     qq one qq ==    two    ||
	      q one q  == qq two qq ||
	     qq one qq ==  q two q
    }
    function removequotes(string) {
      sub("^"q,  "", string)
      sub("^"qq, "", string)
      sub(q"$",  "", string)
      sub(qq"$", "", string)
      return string
    }
    {
      one = tolower($1)
      two = tolower($2)
      if (quotematch(one, two) || "<"removequotes(one)">" == removequotes(two)) {
	print removequotes($1)
      } else {
	print removequotes($1) FS removequotes($2)
      }
    }
    '
}
sed2 () {
  command sed "s/^'\([^\t]*\)'$/\1/"
}
notmuch "$@" | jq | sed1 | fetchaddr | sort | awk | sort  #| sed2 | sort
