with open(f"data/SRR_Acc_List.txt", 'r') as file:
    sra_list = [line.strip() for line in file]

rule get_silva:
    output:
        full='data/references/silva.seed.align',
        v4='data/references/silva.v4.align'
    shell:
        """
        wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v132.tgz
        tar xvzf Silva.seed_v132.tgz silva.seed_v132.align silva.seed_v132.tax

        mothur "#set.dir(output=data/references/);
                get.lineage(fasta=silva.seed_v132.align, taxonomy=silva.seed_v132.tax, taxon=Bacteria);
                degap.seqs(fasta=silva.seed_v132.pick.align, processors=8)"
        mv silva.seed_v132.pick.align data/references/silva.seed.align
        rm Silva.seed_v132.tgz silva.seed_v132.*

        mothur "#set.dir(output=data/references/);
                pcr.seqs(fasta=data/references/silva.seed.align, start=11894, end=25319, keepdots=F, processors=8)"
        mv data/references/silva.seed.pcr.align data/references/silva.v4.align
        """

rule get_rdp:
    output:
        directory('data/references/rdp/')
    shell:
        """
        wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset16_022016.pds.tgz
        tar xvzf Trainset16_022016.pds.tgz trainset16_022016.pds
        mv trainset16_022016.pds/* data/references/rdp/
        rm -rf trainset16_022016.pds
        rm Trainset16_022016.pds.tgz
        """

rule get_zymo:
    input:
        silva_v4=rules.get_silva.output.v4
    output:
        align='data/references/zymo_mock.align'
    resources:
        ncores=12
    shell:
        '''
        wget -N https://s3.amazonaws.com/zymo-files/BioPool/ZymoBIOMICS.STD.refseq.v2.zip
        unzip ZymoBIOMICS.STD.refseq.v2.zip
        rm ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*itochondria_ssrRNA.fasta #V4 primers don't come close to annealing to these
        cat ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*fasta > zymo_temp.fasta
        sed '0,/Salmonella_enterica_16S_5/{s/Salmonella_enterica_16S_5/Salmonella_enterica_16S_7/}' zymo_temp.fasta > zymo.fasta
        mothur "#align.seqs(fasta=zymo.fasta, reference={input.silva_v4}, processors={resources.ncores})"
        mv zymo.align {output.align}
        rm -rf zymo* ZymoBIOMICS.STD.refseq.v2* zymo_temp.fasta
        '''

rule download_most:
    input:
        list="data/SRR_Acc_List.txt"
    output:
        fastq=expand("data/raw/{{SRA}}_{i}.fastq.gz", i=(1,2))
    params:
        sra="{SRA}",
        outdir="data/raw/"
    shell:
        """
        source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
        sra={params.sra}
        outdir={params.outdir}

        prefetch $sra
        fasterq-dump --split-files $sra -O $outdir
        gzip ${{outdir}}/${{sra}}_*.fastq
        """


rule get_good_seqs_shared_otus:
    input:
        fastq=[f"data/raw/{sra}_{i}.fastq.gz" for sra in sra_list for i in (1,2)],
        silva=rules.get_silva.output.v4
    output:
        file="data/raw/cds.files"
    params:
        inputdir='data/raw',
        outputdir='data/mothur'
    shell:
        """
        mothur "#
            make.file(inputdir={params.inputdir}, type=gz, prefix=cdi)
            make.contigs(file=cdi.files, inputdir={params.inputdir}, outputdir={params.outputdir}, processors=10)
            summary.seqs(fasta=cdi.trim.contigs.fasta, processors=10)
            screen.seqs(fasta=current, group=current, maxambig=0, maxlength=275, maxhomop=8, processors=10)
            unique.seqs(fasta=current)
            count.seqs(name=current, group=current)
            summary.seqs(count=cdi.trim.contigs.good.count_table, processors=10)
            align.seqs(fasta=current, reference={input.silva}, processors=10)
            screen.seqs(fasta=current, count=current, start=1968, end=11550, processors=10)
            summary.seqs(fasta=current, count=current, processors=10)
            filter.seqs(fasta=current, vertical=T, trump=., processors=10)
            unique.seqs(fasta=current, count=current)
            pre.cluster(fasta=current, count=current, diffs=2, processors=10)
            chimera.vsearch(fasta=current, count=current, dereplicate=T, processors=10)
            remove.seqs(fasta=current, accnos=current)
            summary.seqs(fasta=current, count=current, processors=10)
            classify.seqs(fasta=current, count=current, reference=data/references/trainset16_022016.pds.fasta, taxonomy=data/references/trainset16_022016.pds.tax, cutoff=80)
            remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota)
            count.seqs(name=current, group=current)

            set.dir(input=data/mothur, output=data/mothur, seed=19760620)
            set.current(processors=10)
            remove.groups(count=cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count_table, fasta=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta, taxonomy=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.taxonomy, groups=mock10-mock11-mock12-mock13-mock14-mock15-mock16-mock17-mock18-mock19-mock20-mock21-mock22-mock23-mock24-mock25-mock26-mock28-mock30-mock32-mock33-mock34-mock35-mock36-mock37-mock38-mock39-mock40-mock41-mock42-mock43-mock44-mock45-mock46-mock47-mock48-mock51-mock51b-mock52-mock53-mock5-mock6-mock7-mock9)
            cluster.split(fasta=current, count=current, taxonomy=current, cutoff=0.03, taxlevel=4, processors=10)
            count.groups(count=current)
            make.shared(list=current, count=current, label=0.03)
            classify.otu(list=current, count=current, taxonomy=current, label=0.03)
            "
        """

