#!/usr/bin/env python3
# coding=utf-8
# vi: foldmethod=marker
# info {{{1

# help {{{1
# Index of `ioreg -rc AppleSmartBattery` #####################################
#                                                                            #
#   1	+-o AppleSmartBattery ...           21	BatteryInstalled             #
#   2	{                                   22	CycleCount                   #
#   3	ExternalConnected                   23	DesignCapacity               #
#   4	TimeRemaining                       24	AvgTimeToFull                #
#   5	InstantTimeToEmpty                  25	ManufactureDate              #
#   6	ExternalChargeCapable               26	BatterySerialNumber          #
#   7	CellVoltage                         27	PostDischargeWaitSeconds     #
#   8	PermanentFailureStatus              28	Temperature                  #
#   9	BatteryInvalidWakeSeconds           29	MaxErr                       #
#  10	AdapterInfo                         30	ManufacturerData             #
#  11	MaxCapacity                         31	FullyCharged                 #
#  12	Voltage                             32	InstantAmperage              #
#  13	DesignCycleCount70                  33	DeviceName                   #
#  14	Quick Poll                          34	IOGeneralInterest            #
#  15	Manufacturer                        35	Amperage                     #
#  16	Location                            36	IsCharging                   #
#  17	CurrentCapacity                     37	DesignCycleCount9C           #
#  18	LegacyBatteryInfo                   38	PostChargeWaitSeconds        #
#  19   LatestErrorType                     39	AvgTimeToEmpty               #
#  20	FirmwareSerialNumber                40	}                            #
#                                                                            #
# DATA #######################################################################
#                                                                            #
#  CurrentCapacity             FullyCharged              MaxCapacity         #
#  CycleCount                  InstantAmperage           AvgTimeToEmpty      #
#  ExternalConnected           IsCharging                Voltage             #
#                                                                            #
##############################################################################

import argparse
import datetime
import io
import plistlib
import subprocess

def getBatteryInformation():
    output = subprocess.check_output(['ioreg', '-arc', 'AppleSmartBattery'])
    filelike = io.BytesIO(output)
    return plistlib.readPlist(filelike)[0]

class TerminalColors():
    escape = '\033'
    red = 1
    yellow = 3
    green = 2
    fg = 3
    bg = 4

