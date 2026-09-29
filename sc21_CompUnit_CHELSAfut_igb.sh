#!/bin/bash

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_new.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# scp Code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_igb.sh sv2:/home/marquez

#sbatch /home/marquez/sc21_CompUnit_CHELSAfut_igb.sh 94 /home/marquez/chelsav2/GLOBAL/climatologies/2071-2100/MPI-ESM1-2-HR/ssp370/bio/CHELSA_bio18_2071-2100_mpi-esm1-2-hr_ssp370_V.2.1.tif

# sbatch  /home/jg2657/project/code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_new.sh
# sacct -j 4535902 --format=JobID%15,State,Elapsed
# srun --pty -t 6:00:00 --mem=20G  -p interactive bash
# salloc -t 6:00:00 --mem=8G

#find $CHELSA -name "*.tif" > $HOME/chelsa_fut_files.txt
#awk 'FNR==NR{a[$1];next}{for(i in a) print i, $1}' \
#    $HOME/CU_refIDS.txt $HOME/chelsa_fut_files.txt \
#    > $HOME/list_array_chelsa_fut.txt

#awk 'FNR==NR{a[$1];next}{for(i in a) print i, $1}' \
#    $HOME/CU_refIDS.txt $HOME/chelsa_fut_files126.txt \
#    > $HOME/list_array_chelsa_fut126.txt

#for cu in $(cat $HOME/CU_refIDS.txt)
#do
#    echo "$cu /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio/future/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/2071-2100/MPI-ESM1-2-HR/ssp370/bio/CHELSA_bio18_2071-2100_mpi-esm1-2-hr_ssp370_V.2.1.tif"
#done >> /home/jg2657/list_array_chelsa.txt

#export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES
export DIR=/mnt/shared/regional_unit_tables_bio_fut
#export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/2041-2070
#export REFS=/home/jg2657/CU_refIDS.txt
#export REFS=/home/jg2657/list_array_chelsa.txt

#export CU=$3
#export DATFOLDER=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export DATFOLDER=/mnt/shared/regional_unit_baseline/hydrography90m_v1_2022_all_data_OLD
#export ROW=$SLURM_ARRAY_TASK_ID
#export CU=$(awk -v r="${ROW}" 'NR == r {print $1}' $REFS)
export CU=$1
#export chelsa=$(awk -v r="${ROW}" 'NR == r {print $2}' $REFS)
export chelsa=$2

#mkdir -p $DIR/CU_${CU}
#for r in $(cat $HOME/CU_refIDS.txt)
#do
#    mkdir /gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES/CU_$r
#done

export OUT=$DIR/CU_${CU}

grass  -f --gtext --tmp-location  $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'

#  Read files with subcatchments
r.in.gdal --o input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
    output=micb 

 VAR=$(basename $chelsa .tif)
  
  [[ -f $OUT/stats_${CU}_${VAR}.txt  ]] && continue
  
  r.external input=$chelsa output=$VAR --overwrite
  
  echo "subcID min max range mean sd" > $OUT/stats_${CU}_${VAR}.txt  

  r.univar -t --o map=$VAR zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> $OUT/stats_${CU}_${VAR}.txt

EOF


exit
