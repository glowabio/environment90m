#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export layers=/mnt/shared/additional_var/FLO1K/tablesRU


TransposeTable_flow1k(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

# exit if file already exist
#[[ -f $zip/Hydrography90m/${var}/${nm}_${var}.zip  ]] && \
#    { echo >&2 "${nm}_${var}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
#tbids=( $(find $out/indx -name "${nm}_*.txt") )
TB=$out/indx/${nm}_subcID.txt

tbids=($(awk -v tile="${nm}" '$1 == tile' $out/tile_RUids_old.txt | cut -d' ' -f 2-))

# create output table with header
echo "subcID min max range mean sd" > ${tmp}/flo1k/${var}_${nm}.txt

# for loop to go through each RU and extract the ids of interest
for ru in ${tbids[@]}
do
    # if file is empty go to next one
    #[[ ! -s $i ]] && continue

    # extract ru number
    #ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers} -name "stats_${ru}_${var}.txt")
    
    # retrieve only records with IDs of interest
#    awk 'NR==FNR {a[$1]; next} FNR > 1 || $1 in a' \
#     ${i} $tb >> ${tmp}/${nm}_${var}.txt

# retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     $TB $tb > ${tmp}/${var}_${nm}_${ru}.txt

done

cat  ${tmp}/${var}_${nm}_*.txt >> ${tmp}/flo1k/${var}_${nm}.txt

rm ${tmp}/${var}_${nm}_*.txt

echo "$nm $(echo "$(wc -l < ${tmp}/flo1k/${var}_${nm}.txt) - 1" | bc)" \
    >> $out/valid/flo1k2.txt

#zip -jq $zip/flo1k_v1_0/flo1k_${nm}.zip \
#    ${tmp}/${nm}_${var}.txt
zip -jq $tmp/flo1k/${var}_${nm}.zip \
    ${tmp}/flo1k/${var}_${nm}.txt

#rm ${tmp}/${nm}_${var}.txt

}


tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
tile=(h00v00 h00v02 h02v00 h02v02 h04v00 h04v02 h04v04)
tile=($(awk '{print $1}' tmp/diff_flo1k.txt))
var=(flow1km)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_flo1k.txt

export -f TransposeTable_flow1k
time parallel -j 10 --colsep ' ' TransposeTable_flow1k ::::  $tmp/tbtrans_flo1k.txt
#time parallel -j 1 TransposeTable_flow1k ::: h00v04 ::: flow1km



for zip in $(find /mnt/shared/Environment90m_v.1.0_online/flo1k_v1_0 -name "*.zip")
do
    sudo unzip $zip -d $tmp/flo1k
done

for zip in $(find $tmp/flo1k -name "*.txt")
    do
    ru=$(basename $zip .txt | awk -F_ '{print $1}')
    count=$(wc -l < $zip)
    echo "$ru $(echo "$count - 1" | bc)" >> $out/valid/flo1k.txt
done


paste -d" " \
    <(sort $out/tile_numberIDs.txt) \
    <(sort $out/valid/flo1k.txt) | more \
    | awk '$2 != $4 {print $1, $2, $3, $4}' > $tmp/diff_flo1k.txt

## create a file with two columns, column 1 the tile id and column 2 the number
## of rows (except header)
tbs=( $(find $tmp/flo1k/ -name "flow1km_*.txt") )

#rm $out/valid/flo1k.txt 
#touch $out/valid/flo1k.txt

for t in ${tbs[@]}
do
    nm=$(basename $t .txt | awk -F_ '{print $2}')

    [[ -f $tmp/flo1k/flow1km_${nm}.zip ]] && continue

    zip -jq $tmp/flo1k/flow1km_${nm}.zip \
    ${tmp}/flo1k/flow1km_${nm}.txt

done

cp tmp/flo1k/flow1km_*.zip $zip/flo1k_v1_0/ 
rm -rf tmp/flo1k

for f in $(awk '{print $1}' tmp/diff_flo1k.txt)
do
    rm tmp/flo1k/${f}_flow1km.txt
done

