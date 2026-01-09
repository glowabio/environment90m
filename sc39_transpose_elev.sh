#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_elev(){

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
echo "subcID min max range mean sd" > ${tmp}/elev/${var}_${nm}.txt

# for loop to go through each RU and extract the ids of interest
for ru in ${tbids[@]}
do
    # if file is empty go to next one
#    [[ ! -s $i ]] && continue
#
#    # extract ru number
#    ru=$(basename $i .txt | awk -F_ '{print $2}')
#
#    # identify table of interest
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_${var}.txt")
#    
#    # retrieve only records with IDs of interest
#    awk 'NR==FNR {a[$1]; next} $1 in a' \
#     $TB $tb > ${tmp}/elev/${var}_${nm}.txt

#    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     $TB $tb > ${tmp}/${var}_${nm}_${ru}.txt
done

cat  ${tmp}/${var}_${nm}_*.txt >> ${tmp}/elev/${var}_${nm}.txt

rm ${tmp}/${var}_${nm}_*.txt

echo "$nm $(echo "$(wc -l < ${tmp}/elev/${var}_${nm}.txt) - 1" | bc)" \
    >> $out/valid/elev.txt

# rm $tmp/elev/${var}_${nm}.zip
zip -jq $tmp/elev/${var}_${nm}.zip \
    ${tmp}/elev/${var}_${nm}.txt

#rm ${tmp}/${var}_${nm}.txt

}

tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
tile=(h12v08 h16v04 h20v04 h24v02 h26v02)
var=(elev)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_elev.txt

#rm $out/valid/elev.txt 
#touch $out/valid/elev.txt

export -f TransposeTable_elev
time parallel -j 1 --colsep ' ' TransposeTable_elev ::::  $tmp/tbtrans_elev.txt

#############################################################################
#############################################################################
#############################################################################

## create a file with two columns, column 1 the tile id and column 2 the number
## of rows (except header)
tbs=( $(find $tmp/elev/ -name "elev_*.txt") )

#rm $out/valid/elev.txt 
#touch $out/valid/elev.txt

for t in ${tbs[@]}
do
    nm=$(basename $t .txt | awk -F_ '{print $2}')
    echo "$nm $(echo "$(wc -l < $t) - 1" | bc)" >> $out/valid/elev.txt
done

## in the first run the tables did not have the header and the name waswith
## the wrong order
#for t in ${tbs[@]}
#do
#    tile=$(basename $t .txt | awk -F_ '{print $1}')
#    echo "$tile $(wc -l < $t)" >> $out/valid/elev.txt
#    sudo sed -i '1i subcID min max range mean sd' $t
#    mv $t $tmp/elev/elev_${tile}.txt
#    zip -jq $tmp/elev/elev_${tile}.zip ${tmp}/elev/elev_${tile}.txt
#done

##############################################################################
##############################################################################
##############################################################################

#awk '!seen[$0]++' $out/tile_numberIDs.txt > $out/new_tile_numberIDs.txt
#mv $out/new_tile_numberIDs.txt $out/tile_numberIDs.txt

## check visually if the number of rows is the same
paste -d" " \
    <(sort $out/tile_numberIDs.txt) \
    <(sort $out/valid/elev.txt) \
    | awk '$2 != $4 {print $1, $2, $4}'

h34v00 2998010 2997867
h34v02 2747624 2710498

### verificar si tiene duplicados
awk '{ if (seen[$1]++) count++ } END { print count }' $tmp/elev/elev_h18v04.txt

### borrar duplicados
awk '!seen[$1]++' $tmp/elev/elev_h18v04.txt > $tmp/elev/elev_h18v04_new.txt 

# if still the number of rows do not match then
#To find entries in file2 not in file1
awk 'NR==FNR {seen[$1]; next} !($1 in seen)' $tmp/elev/elev_h06v06.txt $out/indx/h06v06_subcID.txt
# result:
# subcID min max range mean sd
# 5225859375 604.167582743877 0.710179129075938

# leave only rows with  6 columns
awk 'NF == 6' $tmp/elev/elev_h18v04_new.txt > $tmp/elev/elev_h18v04_new2.txt

mv $tmp/elev/elev_h18v04_new2.txt $tmp/elev/elev_h18v04.txt
rm $tmp/elev/elev_h18v04_new.txt

rm $tmp/elev/elev_h18v04.zip
zip -jq $tmp/elev/elev_h18v04.zip ${tmp}/elev/elev_h18v04.txt 



