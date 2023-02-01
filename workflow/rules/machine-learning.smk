
rule preprocess_data:
    input:
        R="workflow/scripts/preproc.R",
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
        R="workflow/scripts/ml.R",
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


rule combine_results:
    input:
        R="workflow/scripts/combine_results.R",
        csv=expand("results/predict_{outcome}/taxlevel_{taxlevel}/metric_{metric}/dataset_{dataset}/trainfrac_{trainfrac}/runs/{method}_{seed}_{{type}}.csv",
                    outcome = outcomes, taxlevel = tax_levels, metric = metrics,
                    dataset = datasets, trainfrac = train_fracs,
                    method = ml_methods, seed = seeds)
    output: csv='results/{type}_results_aggregated.csv'
    log: "log/combine_results_{type}.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/combine_results.R"
