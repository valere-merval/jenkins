#!/bin/bash
DATE_WITH_TIME=`date "+%Y%m%d_%H%M%S"`
cd ../pman
{
for umgebung in $1 $2 $3 $4; do
if [[ "$umgebung" =~ [hijklq] ]]
then
./pman --list preisdaten-nvsbibe-psx"$umgebung".yml
./pman --list preisdaten-abobibe-psx"$umgebung".yml
./pman --list hafaspools-nvsbibe-psx"$umgebung".yml
./pman --list hafaspools-abobibe-psx"$umgebung".yml
./pman --list stammdaten-nvsbibe-psx"$umgebung".yml
./pman --list     hafaspools-tpo-psx"$umgebung".yml
./pman --list     preisdaten-tpo-psx"$umgebung".yml
fi
done
} | sed -e 's/\s*\[[0-9]*\]\s*//' -e '/^Active/d' -e '/^Package/d' -e '/^Available/d' -e '/^Currently/d' | sort -d -s -u | uniq | tee ~/logs/pmanlist"$DATE_WITH_TIME".log
