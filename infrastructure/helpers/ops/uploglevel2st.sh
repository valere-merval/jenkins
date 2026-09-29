#!/bin/bash
REGEX1='s/log.level=2/log.level=3/g'
REGEX2='s/log.level.extern=300/log.level.extern=200/g'
REGEX3='s/XmlDocQueueSize=0/XmlDocQueueSize=1000/g'

sed -i -e $REGEX1 -e $REGEX2 -e $REGEX3 auskunft/preisdaten/config/test-fork.properties
sed -i -e $REGEX1 -e $REGEX2 -e $REGEX3 auskunft/preisdaten/config/test-abofork.properties
sed -i 's/%AnfragelogFilename/AnfragelogFilename/g' auskunft/preisdaten/config/peconfig.ini.template

#hafas.sh stop
#wait 5
#hafas.sh start --create
