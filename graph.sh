#!/bin/bash

MaxKolTargets=30

path="/tmp/GenTargets/Targets"

targetsFile="files/targetsForGraph.txt"
> $targetsFile

while :
do 
    > $targetsFile
    if ! [ -d $path ] 
    then
        sleep .5
        continue
    fi
    # Считать названия файлов из папки с целями и если там пока нет ни одного файла, то пропустить цикл
    temp=`ls $path -t 2>/dev/null`

    if [[ $temp == "" ]]
    then 
        sleep .5
        continue
    fi
    # Считать последние 30 созданных файлов, если целей 30
    Topfiles=`echo "$temp" | head -n $MaxKolTargets`

    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        echo "$id;$X;$Y" >> $targetsFile
        #echo "$id;$X;$Y"
    done
    echo "-"
    sleep .5
done