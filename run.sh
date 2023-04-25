#!/bin/bash

mkdir ./temp/SPRO
mkdir ./temp/ZRDN1
mkdir ./temp/ZRDN2
mkdir ./temp/ZRDN3
mkdir ./temp/notalive

mkdir ./messages/TargetsLog
mkdir ./messages/WarningsLog
mkdir ./messages/StatusLog

echo "   "

sleep .2
./kp.sh &
PID0=`echo $!`
sleep .2
./rls1.sh &
PID1=`echo $!`
sleep .2
./rls2.sh &
PID2=`echo $!`
sleep .2
./rls3.sh &
PID3=`echo $!`
sleep .2
./spro.sh &
PID4=`echo $!`
sleep .2
./zrdn1.sh &
PID5=`echo $!`
sleep .2
./zrdn2.sh &
PID6=`echo $!`
sleep .2
./zrdn3.sh &
PID7=`echo $!`

echo "   "

echo "kp-$PID0 rls1-$PID1 rls2-$PID2 rls3-$PID3 spro-$PID4 zrdn1-$PID5 zrdn2-$PID6 zrdn3-$PID7"
echo "$PID0 $PID1 $PID2 $PID3 $PID4 $PID5 $PID6 $PID7" > ./files/pidOfScripts