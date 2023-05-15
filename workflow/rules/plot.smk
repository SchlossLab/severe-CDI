
rule mermaid_flowchart:
    input:
        mmd='workflow/scripts/mermaid/severity_flowchart.mmd',
        css='workflow/scripts/mermaid/mermaid.css', # https://github.com/mermaidjs/mermaid.cli/issues/3
        cfg='workflow/scripts/mermaid/config.json' # https://github.com/madskristensen/MarkdownEditor/issues/92
    output:
        img='figures/severity_flowchart.svg'
    shell:
        """
        # npm install -g @mermaid-js/mermaid-cli
        mmdc \
            -i {input.mmd} \
            -o {output.img} \
            -cssFile {input.css} \
            --configFile {input.cfg}
        """

rule svg2tiff:
    input:
        svg='figures/severity_flowchart.svg'
    output:
        tiff='figures/severity_flowchart.tiff'
    conda: '../envs/graphviz.yml'
    shell:
        """
        convert {input.svg} -density 600 -resize 1600x1200 {output.tiff}
        """

rule plot_flowchart_sankey:
    input:
        flowchart='figures/severity_flowchart.tiff',
        #metadat='data/process/cases_full_metadata.csv'
    output:
        tiff='figures/flowchart_sankey.tiff'
    conda:
        "../envs/mikropml.yml"
    script:
        '../scripts/plot_flowchart_sankey.R'

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
        csv="results/performance_results_aggregated.csv"
    output:
        png="figures/plot_perf.png"
    log: "log/plot_perf.txt"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/plot_perf.R"

rule plot_feat_imp:
    input:
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
        rules.plot_flowchart_sankey.output
