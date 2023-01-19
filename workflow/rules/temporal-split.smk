
rule targets_temporal_split:
    input:
        expand("results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_model.Rds", )

rule prep_temporal_split:
    input:
        full_metadata='data/process/cases_full_metadata.csv',
        int_metadata='data/process/cases_int_metadata.csv'
        otu_dat='data/mothur/cdi.opti_mcc.shared'
    output:
        expand("data/process/temporal-split/train-idx_{outcome}_{dataset}_{taxlevel}.Rds", 
               outcome = outcomes, 
               dataset = ['int'], 
               taxlevel = tax_levels
        )

rule run_ml_temporal_split:
    input:
        R="workflow/scripts/ml.R",
        rds=rules.preprocess_data.output.rds,
        train="data/process/temporal-split/train-idx_{outcome}_{dataset}_{taxlevel}.Rds"
    output:
        model="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_model.Rds",
        perf="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_performance.csv",
        feat="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_feature-importance.csv",
        test="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_test-data.csv"
    log: "log/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/run_ml.{method}_{seed}.txt"
    benchmark: "benchmarks/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/run_ml.{method}_{seed}.txt"
    params:
        method="{method}",
        seed="{seed}",
        kfold=kfold
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*4
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/train_ml_temporal_split.R"
