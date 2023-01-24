
rule prep_temporal_split:
    input:
        metadat='data/process/cases_int_metadata.csv'
    output:
        rds="data/process/temporal-split/predict_{outcome}/taxlevel_{taxlevel}/dataset_{dataset}/trainfrac_{trainfrac}/train-idx.Rds"
    script:
        "../scripts/prep_temporal_split.R"

rule run_ml_temporal_split:
    input:
        R="workflow/scripts/ml.R",
        rds=rules.preprocess_data.output.rds,
        train=rules.prep_temporal_split.output.rds
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

rule targets_temporal_split:
    input:
        expand(rules.run_ml_temporal_split.output.test,
                outcome = outcomes, taxlevel = tax_levels, metric = metrics,
                dataset = ['int'], trainfrac = train_fracs,
                method = ml_methods, seed = seeds
        )
