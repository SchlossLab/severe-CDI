
rule preprocess_data:
    input:
        R="workflow/scripts/preproc.R",
        csv=config['dataset']
    output:
        rds='data/dat_proc.Rds'
    log:
        "log/preprocess_data.txt"
    benchmark:
        "benchmarks/preprocess_data.txt"
    threads: ncores
    script:
        "workflow/scripts/preproc.R"

rule run_ml:
    input:
        R="workflow/scripts/ml.R",
        rds=rules.preprocess_data.output.rds
    output:
        model="results/runs/{method}_{seed}_model.Rds",
        perf=temp("results/runs/{method}_{seed}_performance.csv"),
        feat=temp("results/runs/{method}_{seed}_feature-importance.csv")
    log:
        "log/runs/run_ml.{method}_{seed}.txt"
    benchmark:
        "benchmarks/runs/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=config['outcome_colname'],
        method="{method}",
        seed="{seed}",
        kfold=kfold
    threads: ncores
    script:
        "workflow/scripts/ml.R"

rule combine_results:
    input:
        R="workflow/scripts/combine_results.R",
        csv=expand("results/runs/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/{type}_results.csv'
    log:
        "log/combine_results_{type}.txt"
    benchmark:
        "benchmarks/combine_results_{type}.txt"
    script:
        "workflow/scripts/combine_results.R"

rule combine_feat_importance:
    input:
        R="workflow/scripts/combine_feat_imp.R",
        csv=expand("results/runs/{method}_{seed}_feature_importance.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/{type}_feat_imp.csv'
    log:
        "log/combine_feat_imp_{type}.txt"
    benchmark:
        "benchmarks/combine_feat_imp_{type}.txt"
    script:
        "workflow/scripts/combine_feat_imp.R"

rule combine_hp_performance:
    input:
        R='workflow/scripts/combine_hp_perf.R',
        rds=expand('results/runs/{{method}}_{seed}_model.Rds', seed=seeds)
    output:
        rds='results/hp_performance_results_{method}.Rds'
    log:
        "log/combine_hp_perf_{method}.txt"
    benchmark:
        "benchmarks/combine_hp_perf_{method}.txt"
    script:
        "workflow/scripts/combine_hp_perf.R"

rule combine_benchmarks:
    input:
        R='workflow/scripts/combine_benchmarks.R',
        tsv=expand(rules.run_ml.benchmark, method = ml_methods, seed = seeds)
    output:
        csv='results/benchmarks_results.csv'
    log:
        'log/combine_benchmarks.txt'
    script:
        'workflow/scripts/combine_benchmarks.R'

rule plot_performance:
    input:
        R="workflow/scripts/plot_perf.R",
        csv='results/performance_results.csv'
    output:
        plot='figures/performance.png'
    log:
        "log/plot_performance.txt"
    script:
        "workflow/scripts/plot_perf.R"

rule plot_hp_performance:
    input:
        R='workflow/scripts/plot_hp_perf.R',
        rds=rules.combine_hp_performance.output.rds,
    output:
        plot='figures/hp_performance_{method}.png'
    log:
        'log/plot_hp_perf_{method}.txt'
    script:
        'workflow/scripts/plot_hp_perf.R'

rule plot_benchmarks:
    input:
        R='workflow/scripts/plot_benchmarks.R',
        csv=rules.combine_benchmarks.output.csv
    output:
        plot='figures/benchmarks.png'
    log:
        'log/plot_benchmarks.txt'
    script:
        'workflow/scripts/plot_benchmarks.R'

rule render_report:
    input:
        Rmd='workflow/report/report.Rmd',
        R='workflow/scripts/render.R',
        perf_plot=rules.plot_performance.output.plot,
        hp_plot=expand(rules.plot_hp_performance.output.plot, method = ml_methods),
        bench_plot=rules.plot_benchmarks.output.plot
    output:
        doc='workflow/report/report.md'
    log:
        "log/render_report.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'workflow/scripts/render.R'

rule clean:
    input:
        rules.render_report.output,
        rules.plot_performance.output.plot,
        rules.plot_benchmarks.output.plot
    shell:
        '''
        rm -rf {input}
        '''
