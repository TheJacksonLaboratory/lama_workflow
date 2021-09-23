#!/bin/bash
#SBATCH -J lama_spatial
#SBATCH -o lama_spatial.out
#SBATCH -e lama_spatial.err
#SBATCH -t 1-00:00:00
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --mem=20000

# Singularity command line options
module load singularity
singularity exec LAMA.sif lama_workspace/spatially_normalise_data.sh 2> lama_workspace/lama_spatial_$SLURM_ARRAY_TASK_ID.err 1> lama_workspace/lama_spatial_$SLURM_ARRAY_TASK_ID.out

