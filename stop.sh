#!/bin/bash

PIDList=`cat ./files/pidOfScripts`
kill $PIDList

rm -rf /tmp/GenTargets/Targets

rm -rf ./temp/SPRO
rm -rf ./temp/ZRDN1
rm -rf ./temp/ZRDN2
rm -rf ./temp/ZRDN3
rm -rf ./temp/notalive

rm -rf ./messages/TargetsLog
rm -rf ./messages/WarningsLog
rm -rf ./messages/StatusLog

log="./logs/KPLOG.log"
log2="./logs/KPFinal.log"
cat $log | sort > $log2