class BatteryInformation():

    characters = {
            'ascii':      {'left': '<',            'right': '>'},
            'blank':      {'left': ' ',            'right': ' '},
            'blitz':      {'left': '\xe2\x9a\xa1', 'right': '\xe2\x9a\xa1'},
            'block':      {'left': '\xe2\x96\x88', 'right': '\xe2\x96\x88'},
            'fat':        {'left': '\xe2\x97\x80', 'right': '\xe2\x96\xb6'},
            'high':       {'left': '\xe2\x97\xa5', 'right': '\xe2\x97\xa4'},
            'low':        {'left': '\xe2\x97\xa2', 'right': '\xe2\x97\xa3'},
            'smallblock': {'left': '\xe2\x96\xae', 'right': '\xe2\x96\xae'},
            'thin':       {'left': '\xe2\x9d\xae', 'right': '\xe2\x9d\xaf'},
            }

    term_fg = '\033[3'
    term_bg = '\033[4'
    term_stop = 'm'
    term_plain = '\033[m'
    bash_fg = '\[\033[3'
    bash_bg = '\[\033[4'
    bash_stop = 'm\]'
    bash_plain = '\[\033[m\]'
    zsh_fg = '%F{'
    zsh_bg = '%K{'
    zsh_stop = '}'
    zsh_plain = '%f%k'
    tmux_fg = '#[fg='
    tmux_bg = '#[bg='
    tmux_stop = ']'
    tmux_plain = '#[fg=default,bg=default]'

    ascii_left = '<'
    ascii_right = '>'
    utf8_left = '◀'
    utf8_right = '▶'
    #utf8_left = '\xe2\x97\x80'
    #utf8_right = '\xe2\x96\xb6'

    def __init__(self, color=False, escape=None, utf8=True):
        plist = getBatteryInformation()
        self.current = plist['CurrentCapacity']
        self.cycles = plist['CycleCount']
        self.plugged = plist['ExternalConnected']
        self.charged = plist['FullyCharged']
        self.ampere = plist['InstantAmperage']
        self.charging = plist['IsCharging']
        self.max = plist['MaxCapacity']
        self.timeempty = plist['AvgTimeToEmpty']
        self.timefull = plist['AvgTimeToFull']
        self.volt = plist['Voltage']
        if utf8:
            self.left = self.utf8_left
            self.right = self.utf8_right
        else:
            self.left = self.ascii_left
            self.right = self.ascii_right
        if color:
            if escape == None:
                self.red = self.term_fg + '1' + self.term_stop
                self.yellow = self.term_fg + '3' + self.term_stop
                self.green = self.term_fg + '2' + self.term_stop
                self.plain = self.term_plain
            elif escape == 'bash':
                self.red = self.bash_fg + '1' + self.bash_stop
                self.yellow = self.bash_fg + '3' + self.bash_stop
                self.green = self.bash_fg + '2' + self.bash_stop
                self.plain = self.bash_plain
            elif escape == 'zsh':
                self.red = self.zsh_fg + 'red' + self.zsh_stop
                self.yellow = self.zsh_fg + 'yellow' + self.zsh_stop
                self.green = self.zsh_fg + 'green' + self.zsh_stop
                self.plain = self.zsh_plain
            elif escape == 'tmux':
                self.red = self.tmux_fg + 'red' + self.tmux_stop
                self.yellow = self.tmux_fg + 'yellow' + self.tmux_stop
                self.green = self.tmux_fg + 'green' + self.tmux_stop
                self.plain = self.tmux_plain
            else:
                raise ArgumentError()
        else:
            self.red = ''
            self.yellow = ''
            self.green = ''
            self.plain = ''

    def conciceBatteryInfo(self):
        return '%s: %d/%d mAh, %d cycles' % (datetime.datetime.now().strftime(
                '%F %H:%M:%S'), self.current, self.max, self.cycles)

    def verboseBatteryInfo(self):
        text = ['Battery Information',
                '',
                '  ' + ('Charging' if self.charging else 'Remaining') +
                    ': %d/%d (%.1f%% = %dmin)',
                '  Cycles: %d',
                '  Fully charged: ' + ('Yes' if self.charged else 'No'),
                '  Charging: ' + ('Yes' if self.charging else 'No'),
                '  Amperage (mA): %d',
                '  Voltage (mV): %d',
                '']
        return '\n'.join(text) % (self.current, self.max, (100 * self.current
            / self.max), (self.timefull if self.charging else self.timeempty),
            self.cycles, self.ampere, self.volt)

    def batteryBar(self):
        tenth = int(10 * self.current / self.max)
        if tenth <= 2:
            color = self.red
        elif tenth <= 4:
            color = self.yellow
        else:
            color = self.green
        if self.timeempty <= 5:
            text = ' ' * 4 + self.red + str(self.timeempty) + ' min '
        else:
            text = ' ' * (10 - tenth)
            text += color
            text += (self.right if self.charging else self.left) * tenth
        text += self.plain
        text = ('=[' if self.plugged else '[') + text + ']'
        return text

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # different output formats
    parser.add_argument('-b', '--bar',
            action='store_const', const='bar', dest='output',
            help='output a graphical bar')
    parser.add_argument('-v', '--verbose',
            action='store_const', const='verbose', dest='output',
            help='output verbose information')
    parser.add_argument('--non-verbose',
            action='store_const', const='nonverbose', dest='output',
            help='output minimal information')
    parser.add_argument('-o', '--output',
            choices=['bar', 'verbose', 'nonverbose'], default='nonverbose',
            dest='output',
            help='like --bar, --verbose, --non-verbose')
    # output characters for the bar
    parser.add_argument('-a', '--ascii',
            dest='utf8', action='store_false',
            help='output the bar in ascii characters')
    parser.add_argument('-u', '--utf8',
            action='store_true',
            help='output the bar in utf8 characters')
    #parser.add_argument('-U', '--uft8-char',
    #        nargs=1,
    #        help='')
    # colors for the bar
    parser.add_argument('-c', '--color', action='store_true',
            help='use color for the bar')
    parser.add_argument('-e', '--escape', choices=['bash', 'zsh', 'tmux'],
            help='escape colors to be used in shell prompts')
    parser.add_argument('-n', '--no-color', action='store_false',
            dest='color', help='do not use color')
    args = parser.parse_args()
    info = BatteryInformation(color=args.color, escape=args.escape,
            utf8=args.utf8)
    if args.output == 'bar':
        print(info.batteryBar())
    elif args.output == 'verbose':
        print(info.verboseBatteryInfo())
    else:
        print(info.conciceBatteryInfo())
