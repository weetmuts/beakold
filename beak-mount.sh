#!/bin/bash
#  
#    Copyright (C) 2016-2017 Fredrik Öhrström
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
date=$(date +%Y-%m-%d_%H-%M)

BEAK="$HOME/.beak"
ok="false"

function finish {
    if [ "$ok" = "true" ]
    then
        echo 
    else
        echo 
    fi
}
trap finish EXIT

local="$1"
remote="$2"

config="$BEAK/${local}.cfg"
if [ ! -f "$config" ]
then
    echo No such config!
    exit 1
fi

if [ ! -z "$remote" ]
then
    hasremote=$(grep "$remote" "$config")
    if [ "$hasremote" != "remote=$remote" ]
    then
        echo No such remote!
        exit 1
    fi
fi

remotename="${remote%%:*}"

beakdir=$(grep beakdir= "$config" | sed 's/^beakdir=//')
if [ ! -d "$beakdir" ]
then
    echo Configuration error! No mount directory \"$beakdir\"
    exit 1
fi

mountdir="$beakdir/Remote_${local}_${remotename}"
mkdir -p "$mountdir"
if [ ! -d "$mountdir" ]; then
    echo Could not create mount directory "$mountdir"
    exit 1
fi

tarredfsmountdir="$beakdir/.Remote_${local}_${remotename}"
mkdir -p "$tarredfsmountdir"
if [ ! -d "$tarredfsmountdir" ]; then
    echo Could not create mount directory "$tarredfsmountdir"
    exit 1
fi

rclone mount "$remote" "$tarredfsmountdir" &

sleep 1
while [ ! -f "$tarredfsmountdir/taz00000000.tar" ]
do
    sleep 1
done

tarredfs -r "$tarredfsmountdir" "$mountdir"

echo "Mounted $mountdir"
ok="true"
