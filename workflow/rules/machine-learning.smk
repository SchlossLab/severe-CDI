
rule preprocess_data:
    input:
        R="workflow/scripts/preproc.R",
        csv="data/process/{outcome}_OTUs.csv",
        logR="workflow/scripts/log_smk.R"
    output:
        rds='data/process/dat_proc_{outcome}.Rds'
    log: "log/preprocess_data_{outcome}.txt"
    benchmark:
        "benchmarks/preprocess_data_{outcome}.txt"
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*2
    script:
        "../scripts/preproc.R"

rule run_ml:
    input:
        R="workflow/scripts/ml.R",
        rds=rules.preprocess_data.output.rds,
        logR="workflow/scripts/log_smk.R"
    output:
        model="results/predict_{outcome}/{method}_{seed}_model.Rds",
        perf=temp("results/predict_{outcome}/{method}_{seed}_performance.csv")
    log: "log/predict_{outcome}/run_ml.{method}_{seed}.txt"
    benchmark: "benchmarks/predict_{outcome}/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname="{outcome}",
        method="{method}",
        seed="{seed}",
        kfold=kfold
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*4
    script:
        "../scripts/ml.R"

rule combine_results:
    input:
        R="workflow/scripts/combine_results.R",
        csv=expand("results/predict_{{outcome}}/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output: csv='results/predict_{outcome}/{type}_results.csv'
    log: "log/predict_{outcome}/combine_results_{type}.txt"
    benchmark:
        "benchmarks/predict_{outcome}/combine_results_{type}.txt"
    script:
        "../scripts/combine_results.R"
