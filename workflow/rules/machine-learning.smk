ruleorder: run_ml > mikropml_find_feature_importance

rule preprocess_data:
    input:
        csv="data/process/{outcome}_{dataset}_{taxlevel}.csv",
        logR="workflow/scripts/log_smk.R"
    output:
        rds='data/process/dat-proc_{outcome}_{dataset}_{taxlevel}.Rds'
    log: "log/preprocess_data_{outcome}_{dataset}_{taxlevel}.txt"
    benchmark:
        "benchmarks/preprocess_data_{outcome}_{dataset}_{taxlevel}.txt"
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*2
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/preproc.R"

rule run_ml:
    input:
        rds=rules.preprocess_data.output.rds,
        logR="workflow/scripts/log_smk.R"
    output:
        model="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_model.Rds",
        perf="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_performance.csv",
        feat="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_feature-importance.csv",
        test="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_test-data.csv"
    log: "log/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/run_ml.{method}_{seed}.txt"
    benchmark: "benchmarks/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/run_ml.{method}_{seed}.txt"
    params:
        method="{method}",
        seed="{seed}",
        kfold=kfold
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*4
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/ml.R"

use rule calc_model_sensspec from mikropml as mikropml_calc_model_sensspec with:
    output:
        csv="results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_sensspec.csv"
    log:
        "log/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_sensspec.csv"
    params:
        outcome_colname="{outcome}"

rule combine_results:
    input:
        csv=expand("results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_{{type}}.csv",
                    outcome = outcomes, taxlevel = tax_levels, metric = metrics,
                    dataset = datasets, trainfrac = train_fracs,
                    method = ml_methods, seed = seeds)
    output: csv='results/{type}_results_aggregated.csv'
    log: "log/combine_results_{type}.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/combine_results.R"