# SET: Need to update to capture all the mocks for CDI samples (2-4 per library, named according to plate number). Currently set up to check error in resequencing library
rule get_error:
    input:
        rules.get_good_seqs_shared_otus.output
    shell:
        """
        mothur "#
        set.current(inputdir=data/plate53_mothur, outputdir=data/plate53_mothur, processors=8)
        get.groups(count=cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count_table, fasta=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta, taxonomy=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.taxonomy, groups=mock10-mock11-mock12-mock13-mock14-mock15-mock16-mock17-mock18-mock19-mock20-mock21-mock22-mock23-mock24-mock25-mock26-mock28-mock30-mock32-mock33-mock34-mock35-mock36-mock37-mock38-mock39-mock40-mock41-mock42-mock43-mock44-mock45-mock46-mock47-mock48-mock51-mock51b-mock52-mock53-mock5-mock6-mock7-mock9)
        seq.error(fasta=current, count=current, reference=data/references/zymo_mock.align, aligned=F)
        "
        """

rule alpha_beta:
    input:
        taxonomy="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.cons.taxonomy",
        shared="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.shared"
    shell:
        """
        mothur "#
        set.dir(input=data/mothur, output=data/mothur, seed=19760620)
        rename.file(taxonomy={input.taxonomy}, shared={input.shared})
        #sub.sample(shared=cdi.opti_mcc.shared, size=5000)
        #rarefaction.single(shared=cdi.opti_mcc.shared, calc=sobs, freq=100)
        #summary.single(shared=cdi.opti_mcc.shared, calc=nseqs-coverage-invsimpson-shannon-sobs, subsample=5000)
        "
        """

rule get_oturep:
    input:
        list="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.list",
        fasta="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.fasta",
        phylip="data/mothur/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist",
        count_table="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table"
    shell:
        """
        mothur: "#
        set.dir(input=data/mothur, output=data/mothur, seed=19760620)
        get.otulist( list={input.list}, label=0.03)
        bin.seqs(list ={input.list}, fasta={input.fasta})
        get.oturep(phylip={input.phylip}, count={input.count_table},  list={input.list}, fasta=cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.fasta)
        "
        """


rule blast_otus:
    input:
        "code/blast_otus.R",
        "code/utilities.R",
        "data/mothur/cdi.taxonomy",
        "data/process/59OTus_vs_C.diff_ATCC9689-Alignment-HitTable.csv",
        "data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.list",
        'data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.fasta',
        "data/process/c_diff_seqs_vs_C.diff_ATCC9689-Alignment-HitTable.csv",
        "data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.pick.count_table"
    output:
        plot="results/figures/otus_peptostreptococcaceae_blast_results.png",
        table="data/mothur/c_diff_unique_seqs.fasta",
        png1="exploratory/notebook/top_2_otu41_seqs.png",
        png2="exploratory/notebook/top3-7_c_diff_seqs.png",
        png3="exploratory/notebook/top_2_otu41_seqs_sample.png",
        png4="exploratory/notebook/top3-7_c_diff_seqs_sample.png",
    script:
        "code/blast_otus.R"

rule diversity_data:
    input:
        "code/diversity_data.R",
        "code/utilities.R",
        "data/mothur/cdi.opti_mcc.groups.ave-std.summary",
        "data/process/case_idsa_severity.csv"
    output:
        png1="results/figures/idsa_alpha_inv_simpson.png",
        png2="results/figures/idsa_alpha_richness.png"
    script:
        "code/diversity_data.R"

rule lefse_prep_files:
    input:
        "code/lefse_prep_files.R",
        "code/utilities.R",
        "data/process/case_idsa_severity.csv",
        "data/mothur/cdi.opti_mcc.0.03.subsample.shared"
    output:
        tsv1="data/process/idsa.shared",
        tsv2="data/process/idsa.design"
    script:
        "code/lefse_prep_files.R"

#what is the input or output for this one??
rule lefse:
    shell:
    """
    mothur: "#
    set.dir(input=data/process, output=data/process, seed=19760620)
    lefse(shared = idsa.shared, design=idsa.design)
    "
    """

    
rule lefse_analysis:
    input:
        "code/lefse_analysis.R",
        "code/utilities.R",
        "data/process/idsa.0.03.lefse_summary",
        'data/mothur/cdi.taxonomy'
    output:
        png="results/figures/idsa_lefse_plot.png",
        csv="data/process/idsa_lefse_results.csv"
    script:
        "code/lefse_analysis.R"

rule mikropml_input_data:
    input:
        "code/mikropml_input_data.R",
        "code/utilities.R",
        "data/mothur/cdi.opti_mcc.0.03.subsample.shared",
        "data/process/case_idsa_severity.csv"
    output:
        csv="data/process/ml_idsa_severity.csv"
    script:
        "code/mikropml_input_data.R"

    # input:
    #     r="code/shared_file.R"
    #     tsv="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.shared"
