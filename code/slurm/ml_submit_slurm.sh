#!/bin/bash

#SBATCH --job-name=mikropml_3_comparisons

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100MB
#SBATCH --time=72:00:00

#SBATCH --output=log/hpc/slurm-%j_%x.out

#SBATCH --account=pschloss1
#SBATCH --partition=standard

#SBATCH --mail-user=tomkoset@umich.edu
#SBATCH --mail-type=BEGIN,END

time snakemake --unlock --profile config/slurm --latency-wait 90 --configfile config/config.yml --forcerun report_dataset2.md report_dataset3.md report_dataset1.md
