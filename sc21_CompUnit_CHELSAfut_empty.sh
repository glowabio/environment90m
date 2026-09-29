#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 00:30:00
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc21_CompUnit_CHELSAfut_empty.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc21_CompUnit_CHELSAfut_empty.sh.%A_%a.err
#SBATCH --mem-per-cpu=25000M
#SBATCH --array=1-178    ### 178 empty tables

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_empty.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sbatch  /home/jg2657/project/code/environmental-data-extraction/sc21_CompUnit_CHELSAfut_empty.sh
# salloc -t 2:00:00 --mem=8G


module purge
module load GRASS/8.2.0-foss-2022b

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES
export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio/future/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/

export EMPTY=/home/jg2657/incomp_files.txt
export DATFOLDER=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

export ROW=$SLURM_ARRAY_TASK_ID

export file=$(awk -F_ -v r="$ROW" 'NR == r' $EMPTY)
export VAR=$(basename $file .txt* | awk -F_ 'BEGIN{OFS="_";} {print $3, $4, $5, $6, $7, $8}')
export TIF=$(echo ${VAR}.tif)
export CU=$(echo $file | awk -F_ '{print $2}')

grass  -f --gtext --tmp-location  $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif <<'EOF'

#  Read files with subcatchments
r.in.gdal --o input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
    output=micb 
  
r.external input=$(find $CHELSA -name "$TIF") output=chelsa --overwrite
  
  echo "subcID min max range mean sd" > $DIR/empty/stats_${CU}_${VAR}.txt  
  
  r.univar -t --o map=chelsa zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> $DIR/empty/stats_${CU}_${VAR}.txt

EOF
exit

rclone mkdir YaleGDrive:empty
rclone copy ./empty YaleGDrive:empty
## in server 2
rclone copy YaleGDrive:empty missing
rclone copy $DIR/empty/stats_${CU}_${VAR}.txt  YaleGDrive:empty
rclone copy YaleGDrive:empty/stats_87_CHELSA_bio19_2071-2100_mpi-esm1-2-hr_ssp585_V.2.1.txt missing


cp $HOME/missing/stats_87_CHELSA_bio19_2071-2100_mpi-esm1-2-hr_ssp585_V.2.1.txt  /mnt/shared/regional_unit_tables_bio_fut/CU_87




