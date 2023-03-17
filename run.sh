#!/bin/bash
rm -rf /tmp/GenTargets/Targets
sleep .5
./rls1.sh &
PID1=`echo $!`
sleep .5
./rls2.sh &
PID2=`echo $!`
sleep .5
./rls3.sh &
PID3=`echo $!`

sleep 1
./GenTargets.sh &
PID4=`echo $!`

echo "$PID1 $PID2 $PID3 $PID4" > ./temp/pidOfScripts

