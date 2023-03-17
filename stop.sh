#!/bin/bash

PIDList=`cat ./temp/pidOfScripts`
kill $PIDList

