#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES


###############################################################################
## checking 
var=cti
mkdir $tmp/$var
for p in $(find $zip/hydrography90m_v1_0/$var -name "*.zip")
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

TransposeTable_Hydro90m(){

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

echo "$nm $(echo "$(wc -l < ${tmp}/${var}/${var}_${nm}.txt) - 1" | bc)" \
    >> $out/valid/${var}.txt

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
var=(sti)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_hydro90m.txt

export -f TransposeTable_Hydro90m
time parallel -j 3 --colsep ' ' TransposeTable_Hydro90m ::::  $tmp/tbtrans_hydro90m.txt



cp tmp/sti/sti_h10v04.zip $zip/hydrography90m_v1_0/sti



############################
##  STREAM FLOW INDICES 
############################

#    if [ "$VAR" == "cti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_cti_dis.vrt; fi
#    if [ "$VAR" == "spi" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_spi_dis.vrt; fi
#    if [ "$VAR" == "sti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_sti_dis.vrt; fi

export sc=/mnt/shared/hydrography90m_v.1.0_online/hydrography90m_v.1.0/global/sub_catchment_ovr.tif

export tile=h22v04
export ctitarget=/mnt/shared/hydrography90m_v.1.0_online/hydrography90m_v.1.0/flow.index/cti_tiles20d/cti_${tile}.tif

gdalwarp $(pkinfo -i $ctitarget -te)  $sc $tmp/sc_$tile.tif

grass  -f --gtext --tmp-location $tmp/sc_$tile.tif  # <<'EOF'

  r.in.gdal --o input=$tmp/sc_$tile.tif output=micb 

  r.external input=$ctitarget output=cti --overwrite

  echo "subcID min max range mean sd" > ${tmp}/cti/cti_${tile}.txt  

  r.univar -t --o map=cti zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> ${tmp}/cti/cti_${tile}.txt

