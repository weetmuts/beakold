#!/bin/bash
#  
#    Copyright (C) 2016 Fredrik Öhrström
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BEAKDIR="$HOME/.beak"

mkdir -p "$BEAKDIR"

cmd=
debug=
NAM="$( basename "${BASH_SOURCE[0]}" )"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SUF=""
PRE="$DIR"

if [ "sh" = "${NAM##*.}" ]
then
    SUF=".sh"
fi


if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] 
then
cat <<EOF
Usage: beak [COMMAND]... [OPTION]... [LOCAL] [REMOTE]
Backup/mirror local directories to remote locations.

-v         verbose output, use twice for even more.
--help     display this help and exit
--version  output version information and exit

Commands:
    config
    push
    mount

Examples:
    beak push s3storage:
    cat        Copy standard input to standard output.

Full documentation at: <http://github.com/weetmuts/beak>
or available locally via: man beak
EOF
exit 0
fi

case $1 in
    config) cmd=config ;;
    push) cmd=push ;;
    pull) cmd=pull ;;
    mount) cmd=mount ;;
    umount) cmd=umount ;;
    status) cmd=status ;;
    -*) echo No command given!
        exit 1;;
    *) echo Unknown command \"$1\"
       exit 1;;
esac

shift

while [[ $1 =~ -.* ]]
do
    case $1 in
        -d) debug='true'
            shift ;;
    esac
done

local="$1"

if [ "$cmd" != "config" ] && [ "$cmd" != "status" ] 
then
    if [ -z "$local" ] 
    then
        echo No local given!
        exit 1
    fi

    shift
    
    remote="$1"
fi

if [ "$debug" = "true" ]
then
    bash -x "${PRE}/beak-$cmd${SUF}" "$local" "$remote"
else
    "${PRE}/beak-$cmd${SUF}" "$local" "$remote"
fi

