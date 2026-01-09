#! /bin/bash

export tmp=/mnt/shared/tmp
export regunit=/mnt/shared/hydrography90m_v.1.0_online/hydrography90m_v.1.0/global/regional_unit_ovr.tif
export out=/mnt/shared/tiles_tb/indx
export subc=/mnt/shared/hydrography90m_v.1.0_online/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d
export sc=/mnt/shared/hydrography90m_v.1.0_online/hydrography90m_v.1.0/global/sub_catchment_ovr.tif

touch /mnt/shared/tiles_tb/tile_numberIDs.txt
touch /mnt/shared/tiles_tb/tile_RUids.txt

###  Procedure to create a look up table with tiles IDs and Regional Units IDs in each Tile

# get bbox of tile

files=( $(find /mnt/shared/temp_for_deletion/hydrography90m_v1_2022_all_data_OLD/basin_tiles_final20d_1p  -name "*[0-9].tif") )


for tile in ${files[@]}
#do
# tile=/mnt/shared/hydrography90m_v1_2022_all_data_OLD/basin_tiles_final20d_1p/basin_h08v04.tif
# save name
#export name=$(basename $tile .tif | awk -F_ '{print $2}')
#echo $name 
#done | sort > $HOME/tiles.txt

do
# tile=/mnt/shared/hydrography90m_v1_2022_all_data_OLD/basggin_tiles_final20d_1p/basin_h34v10.tif
# save name
export name=$(basename $tile .tif | awk -F_ '{print $2}')

# crop
#pkcrop -i $regunit \
#    $(pkinfo -i $tile -te) \
#    -o $tmp/cropru_$name.tif

#gdalwarp -te -100 25 -80 45 $regunit $tmp/cropru_$name.tif
#gdalwarp -te -100 25 -80 45 $sc $tmp/sc_$name.tif

gdalwarp $(pkinfo -i $tile -te)  $regunit $tmp/cropru_$name.tif
gdalwarp $(pkinfo -i $tile -te)  $sc $tmp/sc_$name.tif

grass -f --gtext --tmp-location $tile <<'EOF'

#r.in.gdal --o input=$subc/sub_catchment_${name}.tif  out=subc_${name}

r.in.gdal --o input=$tmp/sc_$name.tif  out=subc_${name}
r.in.gdal --o input=$tmp/cropru_$name.tif out=cropru_$name

rus=($(r.stats -n in=cropru_$name))

echo $name ${rus[@]} >> /mnt/shared/tiles_tb/tile_RUids.txt

r.stats -ac in=subc_${name} | head -n -1 > $out/${name}_subcID.txt

echo " $name $(wc -l < $out/${name}_subcID.txt)" \
>> /mnt/shared/tiles_tb/tile_numberIDs.txt

#for R in ${rus[@]}
#do
#    r.mapcalc --o "subcmask = if(cropru_$name == $R, subc_${name}, null())"
#    r.stats -ac in=subcmask | head -n -1 > $out/${name}_${R}_subcID.txt
#done

EOF

# delete temp
rm $tmp/cropru_$name.tif
rm $tmp/sc_$name.tif

done

############################################################
############################################################




