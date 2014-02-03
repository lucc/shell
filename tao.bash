#!/bin/bash
# a script for outputting a verse of the Tao Te Ching.

tao="tao_te_ching.txt"
range=($(echo {1..81}))
verse=0

# shuffle function based on Knufth-Fisher-Yayes shuffle algorithm
# http://mywiki.wooledge.org/BashFAQ/026 thank you!
# takes an array as input through 'shuffle ARRAY[@]', outputs arr[@]
shuffle() {
   local i tmp size max rand
   arr=("${!1}") # retrieve array from $1
   # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
   # Compensate by using a range which is a multiple of the array size.
   size=${#arr[*]}
   max=$(( 32768 / size * size ))

   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${arr[i]} arr[i]=${arr[rand]} arr[rand]=$tmp
   done
}

if [[ $# -gt 1 ]]; then
   echo "Too many arguments."
   echo "Use 'tao' for a random verse, or 'tao [1-81]' for a specific verse."
   exit 1
fi

# if no arguments, get a random number from the range.
if [[ $# -eq 0 ]]; then
   shuffle range[@] && verse=${arr[1]}
fi

if [[ $# -eq 1 ]]; then
   for n in ${range[@]}; do
      [[ $1 -eq $n ]] && verse=$1
   done

   if [[ $verse -eq 0 ]]; then
      echo "The Tao Te Ching only has 81 verses."
      echo "If you require even more wisdom, sit down and think of nothing."
      exit 1
   fi
fi

# grep returns the linenumber but also the match so we need to use sed to fix this.
startline=$(grep -n "\-\-\-$verse\-\-\-" $tao | sed 's/:.*//')
verse=$(( $verse + 1 )) # increase verse-number to check for the start of next verse.
endline=$(grep -n "\-\-\-$verse\-\-\-" $tao | sed 's/:.*//')
endline=$(( $endline -1 )) # extract 1 line so it doesn't print the start of the next verse.
lastline=$(wc -l $tao | sed 's/ .*//')
[[ $verse -eq 82 ]] && endline=$(( $lastline -1 )) # check to catch the end of file, where the above doesn't work.

echo
sed -n "$startline,$endline"'p' $tao

exit 0
