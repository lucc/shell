#!/bin/bash

cat <<EOF
This script was copied from
https://wiki.archlinux.org/index.php/Nvidia#Order_of_install.2Fdeinstall_for_changing_drivers

It will try to find the installed nvidia or nouveau drivers and replace them
by the others.
EOF

BRANCH=340xx
#BRANCH=304xx

NVIDIA="nvidia-$BRANCH"
_NVIDIA="$(pacman -Qqs ^${NVIDIA}$)"
NOUVEAU="xf86-video-nouveau mesa-libgl"
_NOUVEAU="$(pacman -Qqs ^mesa-libgl$)"

if [[ ! $_NVIDIA ]]; then
  cat <<EOF

No nvidia driver found, I guess you are using nouveau.  Trying to switch:
  nouveau -> nvidia ...
EOF
  pacman -Rdds $NOUVEAU
  pacman -S $NVIDIA #lib32-$NVIDIA-libgl #$NVIDIA-lts
elif [[ ! $_NOUVEAU ]]; then
  cat <<EOF

No nouveau driver found, I guess you are using nvidia  Trying to switch:
  nvidia -> nouveau ...
EOF
  pacman -Rdds $_NVIDIA
  pacman -S $NOUVEAU #lib32-mesa-libgl
else
  echo Did not find any matching driver. What does that mean?
fi
