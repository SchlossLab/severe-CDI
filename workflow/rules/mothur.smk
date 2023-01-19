with open(f"data/SRR_Acc_List.txt", 'r') as file:
    sra_list = [line.strip() for line in file]

# rule download_silva:
#     output:
#         fasta='data/references/silva.seed_v132.align',
#         tax='data/references/silva.seed_v132.tax'
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         source /etc/profile.d/http_proxy.sh
#         wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v132.tgz
#         tar xvzf silva.seed_v132.tgz silva.seed_v132.align silva.seed_v132.tax
#         mv silva.* data/references/
#         """

# rule get_silva:
#     input:
#         fasta=rules.download_silva.output.fasta,
#         tax=rules.download_silva.output.tax
#     output:
#         full='data/references/silva.seed.align',
#         v4='data/references/silva.v4.align'
#     log:
#         "log/mothur/get_silva.log"
#     threads: 8
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         mothur "#set.logfile(name={log});
#                 set.dir(output=data/references/, input=data/references/);
#                 get.lineage(fasta={input.fasta}, taxonomy={input.tax}, taxon=Bacteria);
#                 degap.seqs(fasta=silva.seed_v132.pick.align, processors={threads})
#                 "
#         mv data/references/silva.seed_v132.pick.align {output.full}

#         mothur "#set.logfile(name={log});
#                 set.dir(output=data/references/);
#                 pcr.seqs(fasta={output.full}, start=11894, end=25319, keepdots=F, processors={threads})"
#         mv data/references/silva.seed.pcr.align {output.v4}
#         """

# rule get_rdp:
#     output:
#         reference='data/references/trainset16_022016.pds.fasta',
# 	    taxonomy='data/references/trainset16_022016.pds.tax'
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         source /etc/profile.d/http_proxy.sh
#         wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset16_022016.pds.tgz
#         tar xvzf trainset16_022016.pds.tgz trainset16_022016.pds
#         mv trainset16_022016.pds/* data/references/
#         rm -rf trainset16_022016.pds
#         rm trainset16_022016.pds.tgz
#         """

# rule get_zymo:
#     input:
#         silva_v4=rules.get_silva.output.v4
#     output:
#         align='data/references/zymo_mock.align'
#     log:
#         "log/mothur/get_zymo.log"
#     threads: 12
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         source /etc/profile.d/http_proxy.sh
#         wget -N https://s3.amazonaws.com/zymo-files/BioPool/ZymoBIOMICS.STD.refseq.v2.zip
#         unzip ZymoBIOMICS.STD.refseq.v2.zip
#         rm ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*itochondria_ssrRNA.fasta #V4 primers don't come close to annealing to these
#         cat ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*fasta > zymo_temp.fasta
#         sed '0,/Salmonella_enterica_16S_5/{{s/Salmonella_enterica_16S_5/Salmonella_enterica_16S_7/}}' zymo_temp.fasta > zymo.fasta
#         mothur "#set.logfile(name={log});
#         align.seqs(fasta=zymo.fasta, reference={input.silva_v4}, processors={threads})"
#         mv zymo.align {output.align}
#         rm -rf zymo* ZymoBIOMICS.STD.refseq.v2* zymo_temp.fasta
#         """

# rule download_sra:
#     input:
#         list="data/SRR_Acc_List.txt"
#     output:
#         fastq=expand("data/raw/{{SRA}}_{i}.fastq.gz", i=(1,2))
#     params:
#         sra="{SRA}",
#         outdir="data/raw/"
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
#         sra={params.sra}
#         outdir={params.outdir}

#         prefetch $sra
#         fasterq-dump --split-files $sra -O $outdir
#         gzip ${{outdir}}/${{sra}}_*.fastq
#         """


