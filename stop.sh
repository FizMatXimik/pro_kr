#!/bin/bash

PIDList=`cat ./files/pidOfScripts`
kill $PIDList

rm -rf /tmp/GenTargets/Targets

