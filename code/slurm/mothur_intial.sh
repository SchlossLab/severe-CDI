#!/bin/bash

###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################

# Name
#SBATCH --job-name=mothur_p5-8

# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4GB
#SBATCH --time=5:00:00

# Account
#SBATCH --account=pschloss1
#SBATCH --partition=standard

# Logs
#SBATCH --mail-user=tomkoset@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.out

# Environment
#SBATCH --export=ALL

# To run mothur. bin/mothur from  /nfs/turbo/schloss-lab which is built with Boost, needed for .gz files

#####################
#                   #
#  2) Job Commands  #
#                   #
#####################


/nfs/turbo/schloss-lab/bin/mothur code/get_good_seqs.batch
/nfs/turbo/schloss-lab/bin/mothur code/get_shared_otus.batch
