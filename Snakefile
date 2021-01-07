configfile: 'config/config.yml'

ncores = config['ncores']
ml_methods = config['ml_methods']
kfold = config['kfold']

nseeds = config['nseeds']
start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

rule targets_1:
    input:
        'report_dataset1.md'

rule targets_2:
    input:
        'report_dataset2.md'

rule targets_3:
    input:
        'report_dataset3.md'

rule preprocess_data1:
    input:
        R="code/preproc.R",
        csv=config['dataset1']
    output:
        rds='data/dat_proc1.Rds'
    log:
        "log/preprocess_data1.txt"
    benchmark:
        "benchmarks/preprocess_data1.txt"
    resources:
        ncores=ncores
    script:
        "code/preproc.R"

rule run_ml_1:
    input:
        R="code/ml.R",
        rds=rules.preprocess_data1.output.rds
    output:
        model="results/runs/dataset1/{method}_{seed}_model.Rds",
        perf=temp("results/runs/dataset1/{method}_{seed}_performance.csv"),
        feat=temp("results/runs/dataset1/{method}_{seed}_feature-importance.csv")
    log:
        "log/runs/dataset1/run_ml.{method}_{seed}.txt"
    benchmark:
        "benchmarks/runs/dataset1/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=config['outcome_colname'],
        method="{method}",
        seed="{seed}",
        kfold=kfold
    resources:
        ncores=ncores
    script:
        "code/ml.R"

rule combine_results_1:
    input:
        R="code/combine_results.R",
        csv=expand("results/runs/dataset1/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/dataset1/{type}_results.csv'
    log:
        "log/dataset1/combine_results_{type}.txt"
    benchmark:
        "benchmarks/dataset1/combine_results_{type}.txt"
    script:
        "code/combine_results.R"

rule combine_benchmarks_1:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml_1.benchmark, method = ml_methods, seed = seeds)
    output:
        csv='results/dataset1/benchmarks_results.csv'
    log:
        'log/dataset1/combine_benchmarks.txt'
    script:
        'code/combine_benchmarks.R'

rule plot_performance_1:
    input:
        R="code/plot_perf.R",
        csv='results/dataset1/performance_results.csv'
    output:
        plot='figures/performance_dataset1.png'
    log:
        "log/plot_performance_dataset1.txt"
    script:
        "code/plot_perf.R"

rule plot_benchmarks_1:
    input:
        R='code/plot_benchmarks.R',
        csv=rules.combine_benchmarks_1.output.csv
    output:
        plot='figures/benchmarks_dataset1.png'
    log:
        'log/plot_benchmarks_dataset1.txt'
    script:
        'code/plot_benchmarks.R'

rule render_report_1:
    input:
        Rmd='report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance_1.output.plot,
        bench_plot=rules.plot_benchmarks_1.output.plot
    output:
        doc='report_dataset1.md'
    log:
        "log/render_report_dataset1.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'code/render.R'

rule clean_1:
    input:
        rules.render_report_1.output,
        rules.plot_performance_1.output.plot,
        rules.plot_benchmarks_1.output.plot
    shell:
        '''
        rm -rf {input}
        '''

rule preprocess_data2:
    input:
        R="code/preproc.R",
        csv=config['dataset2']
    output:
        rds='data/dat_proc2.Rds'
    log:
        "log/preprocess_data2.txt"
    benchmark:
        "benchmarks/preprocess_data2.txt"
    resources:
        ncores=ncores
    script:
        "code/preproc.R"

rule run_ml_2:
    input:
        R="code/ml.R",
        rds=rules.preprocess_data2.output.rds
    output:
        model="results/runs/dataset2/{method}_{seed}_model.Rds",
        perf=temp("results/runs/dataset2/{method}_{seed}_performance.csv"),
        feat=temp("results/runs/dataset2/{method}_{seed}_feature-importance.csv")
    log:
        "log/runs/dataset2/run_ml.{method}_{seed}.txt"
    benchmark:
        "benchmarks/runs/dataset2/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=config['outcome_colname'],
        method="{method}",
        seed="{seed}",
        kfold=kfold
    resources:
        ncores=ncores
    script:
        "code/ml.R"

