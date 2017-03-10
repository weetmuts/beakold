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

function cleanup {
        if [ -d "$beakdir/NowTarredfs" ]
        then
            fusermount -u "$beakdir/NowTarredfs"
            rmdir "$beakdir/NowTarredfs"
        fi
        if [ -d "$beakdir/PrevTarredfs" ]
        then
            fusermount -u "$beakdir/PrevTarredfs"
            rmdir "$beakdir/PrevTarredfs"
        fi
}    

function finish {
    if [ "$ok" = "true" ]
    then
        echo 
    else
        cleanup
        btrfs property set -ts "$beakdir/Now" ro false   
        btrfs subvolume delete "$beakdir/Now"        
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

directory=$(grep directory= "$config" | sed 's/^directory=//')
beakdir=$(grep beakdir= "$config" | sed 's/^beakdir=//')
if [ ! -d "$directory" ]
then
    echo Configration error! No directory to backup \"$directory\"
    exit 1
fi
if [ ! -d "$beakdir" ]
then
    echo Configration error! No snapshot&mount directory \"$beakdir\"
    exit 1
fi

if [ -d "$beakdir/Now" ]; then
    echo "$beakdir/Now" exists! Removing! 
    btrfs property set -ts "$beakdir/Now" ro false   
    btrfs subvolume delete "$beakdir/Now"
fi

TEST=$(cd "$beakdir" && echo Backup-*)
if [ "$TEST" != "Backup-*" ]
then
    PREV=$(cd "$beakdir" && ls --directory Backup-* | tail -n 1)
    echo Last backup was: $PREV
else
    PREV="NoPreviousBackup"
    echo This is the first backup.
fi

btrfs subvolume snapshot -r "$directory" "$beakdir/Now"

mkdir -p "$beakdir/NowTarredfs"
tarredfs -x '\.beak/' -ta 50M "$beakdir/Now" "$beakdir/NowTarredfs"

if [ "$PREV" != "NoPreviousBackup" ]
then 
    mkdir -p "$beakdir/PrevTarredfs"
    tarredfs -x '\.beak/' -ta 50M "$beakdir/$PREV" "$beakdir/PrevTarredfs"
    tarredfs-diff "$beakdir/PrevTarredfs" "$beakdir/NowTarredfs"
fi

UPLOAD=false

echo COMMAND: rclone sync "$beakdir/NowTarredfs/" "$remote"

echo "Do you wish to perform the backup?"
while true; do
    read -p "yn>" yn
    case $yn in
        [Yy]* ) UPLOAD=true; break;;
        [Nn]* ) break;;
        * ) ;;
    esac
done

if [ $UPLOAD == "true" ]; then
    echo 'Uploading...'
    rclone sync "$beakdir/NowTarredfs/" "$remote"

    cleanup
    mv "$beakdir/Now" "$beakdir/Backup-$date"

    if [ "$PREV" != "NoPreviousBackup" ]
    then
        ls --directory "$beakdir/Backup-"* | \
            head --lines=-3 | \
            xargs --no-run-if-empty --verbose btrfs subvolume delete
    fi
else
    cleanup
    btrfs property set -ts "$beakdir/Now" ro false
    btrfs subvolume delete "$beakdir/Now"
fi

ok="true"
