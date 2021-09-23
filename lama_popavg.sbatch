#!/bin/bash
#SBATCH -J lama_popavg
#SBATCH -o lama_popavg.out
#SBATCH -e lama_popavg.err
#SBATCH -t 1-00:00:00
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --mem=20000

# Singularity command line options
module load singularity
singularity exec LAMA.sif lama_workspace/population_average.sh 2> lama_workspace/lama_popavg.err 1> lama_workspace/lama_popavg.out