rule combine_results_2:
    input:
        R="code/combine_results.R",
        csv=expand("results/runs/dataset2/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/dataset2/{type}_results.csv'
    log:
        "log/dataset2/combine_results_{type}.txt"
    benchmark:
        "benchmarks/dataset2/combine_results_{type}.txt"
    script:
        "code/combine_results.R"

rule combine_benchmarks_2:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml_2.benchmark, method = ml_methods, seed = seeds)
    output:
        csv='results/dataset2/benchmarks_results.csv'
    log:
        'log/dataset2/combine_benchmarks.txt'
    script:
        'code/combine_benchmarks.R'

rule plot_performance_2:
    input:
        R="code/plot_perf.R",
        csv='results/dataset2/performance_results.csv'
    output:
        plot='figures/performance_dataset2.png'
    log:
        "log/plot_performance_dataset2.txt"
    script:
        "code/plot_perf.R"

rule plot_benchmarks_2:
    input:
        R='code/plot_benchmarks.R',
        csv=rules.combine_benchmarks_2.output.csv
    output:
        plot='figures/benchmarks_dataset2.png'
    log:
        'log/plot_benchmarks_dataset2.txt'
    script:
        'code/plot_benchmarks.R'

rule render_report_2:
    input:
        Rmd='report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance_2.output.plot,
        bench_plot=rules.plot_benchmarks_2.output.plot
    output:
        doc='report_dataset2.md'
    log:
        "log/render_report_dataset2.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'code/render.R'

rule clean_2:
    input:
        rules.render_report_2.output,
        rules.plot_performance_2.output.plot,
        rules.plot_benchmarks_2.output.plot
    shell:
        '''
        rm -rf {input}
        '''

rule preprocess_data3:
    input:
        R="code/preproc.R",
        csv=config['dataset3']
    output:
        rds='data/dat_proc3.Rds'
    log:
        "log/preprocess_data3.txt"
    benchmark:
        "benchmarks/preprocess_data3.txt"
    resources:
        ncores=ncores
    script:
        "code/preproc.R"

rule run_ml_3:
    input:
        R="code/ml.R",
        rds=rules.preprocess_data3.output.rds
    output:
        model="results/runs/dataset3/{method}_{seed}_model.Rds",
        perf=temp("results/runs/dataset3/{method}_{seed}_performance.csv"),
        feat=temp("results/runs/dataset3/{method}_{seed}_feature-importance.csv")
    log:
        "log/runs/dataset3/run_ml.{method}_{seed}.txt"
    benchmark:
        "benchmarks/runs/dataset3/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=config['outcome_colname'],
        method="{method}",
        seed="{seed}",
        kfold=kfold
    resources:
        ncores=ncores
    script:
        "code/ml.R"

rule combine_results_3:
    input:
        R="code/combine_results.R",
        csv=expand("results/runs/dataset3/{method}_{seed}_{{type}}.csv", method = ml_methods, seed = seeds)
    output:
        csv='results/dataset3/{type}_results.csv'
    log:
        "log/dataset3/combine_results_{type}.txt"
    benchmark:
        "benchmarks/dataset3/combine_results_{type}.txt"
    script:
        "code/combine_results.R"

rule combine_benchmarks_3:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml_3.benchmark, method = ml_methods, seed = seeds)
    output:
        csv='results/dataset3/benchmarks_results.csv'
    log:
        'log/dataset3/combine_benchmarks.txt'
    script:
        'code/combine_benchmarks.R'

rule plot_performance_3:
    input:
        R="code/plot_perf.R",
        csv='results/dataset3/performance_results.csv'
    output:
        plot='figures/performance_dataset3.png'
    log:
        "log/plot_performance_dataset3.txt"
    script:
        "code/plot_perf.R"

rule plot_benchmarks_3:
    input:
        R='code/plot_benchmarks.R',
        csv=rules.combine_benchmarks_3.output.csv
    output:
        plot='figures/benchmarks_dataset3.png'
    log:
        'log/plot_benchmarks_dataset3.txt'
    script:
        'code/plot_benchmarks.R'

rule render_report_3:
    input:
        Rmd='report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance_3.output.plot,
        bench_plot=rules.plot_benchmarks_3.output.plot
    output:
        doc='report_dataset3.md'
    log:
        "log/render_report_dataset3.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'code/render.R'

rule clean_3:
    input:
        rules.render_report_3.output,
        rules.plot_performance_3.output.plot,
        rules.plot_benchmarks_3.output.plot
    shell:
        '''
        rm -rf {input}
        '''
