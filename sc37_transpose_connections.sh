#! /bin/bash
# mkdir /mnt/shared/tmp/connections
export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/Environment90m_v.1.0_online/hydrography90m_v1_0
export layers=/mnt/shared/temp_for_deletion/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_connections(){

# define the tile to work with
nm=${1}

fol=connections

[[ ! -d $zip/${fol} ]] && mkdir $zip/${fol}

# exit if file already exist
[[ -f $zip/${fol}/${fol}_${nm}.zip ]] &&  \
    { echo >&2 "${fol}_${nm}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

for j in ${tbids[@]}
do

    # if file is empty go to next one
    [[ ! -s $j ]] && continue

    # extract ru number
    ru=$(basename $j .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_streamorder.txt")

    declare -a cols  ## array holding original columns from original data file
    declare -a colnum ## array holding position of columns of interest
    declare -a colnam ## array holding names of column of interest

    cols=( $(head -n1 $tb) )  ## fill cols from 1st line of data file

    # identify in which position the prev_ columns are and create the tmp file
    for i in "${!cols[@]}"; do
       if [[ "${cols[$i]}" == *"prev_"* ]]; then
            colnum[$i]=$(echo "${i}" + 1 | bc)
            colnam[$i]="${cols[$i]}"
       fi
    done

    echo "${colnam[@]}" >> $tmp/colnames_connections/colnames_${nm}.txt

    printf -v joined '%s,' "${colnum[@]}"
    # subset the table with columns of interest
    cut -d" " -f1,2,"$(echo "${joined%,}")" $tb > $tmp/sub_${fol}_${ru}_${nm}.txt

    # extract subc of interst only
     awk 'NR == FNR {a[$1]; next} $1 in a' \
         $j $tmp/sub_${fol}_${ru}_${nm}.txt \
         >> ${tmp}/connections/${fol}_${nm}.txt 
    
     rm $tmp/sub_${fol}_${ru}_${nm}.txt 
 
 done

}


export -f TransposeTable_connections
time parallel -j 20  TransposeTable_connections :::: /mnt/shared/tiles_tb/tiles.txt 
#time parallel -j 1  TransposeTable_connections ::: h34v06



#####   next steps:
# 1. check that the colnmaes for each tile files have the same number of columns

for f in $(ls $tmp/colnames_connections)
do
   nr=$(awk '{print NF}' $tmp/colnames_connections/$f | sort | uniq -c | wc -l)
   echo "$f  $nr" >> $tmp/check.txt
done

### and the anwer is YES
# 2. if yes, then add column names to connection files
h10v04
time for tile in $(cat /mnt/shared/tiles_tb/tiles.txt)
do
    nr=$(awk -v T="colnames_${tile}.txt"  '$1 == T {print $2}' $tmp/check.txt)
    if [ "$nr" -eq 1 ]
    then
        # prepare header
        echo "subcID next_stream $(awk 'NR==1' $tmp/colnames_connections/colnames_${tile}.txt)" \
            > $tmp/header_${tile}

        cat $tmp/header_${tile} $tmp/connections/connections_${tile}.txt \
            > $tmp/connections/connections_${tile}_comp.txt

        rm $tmp/header_${tile} 
#       rm $tmp/connections/connections_${tile}.txt

    else
        # identify the row where the larger number of olumns is
        gn=$(awk '{print NR, NF}'  $tmp/colnames_connections/colnames_$tile.txt \
            | sort -n -k2 -r | awk 'NR==1{print $1}')
        # extrcat column names
        colnames=$(awk -v ROW="${gn}" 'NR==ROW' $tmp/colnames_connections/colnames_$tile.txt)
        # prepare header 
        echo "subcID next_stream $(echo $colnames)" > $tmp/header_${tile}

        # fill in the empty rows

        # which row is needed to be filled in?
        fr=$(awk '{print NF}' $tmp/header_${tile})
        # and fill in with zeros
        awk -v R="${fr}"  '{if ($R == "") $R = "0"; print}' \
            $tmp/connections/connections_${tile}.txt \
            >  $tmp/connections/connections_${tile}_comp.txt
        
        ## this is only for tile h10v04
        #awk '{for(i=1;i<=7;i++) {if($i == "") $i = 0;} }1' \
        #    $tmp/connections/connections_${tile}.txt \
        #    >  $tmp/connections/connections_${tile}_comp.txt

        rm $tmp/header_${tile} 
#       rm $tmp/connections/connections_${tile}.txt

    fi
done

# 3. zip file in final destination ($zip/connections)
fol=connections
time for tile in $(cat /mnt/shared/tiles_tb/tiles.txt)
do
# delete if file already exist
#[[ -f $zip/${fol}/${fol}_${nm}.zip ]] && rm $zip/${fol}/${fol}_${nm}.zip

mv $tmp/connections/connections_${tile}_comp.txt  \
    $tmp/conn_final/connections_${tile}.txt

zip -jq $zip/${fol}/${fol}_${tile}.zip \
    $tmp/conn_final/${fol}_${tile}.txt 

#rm $tmp/connections/connections_${tile}.txt


done

# 4. delete temp files

