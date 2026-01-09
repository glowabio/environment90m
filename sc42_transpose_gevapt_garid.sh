#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES


###############################################################################
## checking 
var=garid
mkdir $tmp/$var
for p in $(find $zip/cgiar_csi_v3/$var -name "*.zip")
do
    sudo unzip $p -d $tmp/$var
done

for p in $(find $tmp/$var -name "*.txt")
    do
    ru=$(basename $p .txt | awk -F_ '{print $2}')
    count=$(wc -l < $p)
    echo "$ru $(echo "$count - 1" | bc)" >> $out/valid/${var}.txt
done

paste -d" " \
    <(sort $out/tile_numberIDs.txt) \
    <(sort $out/valid/${var}.txt) \
    | awk '$2 != $4 {print $1, $2, $3, $4}' > $tmp/diff_${var}.txt

###############################################################################
###############################################################################
###############################################################################
###############################################################################

TransposeTable_gevapt(){

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
echo "subcID min max range mean sd" > ${tmp}/${var}/${var}_${nm}.txt

# for loop to go through each RU and extract the ids of interest
for ru in ${tbids[@]}
do
    # if file is empty go to next one
    #[[ ! -s $i ]] && continue

    # extract ru number
    #ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_${var}.txt")
    
    # retrieve only records with IDs of interest
    #awk 'NR==FNR {a[$1]; next} FNR > 1 || $1 in a' \
    # ${i} $tb >> ${tmp}/${nm}_${var}.txt

    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     $TB $tb > ${tmp}/${var}_${nm}_${ru}.txt
done

cat  ${tmp}/${var}_${nm}_*.txt >> ${tmp}/${var}/${var}_${nm}.txt

rm ${tmp}/${var}_${nm}_*.txt

#echo "$nm $(echo "$(wc -l < ${tmp}/${var}/${var}_${nm}.txt) - 1" | bc)" \
#    >> $out/valid/${var}.txt

# rm $tmp/elev/${var}_${nm}.zip
zip -jq $tmp/${var}/${var}_${nm}.zip \
    ${tmp}/${var}/${var}_${nm}.txt

#rm ${tmp}/${var}_${nm}.txt


#zip -jq $zip/elevation/${var}_${nm}.zip \
#    ${tmp}/${nm}_${var}.txt

#rm ${tmp}/${nm}_${var}.txt

}

tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
tile=(h10v04 h34v00 h34v02)  # h22v04
var=(garid)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_gevapt.txt

export -f TransposeTable_gevapt
time parallel -j 3 --colsep ' ' TransposeTable_gevapt ::::  $tmp/tbtrans_gevapt.txt



cp tmp/gevapt/gevapt_h10v04.zip $zip/cgiar_csi_v3/gevapt
cp tmp/garid/garid_h34v00.zip $zip/cgiar_csi_v3/garid
