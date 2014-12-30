#!/bin/sh
msmtp -v --file "$HOME/.config/msmtp/msmtprc" "$@"
