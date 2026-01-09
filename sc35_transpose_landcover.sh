#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_LandCover(){

# define the tile to work with
export nm=${1}
# define variable of interest
export var=${2}

# CHeck tables with ids for that tile
#tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )
TB=$out/indx/${nm}_subcID.txt

tbids=($(awk -v tile="${nm}" '$1 == tile' $out/tile_RUids_old.txt | cut -d' ' -f 2-))

# create output table with header
echo "subcID $(for i in {1992..2020}; do printf "%s " ${var}_y$i; done)" > ${tmp}/esa/${var}_${nm}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for ru in ${tbids[@]}
do
    # if file is empty go to next one
    #[[ ! -s $ru ]] && continue

#    wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    #ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru} -name "stats_${ru}_LCprop.txt")

    # subset the table with subcatchment id and column of interest
    flds=$(head -n1 $tb | tr ' ' '\n' | grep -ne "^${var}_" \
         | cut -d: -f1 | paste -sd,)

    cut -d' ' -f1,"${flds}" $tb > $tmp/sub_${var}_${ru}_${nm}.txt

    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     $TB $tmp/sub_${var}_${ru}_${nm}.txt \
     > ${tmp}/${var}_${nm}_${ru}.txt

    rm $tmp/sub_${var}_${ru}_${nm}.txt

done


cat  ${tmp}/${var}_${nm}_*.txt >> ${tmp}/esa/${var}_${nm}.txt

rm ${tmp}/${var}_${nm}_*.txt

## here again a for loop to go to through each column (each year) and save (zip) a file with 
## subcID, land cover category per year year
for year in {1992..2020}
do

    #[[ -f $zip/LandCover/${var}/${var}_${year}_${nm}.zip  ]] && \
    #{ echo >&2 "${var}_${year}_${nm}.zip already exist"; continue; }

    awk -v colname="${var}_y${year}" \
        'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
        {print $1, $(f[colname])}' $tmp/esa/${var}_${nm}.txt \
            > ${tmp}/esa/${var}_${year}_${nm}.txt

    #zip -jq $zip/LandCover/${var}/${var}_${year}_${nm}.zip \
    #${tmp}/${var}_${year}_${nm}.txt
    
    zip -jq $tmp/esa/${var}_${year}_${nm}.zip \
    ${tmp}/esa/${var}_${year}_${nm}.txt
    #cpulimit -e zip -l 10
    
    rm ${tmp}/esa/${var}_${year}_${nm}.txt
done

#rm ${tmp}/esa/${var}_${nm}.txt

#echo "file ${nm}_${var}_${year}.zip created" >> $tmp/landcoverZipfiles.txt
cp $tmp/esa/${var}_*_${nm}.zip $zip/esa_cci_landcover_v2_1_1/${var}

rm $tmp/esa/${var}_*_${nm}.zip
}

echo "h26v02 c110
h26v02 c120
h26v02 c130
h26v02 c140
h16v06 c170
h16v06 c180" > $tmp/faltantes.txt




export -f TransposeTable_LandCover
#time parallel -j 6 --colsep ' ' TransposeTable_LandCover ::::  $tmp/tbtrans_landcover.txt    
time parallel -j 6 --colsep ' ' TransposeTable_LandCover ::::  $tmp/faltantes.txt    

#for cat in c10 c20 c30 c40 c50 c60 c70 c80 c90 c100 c110 c120 c130 c140 c150 c160 c170 c180 c190 c200 c210 c220; do mkdir $zip/LandCover/${cat}; done


# list of variables:
tile=(h10v04)
tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
var=(c20 c30 c40 c50 c60 c70 c80 c90 c100 c110 c120 c130 c140 c150 c160 c170 c180 c190 c200 c210 c220)

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


################################################################################
################################################################################
################################################################################


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

