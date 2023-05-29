rule prep_temporal_split:
    input:
        metadat='data/process/cases_{dataset}_metadata.csv'
    output:
        rds="data/process/temporal-split/predict_{outcome}/taxlevel_{taxlevel}/dataset_{dataset}/trainfrac_{trainfrac}/train-idx.Rds"
    log: 'log/temporal-split/predict_{outcome}/taxlevel_{taxlevel}/dataset_{dataset}/trainfrac_{trainfrac}/prep_temporal_split.txt'
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/prep_temporal_split.R"

rule run_ml_temporal_split:
    input:
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
        mem_mb=MEM_PER_GB*1
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/train_ml_temporal_split.R"

rule mutate_benchmark:
    input:
        tsv="benchmarks/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/run_ml.{method}_{seed}.txt"
    output:
        csv="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_benchmarks.csv"
    log:
        "log/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/mutate_benchmark.{method}_{seed}.txt"
    conda: "../envs/mikropml.yml"
    script:
        '../scripts/mutate_benchmark.R'

rule calc_model_sensspec_temporal:
    input:
        rds=rules.preprocess_data.output.rds,
        model=rules.run_ml_temporal_split.output.model,
        test=rules.run_ml_temporal_split.output.test,
    output:
        sensspec="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_sensspec.csv",
        thresholds="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_thresholds.csv"
    log:
        "log/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_sensspec.log"
    params:
        outcome_colname="{outcome}"
    conda:
        "../envs/mikropml.yml"
    script:
        "../scripts/calc_model_sensspec.R"

rule combine_results_temporal:
    input:
        csv=expand("results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/temporal-split/{method}_{seed}_{{rtype}}.csv", outcome = outcomes, taxlevel = tax_levels, metric = metrics, dataset = datasets, trainfrac = train_fracs, method = ml_methods, seed = seeds)
    output: csv='results/temporal-split/{rtype}_results.csv'
    log: "log/combine_results_{rtype}.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/combine_results.R"

rule targets_temporal_split:
    input: expand('results/temporal-split/{rtype}_results.csv', rtype = result_types)

# TODO plot performance & feature importance
