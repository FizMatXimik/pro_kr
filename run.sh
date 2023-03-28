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
sleep .5
./spro.sh &
PID4=`echo $!`
sleep .5
./zrdn1.sh &
PID5=`echo $!`
sleep .5
./zrdn2.sh &
PID6=`echo $!`
sleep .5
./zrdn3.sh &
PID7=`echo $!`
sleep .5
./graph.sh &
PID8=`echo $!`

sleep 1
./GenTargets.sh &
PID9=`echo $!`

# sleep 1
# java -jar /home/aleksandr/pro_kr_graph/target/pro_kr_graph-1.0-SNAPSHOT.jar &
# PID10=`echo $!`

echo "$PID1 $PID2 $PID3 $PID4 $PID5 $PID6 $PID7 $PID8 $PID9" > ./files/pidOfScripts

  