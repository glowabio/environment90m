#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export layers=/mnt/shared/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_LandCover(){

# define the tile to work with
export nm=${1}
# define variable of interest
export var=${2}

# exit if file already exist

for y in {1993..2020}
do
    [[ -f $zip/LandCover/${var}/${nm}_${var}_${y}.zip  ]] && \
    { echo >&2 "${nm}_${var}_${y}.zip already exist"; exit 1; }
done

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID $(for i in {1992..2020}; do printf "%s " ${var}_y$i; done)" > ${tmp}/${nm}_${var}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do
    # if file is empty go to next one
    [[ ! -s $i ]] && continue

#    wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru} -name "stats_${ru}_LCprop.txt")

    # subset the table with subcatchment id and column of interest
    flds=$(head -n1 $tb | tr ' ' '\n' | grep -ne "^${var}_" \
         | cut -d: -f1 | paste -sd,)

    cut -d' ' -f1,"${flds}" $tb > $tmp/sub_${var}_${ru}_${nm}.txt

    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tmp/sub_${var}_${ru}_${nm}.txt \
     >> ${tmp}/${nm}_${var}.txt

    rm $tmp/sub_${var}_${ru}_${nm}.txt

done


## here again a for loop to go to through each column (each year) and save (zip) a file with 
## subcID, land cover category per year year
for col in {2..30}
do
    export year=$(echo "1990 + ${col}" | bc)

    zip -jq $zip/LandCover/${var}/${nm}_${var}_${year}.zip \
    ${tmp}/${nm}_${var}_${year}.txt
    
    #cpulimit -e zip -l 10
    
    rm ${tmp}/${nm}_${var}_${year}.txt
done

rm ${tmp}/${nm}_${var}.txt

echo "file ${nm}_${var}_${year}.zip created" >> $out/landcoverZipfiles.txt

}


#for cat in c10 c20 c30 c40 c50 c60 c70 c80 c90 c100 c110 c120 c130 c140 c150 c160 c170 c180 c190 c200 c210 c220; do mkdir $zip/LandCover/${cat}; done


# list of variables:
tile=(h18v02 h20v02 h18v04 h20v04)
tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
var=(c10 c20 c30 c40 c50 c60 c70 c80 c90 c100 c110 c120 c130 c140 c150 c160 c170 c180 c190 c200 c210 c220)

for t in ${tile[@]}
do
    for i in ${var[@]}
                do echo $t $i 
    done 
done > $tmp/tbtrans_landcover.txt


export -f TransposeTable_LandCover
time parallel -j 5 --colsep ' ' TransposeTable_LandCover ::::  $tmp/tbtrans_landcover.txt
#parallel -j 1 TransposeTable_LandCover ::: h18v02 ::: c10



####  validate output

for v in ${var[@]}
for v in c110
do
    for t in ${tile[@]}
    do
        ll -h  $v/${t}*.zip | wc -l
    done
done | sort | uniq -c

###  check again c110,120, 130, 140, 170, 180

for v in c110 c120 c130 c140 c170 c180
do
for t in ${tile[@]}
do
    n=$(ls $v/${t}*.zip | wc -l)
    echo "$v = $t = $n"
done
done | awk '$5 != 29' > /mnt/shared/tiles_tb/lc_missing2.txt

echo "h26v02 c110
h26v02 c120
h26v02 c130
h26v02 c140
h16v06 c170
h16v06 c180" > $tmp/faltantes.txt




export -f TransposeTable_LandCover
#time parallel -j 6 --colsep ' ' TransposeTable_LandCover ::::  $tmp/tbtrans_landcover.txt    
time parallel -j 1 --colsep ' ' TransposeTable_LandCover ::::  $tmp/faltantes.txt    




tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tmp/sub_${var}_${ru}_${nm}.txt \
     >> ${tmp}/${nm}_${var}.txt


export afro=/mnt/shared/afroditi_subc_ru.csv


#for ru in $(awk -F, 'NR > 1 {print $2}' $afro | sort | uniq)
#ru=99

areaAfro(){

ru=$1

awk -F, -v RU="$ru" '$2 == RU {print $1, $2}' $afro | awk '!a[$1]++'  > tmp/ru_${ru}.txt

fs=( $(find /mnt/shared/tiles_tb/indx -name "*_${ru}_*.txt") )

cat ${fs[@]} | awk '!a[$1]++'  > tmp/all_${ru}.txt

awk 'NR==FNR {a[$1]; next} $1 in a' tmp/ru_${ru}.txt tmp/all_${ru}.txt > tmp/merge_${ru}.txt

echo "RU = $ru --- afroRU = $(wc -l < tmp/ru_${ru}.txt) --- extractRU = $(wc -l < tmp/merge_${ru}.txt)" \
    >> tmp/comparison.txt

rm tmp/ru_${ru}.txt tmp/all_${ru}.txt

}

export -f areaAfro
#parallel -j 1 areaAfro ::: 99 
parallel -j 40 areaAfro ::: $(awk -F, 'NR > 1 {print $2}' $afro | sort | uniq) 

# check 158 , 31, 32, 184,   

cat $(find /mnt/shared/tmp -name "merge*.txt") > tmp/all_ru.txt

paste -d" " \
    <(awk -F, 'NR > 1 {print $1, $2}' $afro | sort | head) \
    <()

