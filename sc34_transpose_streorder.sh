#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online/hydrography90m_v1_0
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_streamorder(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

fol=$var

[[ "$var" = "strahler" ]] && fol=stream_strahler
[[ "$var" = "horton" ]] && fol=stream_horton
[[ "$var" = "shreve" ]] && fol=stream_shreve
[[ "$var" = "hack" ]] && fol=stream_hack
[[ "$var" = "topo_dim" ]] && fol=stream_topo_dim
[[ "$var" = "scheidegger" ]] && fol=stream_scheidegger
[[ "$var" = "drwal_old" ]] && fol=stream_drwal_old


[[ ! -d $zip/${fol} ]] && mkdir $zip/${fol}

# exit if file already exist
[[ -f $zip/${fol}/${fol}_${nm}.zip ]] &&  \
    { echo >&2 "${fol}_${nm}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID $fol" > ${tmp}/${nm}_${var}.txt

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
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_streamorder.txt")
 
    # subset the table with subcatchment id and column of interest
     awk -v VAR="$var"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } 
     {print $1, $(f[VAR])}' $tb > $tmp/sub_${var}_${ru}_${nm}.txt

    # extract subc of interst only
     awk 'NR == FNR {a[$1]; next} $1 in a' \
         $i $tmp/sub_${var}_${ru}_${nm}.txt \
         >> ${tmp}/${nm}_${var}.txt 
    
     rm $tmp/sub_${var}_${ru}_${nm}.txt 
 
 done

mv ${tmp}/${nm}_${var}.txt ${tmp}/${fol}_${nm}.txt

# delete if file already exist
[[ -f $zip/${fol}/${fol}_${nm}.zip ]] && rm $zip/${fol}/${fol}_${nm}.zip

zip -jq $zip/${fol}/${fol}_${nm}.zip \
    ${tmp}/${fol}_${nm}.txt

#wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

#rm ${tmp}/${fol}_${nm}.txt
mv ${tmp}/${fol}_${nm}.txt ${tmp}/$var/${fol}_${nm}.txt 
#echo "${nm} ${var} done" >> $tmp/streamorder_tiles_done.txt

}

#####   OJO
### make sure the folders for each variable exist

# list of variables:
tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
tile=(h18v04)
var=(stream_horton)
var=(strahler horton shreve hack topo_dim scheidegger drwal_old length stright sinosoid cum_length flow_accum out_dist source_elev outlet_elev elev_drop out_drop gradient)


for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_streamorder.txt

export -f TransposeTable_streamorder
time parallel -j 20 --colsep ' ' TransposeTable_streamorder ::::  $tmp/tbtrans_streamorder.txt
#time parallel -j 1  TransposeTable_streamorder ::: h18v04 ::: scheidegger


for fol in stream_strahler stream_horton stream_shreve stream_hack stream_topo_dim stream_scheidegger stream_drwal_old length stright sinosoid cum_length flow_accum out_dist source_elev outlet_elev elev_drop out_drop gradient
do
    find $zip/$fol -mtime +6 -name "*.zip" -delete
done


#find /tmp -maxdepth 1 -mtime -1 -type f -name "DBG_A_sql*" -print