# rule process_samples:
#     input:
#         fastq=[f"data/raw/{sra}_{i}.fastq.gz" for sra in sra_list for i in (1,2)],
#         silva=rules.get_silva.output.v4,
#         reference=rules.get_rdp.output.reference,
# 	    taxonomy=rules.get_rdp.output.taxonomy,
#         zymo=rules.get_zymo.output
#     output:
#         fasta="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta",
#         taxonomy="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.taxonomy",
#         count_table="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count_table"
#     log:
#         "log/mothur/process_samples.log"
#     params:
#         inputdir='data/raw',
#         outputdir='data/mothur'
#     threads: 10
#     resources:
#         mem_mb=8000
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         mothur "#
#             set.logfile(name={log});
#             make.file(inputdir={params.inputdir}, type=gz, prefix=cdi);
#             make.contigs(file=cdi.files, inputdir={params.inputdir}, outputdir={params.outputdir}, processors={threads});
#             summary.seqs(fasta=cdi.trim.contigs.fasta, processors={threads});
#             screen.seqs(fasta=current, group=current, maxambig=0, maxlength=275, maxhomop=8, processors={threads});
#             unique.seqs(fasta=current);
#             count.seqs(name=current, group=current);
#             summary.seqs(count=cdi.trim.contigs.good.count_table, processors={threads});
#             align.seqs(fasta=current, reference={input.silva}, processors={threads});
#             screen.seqs(fasta=current, count=current, start=1968, end=11550, processors={threads});
#             summary.seqs(fasta=current, count=current, processors={threads});
#             filter.seqs(fasta=current, vertical=T, trump=., processors={threads});
#             unique.seqs(fasta=current, count=current);
#             pre.cluster(fasta=current, count=current, diffs=2, processors={threads});
#             chimera.vsearch(fasta=current, count=current, dereplicate=T, processors={threads});
#             remove.seqs(fasta=current, accnos=current);
#             summary.seqs(fasta=current, count=current, processors={threads});
#             classify.seqs(fasta=current, count=current, reference={input.reference}, taxonomy={input.taxonomy}, cutoff=80);
#             remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota);
#             count.seqs(name=current, group=current)
#         "
#         """


# rule cluster_otus:
#     input:
#         fasta=rules.process_samples.output.fasta,
#         taxonomy=rules.process_samples.output.taxonomy,
#         count_table=rules.process_samples.output.count_table
#     output:
#         shared="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.shared",
#         taxonomy="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.0.03.cons.taxonomy"
#     threads: 10
#     params:
#         inputdir='data/mothur',
#         outputdir='data/mothur'
#     resources:
#         mem_mb=MEM_PER_GB*16
#     conda: "../envs/mothur.yml"
#     shell:
#         """
#         mothur "#
#             set.dir(input=data/mothur, output=data/mothur, seed=19760620);
#             set.current(processors={threads});
#             cluster.split(fasta={input.fasta}, count={input.count_table}, taxonomy={input.taxonomy}, cutoff=0.03, taxlevel=4, processors={threads});
#             count.groups(count=current);
#             make.shared(list=current, count=current, label=0.03);
#             classify.otu(list=current, count=current, taxonomy=current, label=0.03)
#             "
#         """

rule alpha_beta:
    input:
        taxonomy="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.0.03.cons.taxonomy",
        shared="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.shared"
    output:
        shared="data/mothur/cdi.opti_mcc.shared",
        taxonomy="data/mothur/cdi.taxonomy",
        summary="data/mothur/cdi.opti_mcc.groups.ave-std.summary",
        rarefaction="data/mothur/cdi.opti_mcc.groups.rarefaction",
        subsample_shared="data/mothur/cdi.opti_mcc.0.03.subsample.shared",
        dist_shared = "data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist",
        nmds = "data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist.nmds",
        pcoa = "data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist.pcoa"
    log:
        "log/mothur/alpha_beta.log"
    conda:
        "../envs/mothur.yml"
    shell:
        """
        mothur "#set.logfile(name={log});
        set.dir(input=data/mothur, output=data/mothur, seed=19760620);
        rename.file(taxonomy={input.taxonomy}, shared={input.shared});
        sub.sample(shared=cdi.opti_mcc.shared, size=5000);
        rarefaction.single(shared=cdi.opti_mcc.shared, calc=sobs, freq=100);
        summary.single(shared=cdi.opti_mcc.shared, calc=nseqs-coverage-invsimpson-shannon-sobs, subsample=5000);
        dist.shared(shared=cdi.opti_mcc.shared, calc=braycurtis, subsample=5000, processors=10);
        nmds(phylip=cdi.opti_mcc.braycurtis.0.03.lt.ave.dist);
        pcoa(phylip=cdi.opti_mcc.braycurtis.0.03.lt.ave.dist);
        "
        """

