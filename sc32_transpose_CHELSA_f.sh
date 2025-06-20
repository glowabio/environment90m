#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online/chelsa_bioclim_v2_1
export biop=/mnt/shared/regional_unit_tables_bio_fut/newfiles

TransposeTable_CHELSA_f(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}
year=${3}
year2=${year//-/_}
model=${4}
ssp=${5}
ver=${6}

# exit if file already exist
[[ -f $zip/${year2}/${var}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.zip  ]] \
    && { echo >&2 "${var}_${year}_${model}_${ssp}_${ver}_${nm}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID min max range mean sd" > \
    ${tmp}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do
    # if file is empty go to next one
    [[ ! -s $i ]] && continue

 #  wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${biop}/CU_${ru} -name "stats_${ru}_*_${var}_${year}*${model}*${ssp}*.txt")
    
    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tb >> ${tmp}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.txt
done

zip -jq $zip/${year}_projected/${var}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.zip \
    ${tmp}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.txt

#wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

rm ${tmp}/${var}_${year}_${model}_${ssp}_${ver}_${nm}.txt

#echo "${nm} ${var} ${year} ${model} ${ssp}  done" >> $tmp/biof_tiles_done.txt

}

# list of variables:
# bio1-19   source:/mnt/shared/regional_unit_bio 
tile=(h18v02 h20v02 h18v04 h20v04)
var=(bio1 bio2 bio3 bio4 bio5 bio6 bio7 bio8 bio9 bio10 bio11 bio12 bio13 bio14 bio15 bio16 bio17 bio18 bio19)
year=(2041-2070 2071-2100)
model=(mpi-esm1-2-hr ukesm1-0-ll ipsl-cm6a-lr)
ssp=(ssp585 ssp370 ssp126)
ver=(V.2.1)

for t in $(cat /mnt/shared/tiles_tb/tiles.txt)
#for t in ${tile[@]}
do
    for i in ${var[@]}
    do
        for y in ${year[@]}
        do
            for m in ${model[@]}
            do
                for s in ${ssp[@]}
                do 
                    for v in ${ver[@]}
                    do echo $t $i $y $m $s $v
                    done
                done
            done
        done
    done 
done > $tmp/tbtrans_bf.txt

export -f TransposeTable_CHELSA_f
time parallel -j 20 --colsep ' ' TransposeTable_CHELSA_f ::::  $tmp/tbtrans_bf.txt
#time parallel -j 1 TransposeTable_CHELSA_f ::: h00v02 ::: bio1 ::: 2071-2100 ::: mpi-esm1-2-hr ::: ssp585 ::: V.2.1


###############################################
###############################################

dir=/mnt/shared/regional_unit_tables_bio_fut/newfiles
for i in $(ls $dir)
do
    unzip -j $dir/$i -d $dir
done


for i in $(ls $dir)
do
    outn=$(basename $i .zip)
    mkdir $dir/$outn
    sudo unzip -j $dir/$i -d $dir/$outn
done
