#!/bin/bash

#SBATCH --job-name=severe-CDI

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100MB
#SBATCH --time=72:00:00

#SBATCH --output=log/hpc/slurm-%j_%x.out

#SBATCH --account=YOUR_ACCOUNT_HERE
#SBATCH --partition=standard

#SBATCH --mail-user=YOUR_EMAIL_HERE
#SBATCH --mail-type=BEGIN,END

mkdir -p log/hpc/
time snakemake --profile config/slurm --use-conda