rule get_genus_level:
    input:
        shared="data/mothur/cdi.opti_mcc.shared",
        taxonomy="data/mothur/cdi.taxonomy"
    output:
        shared="data/mothur/cdi.opti_mcc.genus.shared",
        taxonomy="data/mothur/cdi.genus.taxonomy"
    log:
        "log/mothur/get_genus_level.log"
    conda: "../envs/mikropml.yml"
    resources:
        mem_mb=MEM_PER_GB*8
    script:
        "../scripts/get_genus_level.R"

rule get_oturep:
    input:
        list="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.list",
        fasta="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.fasta",
        phylip="data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist",
        count_table="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table"
    log:
        "log/mothur/get_oturep.log"
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur: "#set.logfile(name={log});
        set.dir(input=data/mothur, output=data/mothur, seed=19760620);
        get.otulist( list={input.list}, label=0.03);
        bin.seqs(list ={input.list}, fasta={input.fasta});
        get.oturep(phylip={input.phylip}, count={input.count_table},  list={input.list}, fasta=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.fasta)
        "
        """


rule blast_otus:
    input:
        "workflow/scripts/blast_otus.R",
        "workflow/scripts/utilities.R",
        "data/mothur/cdi.taxonomy",
        "data/process/59OTus_vs_C.diff_ATCC9689-Alignment-HitTable.csv",
        "data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.list",
        'data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.fasta',
        "data/process/c_diff_seqs_vs_C.diff_ATCC9689-Alignment-HitTable.csv",
        "data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table"
    output:
        blast="results/figures/otus_peptostreptococcaceae_blast_results.png",
        unique_seqs="data/mothur/c_diff_unique_seqs.fasta",
        top2="exploratory/notebook/top_2_otu41_seqs.png",
        top3_7="exploratory/notebook/top3-7_c_diff_seqs.png",
        top2_sample="exploratory/notebook/top_2_otu41_seqs_sample.png",
        top3_7_sample="exploratory/notebook/top3-7_c_diff_seqs_sample.png",
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/blast_otus.R"

rule lefse_prep_files:
    input:
        "workflow/scripts/lefse_prep_files.R",
        "workflow/scripts/utilities.R",
        "data/process/case_idsa_severity.csv",
        "data/mothur/cdi.opti_mcc.0.03.subsample.shared"
    output:
        shared="data/process/idsa.shared",
        design="data/process/idsa.design"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/lefse_prep_files.R"

rule lefse:
    input:
        rules.lefse_prep_files.output
    output:
        lefse_summary="data/process/idsa.0.03.lefse_summary"
    log:
        "log/mothur/lefse.log"
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur: "#set.logfile(name={log});
        set.dir(input=data/process, output=data/process, seed=19760620);
        lefse(shared = {input.shared}, design={input.design})
        "
        """

rule lefse_analysis:
    input:
        "workflow/scripts/lefse_analysis.R",
        "workflow/scripts/utilities.R",
        rules.lefse.output,
        'data/mothur/cdi.taxonomy'
    output:
        lefse_plot="results/figures/idsa_lefse_plot.png",
        lefse_results="data/process/idsa_lefse_results.csv"
    conda: "../envs/mikropml.yml"
    script:
        "../scripts/lefse_analysis.R"

