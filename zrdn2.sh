#!/bin/bash

# Размеры карты
RangeXY=(13000000 9000000)
# Максимальное количество целей на карте одновременно
MaxKolTargets=30
# Название станции
SName="__ZRDN_2__"
# Цвет текста станции
SColor="\e[1;36m"
# Границы скорости целей
PlaneSpeedL=50
PlaneSpeedH=250
KRSpeedL=250
KRSpeedH=1000
# Координаты и радиус ЗРДН
CoordsZRDNXY=(6150000 3510000)
RadiusZRDN=450000
# Путь до папки с Целями
path="/tmp/GenTargets/Targets"
# Путь до папки для уничтожения целей
pathD="/tmp/GenTargets/Destroy"
# Путь до папки временных файлов целей, по котором был произведен выстрел
pathShoot="./temp/ZRDN2"
# Путь до файла с засечками
targetsFile="files/targets_zrdn2.txt"
> $targetsFile
# Путь до файла с id новых засеченных целей
targetsFileIds="files/targets_zrdn2_ids.txt"
> $targetsFileIds
# Путь до файла с боезапасом ЗРДН
ammunitionFile="files/ZRDN2_Missiles"
> $ammunitionFile
NumOfMissiles=20
# Основной цикл станции

while :
do 

    # Пропускать цикл если пока нет папки с целями
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

    # Очистка файла с целями для записи новых
    > $targetsFileIds
    # Заполнение файла айдишниками замеченных целей на данной итерации цикла
    for file in $Topfiles
    do
        idL=${file: -6}
        echo $idL >> $targetsFileIds
    done

    # Считываем все айдишники целей на данной итерации цикла
    IdsOfNewTargets=`cat $targetsFileIds`
    # Пробегаемся по списку файлов, то есть целей по которым был произведен выстрел
    for idAT in `ls $pathShoot -t`
    do
        # Проверка есть ли среди новых айдишников тот, по которому был произведен выстрел.
        TargetCheckAt=`echo $IdsOfNewTargets | grep $idAT | wc -l`
        # Если нет, то есть совпадений ноль, то значит цель была сбита и можно выводить сообщение и удалять файл 
        if [[ $TargetCheckAt -eq 0 ]]
        then
            echo -e "$SColor $SName Цель ID:$idAT сбита"
            rm "$pathShoot/$idAT"
        fi
    done

    # Цикл, где на каждой итерации берем новую информацию по одной из целей
    for file in $Topfiles
    do
        id=${file: -6}
        X=`cat "${path}/${file}" | cut -d "," -f1 | cut -c2-9`
        Y=`cat "${path}/${file}" | cut -d "," -f2 | cut -c2-9`

        deltaX=$(( $X - ${CoordsZRDNXY[0]} ))
        deltaY=$(( $Y - ${CoordsZRDNXY[1]} ))

        if [[ `echo "(($deltaX)^2 + ($deltaY)^2)<=(($RadiusZRDN)^2)" | bc` -eq 1 ]]
        then
            TargetCheck=`grep $id $targetsFile | wc -l`

            if [[ $TargetCheck -eq 0 ]]
            then
                echo "$id;$X;$Y" >> $targetsFile
            else
                if [[ $TargetCheck -ge 1 ]]
                then
                    PrevX=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f2`
                    PrevY=`grep $id $targetsFile | tail -n 1 | cut -d ";" -f3`
                    if [[ ($PrevX != $X) || ($PrevY != $Y) ]]
                    then
                        Distance=`echo "sqrt(($PrevX-$X)^2 + ($PrevY-$Y)^2)" | bc`

                        if [[ ($Distance -ge $PlaneSpeedL) && ($Distance -le $KRSpeedH) ]]
                        then
                            if [[ $TargetCheck -eq 1 ]]
                            then
                                if [[ ($Distance -le $PlaneSpeedH) ]]
                                then
                                    echo -e "$SColor $SName Обнаружен Самолет ID:$id с координатами X$X Y$Y"
                                else
                                    echo -e "$SColor $SName Обнаружена К.ракета ID:$id с координатами $X $Y"
                                fi
                            else
                                # иначе, если это 3-я или более засечка, то говорим, что был промах при выстреле
                                echo -e "$SColor $SName Промах по цели ID:$id"
                            fi
                            # производим выстрел
                            echo -e "$SColor $SName Выстрел по цели ID:$id "
                            # создаем файл в папке уничтожения целей
                           	touch "$pathD/$id"
                            # записываем выстрел в файл арсенала
                            echo "shoot" >> $ammunitionFile

                            # создание файла цели, по которой был произведен выстрел
                            touch "$pathShoot/$id"

                            # проверка файла с боекомплектом
                            L=`cat $ammunitionFile | wc -l`
                            Missilesremained=`echo "$NumOfMissiles - $L" | bc`
                            # печатаем остаток боекомплекта
                            echo -e "$SColor $SName Ракет осталось: $Missilesremained"

                            # если боекомплект пуст то выводим сообщение и перезагружаем его
                            if [[ $Missilesremained -eq 0 ]]
                            then 
                                echo -e "$SColor $SName Боекомплект пуст"
                                > $ammunitionFile
                                echo -e "$SColor $SName Боекомплект перезаряжен"
                            fi
                        fi
                        echo "$id;$X;$Y" >> $targetsFile
                    fi
                fi
            fi
        else 
            continue
        fi
    done
    # echo -e "\033[0m ..."
    sleep .5
done