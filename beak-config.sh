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
name=""
directory=""
beakdir=""

function finish {
    if [ "$ok" = "true" ]
    then
        echo
    else
        echo
    fi
}
trap finish EXIT

#One possible gotcha is the ownership of the subvolume at creation
#time. If you do this as root then you need to chown after you're done;
#or you need to be logged in as the user who will own the Documents
#directory in each of the four cases. If you're using SELinux another
#gotcha is with copying files, which causes them to inherit the
#security context of the directory copied into, whereas mv preserves
#existing context. You can just restorecon -Rv /home/user once you're
#done to make sure the subvolume and its contents have the right
#labeling.

function convertToSubvolume {
    tmp="${directory}_x"
    while [ -d "$tmp" ]; do tmp="${tmp}_x"; done
    btrfs subvolume create "$tmp"
    if [ $(stat --format=%i "$tmp") -ne 256 ]
    then
        echo Failed to create subvolume!
        exit
    fi
    echo Moving contents into "$tmp"
    find "$directory" -mindepth 1 -maxdepth 1 -exec mv "{}" "$tmp" ";"
    #LC_ALL=C ls -l other_file | {
    #    read -r permissions links user group stuff;
    #    chown -- "$user:$group" file_to_change
    #}
    #getfacl other_file | setfacl -bnM - file_to_change
    # getfacl other_file | setfacl -bnM - file_to_change
    chown --reference="$directory" "$tmp"
    chmod --reference="$directory" "$tmp"    
    echo Removing directory "$directory"
    rmdir "$directory"
    echo Renaming "$tmp" into "$directory"
    mv "$tmp" "$directory"
    if [ $(stat --format=%i "$directory") -ne 256 ]
    then
        echo Failed to convert directory into subvolume!
        echo "$directory"
        exit
    fi
    echo Successfully converted "$directory" into a subvolume.
    echo
}

function newConfig {
    echo 
    while true
    do
        read -p "name>" name
        
        if [ -f "$BEAK/${name}.cfg" ]; then
            echo Configuration already exits!
            continue
        fi
        
        spaced=$(echo "$name" | grep -o " ")
        slashed=$(echo "$name" | grep -o "/")
        if [ "$spaced" != "" ] || [ "$slashed" != "" ]; then
            echo No slashes or spaces in the name please!
            continue
        fi
        
        break
    done
    
    while true
    do
        read -p "directory>" directory
        
        if [ ! -d "$directory" ]; then
            echo Directory does not exist!
            continue
        fi
        
        if [ $(stat -f --format=%T "$directory") != "btrfs" ]
        then
            echo Directory is not in a btrfs file system!
            continue
        fi

        check=$(findmnt -o FS-OPTIONS -nt btrfs --target /alfa/Test | grep -o user_subvol_rm_allowed)
        if [ "$check" != "user_subvol_rm_allowed" ]
        then
            echo 
            echo You cannot delete your own snapshots in this btrfs mount!
            echo The flag user_subvol_rm_allowed is not set on the mount!
            echo
            echo For a temporary solution you can execute the command:
            echo "sudo mount -t btrfs -o remount,user_subvol_rm_allowed $mountdevice \"$mountpoint\""
            echo
            echo or for a permanent solution user_subvol_rm_allowed
            echo the mount options in /etc/fstab
            exit        
        fi
        
        if [ $(stat --format=%i "$directory") -ne 256 ]
        then
            echo Directory is not a subvolume!
            echo Would you like to convert the directory into a subvolume?
            read -p "yn>" yn
            case $yn in
                [yY] ) convertToSubvolume;;
                * ) continue ;;
            esac
        fi
        break
    done  
    
    beakdir="$directory/.beak"
    while true
    do
        echo "Storing snapshots and mounts here: $beakdir"
        read -p "Accept or change? ac>" ac
        case $ac in
            [cC] ) read -p "Snapshot and mounts dir:" beakdir ; continue ;;
            * ) ;;
        esac
        mkdir -p "$beakdir"           
        if [ ! -d "$beakdir" ]
        then
            echo "Could not create directory $beakdir"
            exit
        fi
        break
    done
    
    # Test that we can snapshot!
    btrfs subvolume snapshot -r "$directory" "$beakdir/ConfigTest" > /dev/null 2>&1
    if [ ! -d "$beakdir/ConfigTest" ]
    then
        echo "Could not create snapshot $beakdir/ConfigTest"
        exit
    fi

    # Test that we can delete the snapshot!
    btrfs property set -ts "$beakdir/ConfigTest" ro false
    btrfs subvolume delete "$beakdir/ConfigTest" > /dev/null 2>&1
    if [ -d "$beakdir/ConfigTest" ]
    then
        echo "Could not delete snapshot $beakdir/ConfigTest"
        exit
    fi

    echo Available rclone remotes
    rclone listremotes -l

    remotes=""
    while true
    do
        echo 
        read -p "Add remote: or remote:path [empty when done]>" remote
        if [ -z "$remote" ]
        then
            break
        fi
        case "$remote" in 
            *:* ) ;;
            * ) echo "Remote must contain a colon : !"
                continue ;;
        esac

        remotename="${remote%%:*}:"
        isok=$(rclone listremotes | grep -o "$remotename")

        if [ "$isok" != "$remotename" ]
        then
            echo Remote does not exist!
            continue
        fi

        iscrypt=$(rclone listremotes -l | tr -s ' ' | grep -o "$remotename crypt")
        if [ "$remotename crypt" != "$iscrypt" ]
        then
            echo Remote is not encrypted?
            read -p "Really add? yn>" yn
            case $yn in
                [nN] ) echo "Remote not added." 
                       continue ;;
                [yY] ) ;;
            esac
        fi
        remotes=$(printf "remote=$remote\n$remotes")
        echo "Added remote $remote"        
    done
    

    
    echo
    echo
    echo "New Configuration"
    echo "================="
    echo "name: $name"
    echo "directory: $directory"
    echo "snapshots and mounts: $beakdir"
    echo "$remotes"
    echo
    read -p "Save configuration? yn>" yn
    case $yn in
        [yY] ) cat > "$BEAK/${name}.cfg" <<EOF
directory=$directory
beakdir=$beakdir
$remotes
EOF
               echo Configuration saved!
;;
        * ) ;;
    esac
}

function menu {
    echo
    echo "Name                  Directory"
    echo "====                  ========="

    for i in $BEAK/*.cfg
    do
        root="${i##*/}"
        root="${root%.cfg}"
        where="$(grep -h "directory" $i | cut -f 2 -d =)"
        printf "%-16s      %s\n" "$root" "$where"        
    done
    echo 
    echo "e) Edit config"
    echo "n) New config"
    echo "d) Delete config"
    echo "q) Quit"
    
    read -p "e/n/d/q>" choice
    case $choice in
        [eE] ) ;;
        [nN] ) newConfig ;;
        [d] ) ;;
        [q] ) exit ;;
        * ) ;;
    esac
}

menu
ok="true"
