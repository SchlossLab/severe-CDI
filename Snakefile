configfile: 'config/config.yml'

ncores = config['ncores']
ml_methods = config['ml_methods']
kfold = config['kfold']

nseeds = config['nseeds']
start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

include: 'code/mothur/mothur.smk'
include: 'code/machine-learning/machine-learning.smk'

rule targets:
    input:
        'report.md'

rule classify_idsa_severity:
    input:
        "code/utilities.R",
        "data/process/final_CDI_16S_metadata.tsv",
        "data/raw/max_creat.csv",
        "data/raw/max_wbc.csv",
        "data/raw/r21_fullcohort_edited_deidentified.csv",
        "data/raw/HPI-1878 Lab.csv"
    output:
        csv="data/process/case_idsa_severity.csv",
        png="results/figures/idsa_severe_n.png"
    script:
        'code/severity_analysis.R'
