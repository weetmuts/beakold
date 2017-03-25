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

echo
echo "Name                  Directory"
echo "====                  ========="

for i in $BEAK/*.cfg
do
    root="${i##*/}"
    root="${root%.cfg}"
    pushes="$BEAK/${root}.pushes"
    where="$(grep -h directory "$i" | cut -f 2 -d =)"
    printf "%-16s      %s\n" "$root" "$where"
    n=$(date +%s)
    if [ -s "$pushes" ]
    then
        while read l; do
            remote=$(echo "$l" | cut -f 2- -d ' ')
            p=$(date +%s "--date=$(echo "$l" | cut -f 1 -d ' ')")
            d=$((n-p))
            if [ $d -le 60 ]; then m="less than a minute ago" 
            elif [ $d -le 3600 ]; then m="$((d / 60)) minutes ago"
            elif [ $d -le 86400 ]; then m="$((d / 3600)) hours ago"
            elif [ $d -le 604800 ]; then m="$((d / 86400)) days ago"
            else                             
                m="$((d / 604800)) weeks ago"
            fi
            printf "%-16s      %s\n" "$m" "$remote"
        done <"$pushes"
    else
        printf "%-16s      %s\n" "No backup!" ""
    fi
    echo
done

ok="true"
