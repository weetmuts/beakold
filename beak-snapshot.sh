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

shopt -s dotglob
shopt -s globstar

if [ "$1" != "" ]
then
snapshot=".snapshot_$1"
else
snapshot=".snapshot_$(date +%Y-%m-%d_%H-%M-%S)"    
fi
mkdir "$snapshot"

for i in *
do
    echo "$i"
    if [[ "$i" =~ ^.snapshot.*$ ]]
    then
        echo Nope
    else
        echo Yes
        cp -a --reflink=always "$i" "$snapshot"
    fi
done

# Now unlink any snapshots that accidently got copied (using reflinks)
# into the snapshot directory.
SNAPS=$(compgen -G "$snapshot/**/.snapshot*")
if [ "$SNAPS" != "" ]
then
    rm -r "$snapshot"/**/.snapshot*
fi

chmod -R ugo-w "$snapshot"
