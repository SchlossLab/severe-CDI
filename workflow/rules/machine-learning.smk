
rule preprocess_data:
    input:
        R="workflow/scripts/preproc.R",
        csv="data/process/{outcome}_OTUs.csv"
    output:
        rds='data/process/dat_proc_{outcome}.Rds'
    log: "log/preprocess_data_{outcome}.txt"
    benchmark:
        "benchmarks/preprocess_data_{outcome}.txt"
    threads: ncores
    params:
        mem_mb=MEM_PER_GB*2
    script:
        "workflow/scripts/preproc.R"

rule run_ml:
    input:
        R="workflow/scripts/ml.R",
        rds=rules.preprocess_data.output.rds
    output:
        model="results/predict_{outcome}/{method}_{seed}_model.Rds",
        perf=temp("results/predict_{outcome}/{method}_{seed}_performance.csv")
    log: "log/predict_{outcome}/run_ml.{method}_{seed}.txt"
    benchmark: "benchmarks/predict_{outcome}/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=config['outcome_colname'],
        method="{method}",
        seed="{seed}",
        kfold=kfold
    threads: ncores
    resources:
        mem_mb=MEM_PER_GB*4
    script:
        "workflow/scripts/ml.R"

rule combine_results:
    input:
        R="workflow/scripts/combine_results.R",
        csv=expand("results/predict_{{outcome}}/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output: csv='results/predict_{outcome}/{type}_results.csv'
    log: "log/predict_{outcome}/combine_results_{type}.txt"
    benchmark:
        "benchmarks/predict_{outcome}/combine_results_{type}.txt"
    script:
        "workflow/scripts/combine_results.R"

