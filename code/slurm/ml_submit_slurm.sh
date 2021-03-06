#!/bin/bash

#SBATCH --job-name=mikropml_CvNDC_lefse

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100MB
#SBATCH --time=48:00:00

#SBATCH --output=log/hpc/slurm-%j_%x.out

#SBATCH --account=pschloss1
#SBATCH --partition=standard

#SBATCH --mail-user=tomkoset@umich.edu
#SBATCH --mail-type=BEGIN,END

time snakemake --profile config/slurm --latency-wait 90 --configfile config/config.yml
