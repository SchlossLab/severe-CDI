#!/bin/bash

###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################

# Name
#SBATCH --job-name=permanova

# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=100GB
#SBATCH --time=48:00:00

# Account
#SBATCH --account=pschloss1
#SBATCH --partition=standard

# Logs
#SBATCH --mail-user=tomkoset@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.out

# Environment
#SBATCH --export=ALL

# To run r & vegan adonis(): conda activate rstats before submitting job.
# --max-ppsize 500000 suggested by Kelly to work around memory issues

#####################
#                   #
#  2) Job Commands  #
#                   #
#####################

Rscript --max-ppsize 500000 code/pcoa_data.R
