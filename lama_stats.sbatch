#!/bin/bash
#SBATCH -J lama_stats
#SBATCH -o lama_stats.out
#SBATCH -e lama_stats.err
#SBATCH -t 1-00:00:00
#SBATCH -N 1
#SBATCH -c 2
#SBATCH --mem=120000

# Singularity command line options
module load singularity
#singularity exec LAMA.sif lama_workspace/stats_with_BH_correction.sh 2> lama_workspace/lama_stats.err 1> lama_workspace/lama_stats.out
singularity exec LAMA.sif lama_walkthroughs/stats_with_BH_correction.sh 2> lama_walkthroughs/lama_stats.err 1> lama_walkthroughs/lama_stats.out
