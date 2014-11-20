#!/bin/bash -x

# copied from https://wiki.archlinux.org/index.php/Nvidia#Order_of_install.2Fdeinstall_for_changing_drivers

BRANCH=340xx
#BRANCH=304xx

NVIDIA="nvidia-$BRANCH"
_NVIDIA="$(pacman -Qqs ^${NVIDIA}$)"
NOUVEAU="xf86-video-nouveau mesa-libgl"
_NOUVEAU="$(pacman -Qqs ^mesa-libgl$)"

if [[ ! $_NVIDIA ]]; then
    pacman -Rdds $NOUVEAU
    pacman -S $NVIDIA #lib32-$NVIDIA-libgl #$NVIDIA-lts
elif [[ ! $_NOUVEAU ]]; then
    pacman -Rdds $_NVIDIA
    pacman -S $NOUVEAU #lib32-mesa-libgl
fi
