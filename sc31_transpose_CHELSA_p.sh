#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online
export biop=/mnt/shared/regional_unit_bio

TransposeTable_CHELSA_p(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

#[[ -f $zip/Climate/present/${var}/${nm}_${var}.zip  ]] && \
#    { echo >&2 "${nm}_${var}.zip already exist"; exit 1; }

# Check tables with ids for that tile
#tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )
TB=$out/indx/${nm}_subcID.txt

tbids=($(awk -v tile="${nm}" '$1 == tile' $out/tile_RUids_old.txt | cut -d' ' -f 2-))

# create output table with header
echo "subcID min max range mean sd" > ${tmp}/chelsa/${var}_${nm}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for ru in ${tbids[@]}
do
    # if file is empty go to next one [[ ! -s $i ]] && continue

    #wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    #ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${biop} -name "stats_${ru}_${var}.txt")
    
    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     $TB $tb > ${tmp}/${var}_${nm}_${ru}.txt

done

cat  ${tmp}/${var}_${nm}_*.txt >> ${tmp}/chelsa/${var}_${nm}.txt

rm ${tmp}/${var}_${nm}_*.txt

#zip -jq $zip/Climate/present/${var}/${nm}_${var}.zip ${tmp}/${nm}_${var}.txt

zip -jq $tmp/chelsa/${var}_${nm}.zip \
    ${tmp}/chelsa/${var}_${nm}.txt

#wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

#rm ${tmp}/chelsa/${var}_${nm}.txt

#echo "${nm} ${var} done" >> $tmp/biop_tiles_done.txt

}

# list of variables:
# bio1-19   source:/mnt/shared/regional_unit_bio 
tile=( $(cat /mnt/shared/tiles_tb/tiles.txt)  )
tile=(h10v04)
var=(bio3 bio4 bio5 bio6 bio7 bio8 bio9 bio10 bio11 bio12 bio13 bio14 bio15 bio16 bio17 bio18 bio19)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_chelsa.txt

export -f TransposeTable_CHELSA_p
time parallel -j 5 --colsep ' ' TransposeTable_CHELSA_p ::::  $tmp/tbtrans_chelsa.txt
#time parallel -j 1 --colsep ' ' TransposeTable_CHELSA_p ::: h18v04 ::: bio1


#awk 'NR > 1 {total+=$1; print $1,total}' h18v04_bio1.txt

for p in $(find $tmp/chelsa -name "*.txt")
    do
    ru=$(basename $p .txt | awk -F_ '{print $1}')
    count=$(wc -l < $p)
    echo "$ru $(echo "$count - 1" | bc)" >> $out/valid/${var}.txt
done

mv $tmp/chelsa/bio1_h10v04.txt $tmp/chelsa/bio01_h10v04.txt
mv $tmp/chelsa/bio2_h10v04.txt $tmp/chelsa/bio02_h10v04.txt
mv $tmp/chelsa/bio3_h10v04.txt $tmp/chelsa/bio03_h10v04.txt
mv $tmp/chelsa/bio4_h10v04.txt $tmp/chelsa/bio04_h10v04.txt
mv $tmp/chelsa/bio5_h10v04.txt $tmp/chelsa/bio05_h10v04.txt
mv $tmp/chelsa/bio6_h10v04.txt $tmp/chelsa/bio06_h10v04.txt
mv $tmp/chelsa/bio7_h10v04.txt $tmp/chelsa/bio07_h10v04.txt
mv $tmp/chelsa/bio8_h10v04.txt $tmp/chelsa/bio08_h10v04.txt
mv $tmp/chelsa/bio9_h10v04.txt $tmp/chelsa/bio09_h10v04.txt

for p in $(find $tmp/chelsa -name "*.txt")
    do
    name=$(basename $p .txt)
    ch=$(basename $p .txt | awk -F_ '{print $1}')
    zip -jq $tmp/chelsa/$name.zip $p
    cp $tmp/chelsa/$name.zip  $zip/chelsa_bioclim_v2_1/1981-2010_observed/$ch
done

