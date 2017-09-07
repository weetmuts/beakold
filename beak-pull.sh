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
date=$(date -Iseconds)

BEAK="$HOME/.beak"
ok="false"

function cleanup {
        if [ -d "$beakdir/NowTarredfs" ]
        then
            fusermount -u "$beakdir/NowTarredfs"
            rmdir "$beakdir/NowTarredfs"
            rm -f "$beakdir/NowTarredfs.list" 
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

name="$1"
remote="$2"

config="$BEAK/${name}.cfg"
pushes="$BEAK/${name}.pushes"
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
    PREV=$(cd "$beakdir" && ls --directory Backup-* | grep -v .list | tail -n 1)
    echo Last backup was: $PREV
else
    PREV="NoPreviousBackup"
    echo This is the first backup.
fi

btrfs subvolume snapshot -r "$directory" "$beakdir/Now"

mkdir -p "$beakdir/NowTarredfs"
tarredfs -q -tl "$beakdir/NowTarredfs.list" -x '\.beak/' -ta 50M "$beakdir/Now" "$beakdir/NowTarredfs"

if [ "$PREV" != "NoPreviousBackup" ]
then
    echo ===============
    diff "$beakdir/NowTarredfs.list" "$beakdir/${PREV}.list"
    echo ===============
fi

UPLOAD=false

echo COMMAND: rclone sync "$beakdir/NowTarredfs/" "$remote/$name/"

echo "Do you wish to perform the backup?"
while true; do
    read -p "yn>" yn
    case $yn in
        [Yy]* ) UPLOAD=true; break;;
        [Nn]* ) break;;
        * ) ;;
    esac
done

if [ $DOWNLOAD == "true" ]; then
    echo 'Downloading...'
    mkdir -p "$beakdir/beak"
    now=$(date -Iseconds)
    touch "$beakdir/beak/mirror_${date}_started_${now}"
    rclone -q copy "$beakdir/beak/" "$remote/$name/.beak/"

    rclone sync "$beakdir/NowTarredfs/" "$remote/$name/"

    now=$(date -Iseconds)
    touch "$beakdir/beak/mirror_${date}_stopped_${now}"
    rclone -q copy "$beakdir/beak/" "$remote/$name/.beak/"
    
    rm -rf "$beakdir/beak"
    mv "$beakdir/Now" "$beakdir/Backup-$date"
    mv "$beakdir/NowTarredfs.list" "$beakdir/Backup-${date}.list"
    cleanup
    echo "$date $remote/$name" >> "$pushes"

    if [ "$PREV" != "NoPreviousBackup" ]
    then
        ls --directory "$beakdir/Backup-"* | grep -v .list | head --lines=-1 | while read line
        do
            btrfs property set -ts "$line" ro false
            btrfs subvolume delete "$line"
            rm -f "${line}.list"
        done
    fi
else
    cleanup
    btrfs property set -ts "$beakdir/Now" ro false
    btrfs subvolume delete "$beakdir/Now"
fi

ok="true"
