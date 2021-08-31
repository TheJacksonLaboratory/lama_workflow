#!/bin/bash
#SBATCH -J lama_test_$SLURM_ARRAY_TASK_ID
#SBATCH -o lama_test_$SLURM_ARRAY_TASK_ID.out
#SBATCH -e lama_test_$SLURM_ARRAY_TASK_ID.err
#SBATCH -t 1-00:00:00
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --mem=20000

# Singularity command line options
module load singularity
singularity exec LAMA.sif lama_walkthroughs/spatially_normalise_data.sh > lama_$SLURM_ARRAY_TASK_ID.log
