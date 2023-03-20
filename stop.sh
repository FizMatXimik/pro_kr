#!/bin/bash

PIDList=`cat ./temp/pidOfScripts`
kill $PIDList

rm -rf /tmp/GenTargets/Targets

