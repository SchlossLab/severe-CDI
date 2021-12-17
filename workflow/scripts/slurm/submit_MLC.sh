#!/bin/bash

#SBATCH --job-name=adverseCDI

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100MB
#SBATCH --time=72:00:00

#SBATCH --output=log/hpc/slurm-%j_%x.out

#SBATCH --account=pschloss1
#SBATCH --partition=standard

#SBATCH --mail-user=mlcoden@umich.edu
#SBATCH --mail-type=BEGIN,END

mkdir -p log/hpc/
time snakemake --profile config/slurm_mlc -s workflow/Snakefile --configfile config/test.yml
