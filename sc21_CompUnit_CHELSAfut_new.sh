#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 01:10:00
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc21_CompUnit_CHELSAfut_new.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc21_CompUnit_CHELSAfut_new.sh.%A_%a.err
#SBATCH --mem-per-cpu=25000M
#SBATCH --array=1-9462%100      ###   28386 

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_new.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

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

module purge
module load GRASS/8.2.0-foss-2022b

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES
#export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/2041-2070
#export REFS=/home/jg2657/CU_refIDS.txt
export REFS=/home/jg2657/list_array_chelsa.txt

#export CU=$3
export DATFOLDER=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export ROW=$SLURM_ARRAY_TASK_ID
export CU=$(awk -v r="${ROW}" 'NR == r {print $1}' $REFS)
export chelsa=$(awk -v r="${ROW}" 'NR == r {print $2}' $REFS)

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

for ref in $(cat $HOME/CU_refIDS.txt)
do 
    zip -r $DIR/CU_${ref}.zip $DIR/CU_${ref}
done 

for i in {1..63}
do
    rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES/CU_${i}.zip YaleGDrive:CHELSA-FUT
    echo "DONE CU_${i}"
done

# in GRACE
rclone copy  /gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES YaleGDrive:CHELSA-FUT

## in server 2
rclone --local-no-set-modtime copy YaleGDrive:CHELSA-FUT /mnt/shared/regional_unit_tables_bio_fut/newfiles
