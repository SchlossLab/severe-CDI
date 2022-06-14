
rule plot_complex_upset:
    input:
        csv='data/process/cases_{dataset}_metadata.csv'
    output:
        png='figures/complex-upset_plot_{dataset}.png'
    conda:
        'envs/complex-upset.yml'
    script:
        '../scripts/plot_complex_upset.R'

rule plot_diversity:
    input:
        "workflow/scripts/plot_diversity.R",
        "workflow/scripts/utilities.R",
        "data/mothur/cdi.opti_mcc.groups.ave-std.summary",
        'data/process/cases_full_metadata.csv'
    output:
        inv_simpson="figures/alpha_inv-simpson.png",
        richness="figures/alpha_richness.png"
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
    script:
        "../scripts/taxa.R"

rule plot_idsa_analysis_summary:
    input:
        "workflow/scripts/idsa_analysis_summary.R",
        "workflow/scripts/utilities.R",
        "results/figures/idsa_severe_n.png",
        rules.plot_diversity_data.output.inv_simpson,
        "results/figures/ml_performance_idsa_otu.png",
        "results/figures/ml_performance_idsa_otu_AUC.png",
        rules.plot_ml_feature_importance.output.isda_severity_png,
        rules.plot_taxa.output.severe_otus
    output:
        severe_isda_summary="results/figures/severe_idsa_summary.pdf"
    script:
        "../scripts/idsa_analysis_summary.R"

rule plot_perf:
    input:
        R="workflow/scripts/plot_perf.R",
        csv="results/performance_results_aggregated.csv"
    output:
        png="figures/plot_perf.png"
    log: "log/plot_perf.txt"
    script:
        "../scripts/plot_perf.R"

rule plot_feat_imp:
    input:
        R="workflow/scripts/plot_feat_imp.R",
        csv="results/feature-importance_results_aggregated.csv"
    output:
        png="figures/plot_feat_imp.png"
    log: "log/plot_feat_imp.txt"
    script:
        "../scripts/plot_feat_imp.R"
