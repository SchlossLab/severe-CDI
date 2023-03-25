
rule plot_complex_upset:
    input:
        csv='data/process/cases_{dataset}_metadata.csv'
    output:
        png='figures/complex-upset_plot_{dataset}.png'
    conda:
        '../envs/complex-upset.yml'
    script:
        '../scripts/plot_complex_upset.R'

rule plot_diversity:
    input:
        R="workflow/scripts/plot_diversity.R",
        div="data/mothur/cdi.opti_mcc.groups.ave-std.summary",
        meta="data/process/cases_int_metadata.csv",
        nmds='data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.axes',
        metadata="data/process/cases_full_metadata.csv"
    output:
        alpha="figures/alpha_div.png",
        beta="figures/beta_div.png",
        combined="figures/alpha_and_beta_div.png"
    conda: "../envs/mikropml.yml"
    script:
        '../scripts/plot_diversity.R'

rule plot_taxa:
    input:
        "workflow/scripts/plot_taxa.R",
        "workflow/scripts/utilities.R",
        "workflow/scripts/read_taxa_data.R",
        "data/process/case_idsa_severity.csv",
        "results/idsa_severity/combined_feature-importance_rf.csv"
    output:
        otus="results/figures/otus_peptostreptococcaceae.png",
        severe_otus="results/figures/feat_imp_idsa_severe_otus_abund.png"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/taxa.R"

rule plot_perf:
    input:
        R="workflow/scripts/plot_perf.R",
        csv="results/performance_results_aggregated.csv"
    output:
        png="figures/plot_perf.png"
    log: "log/plot_perf.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/plot_perf.R"

rule plot_feat_imp:
    input:
        R="workflow/scripts/plot_feat_imp.R",
        csv="results/feature-importance_results_aggregated.csv"
    output:
        png="figures/plot_feat_imp.png"
    log: "log/plot_feat_imp.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/plot_feat_imp.R"

rule make_plots:
    input:
        expand('figures/complex-upset_plot_{dataset}.png', dataset = datasets),
        rules.plot_diversity.output,
        rules.plot_taxa.output,
        rules.plot_perf.output,
        rules.plot_feat_imp.output,