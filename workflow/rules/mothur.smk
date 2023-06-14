rule download_silva:
    output:
        fasta='data/references/silva.seed_v132.align',
        tax='data/references/silva.seed_v132.tax'
    conda: "../envs/mothur.yml"
    shell:
        """
        source /etc/profile.d/http_proxy.sh
        wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v132.tgz
        tar xvzf silva.seed_v132.tgz silva.seed_v132.align silva.seed_v132.tax
        mv silva.* data/references/
        """

rule get_silva:
    input:
        fasta=rules.download_silva.output.fasta,
        tax=rules.download_silva.output.tax
    output:
        full='data/references/silva.seed.align',
        v4='data/references/silva.v4.align'
    log:
        "log/mothur/get_silva.log"
    threads: 8
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur "#set.logfile(name={log});
                set.dir(output=data/references/, input=data/references/);
                get.lineage(fasta={input.fasta}, taxonomy={input.tax}, taxon=Bacteria);
                degap.seqs(fasta=silva.seed_v132.pick.align, processors={threads})
                "
        mv data/references/silva.seed_v132.pick.align {output.full}

        mothur "#set.logfile(name={log});
                set.dir(output=data/references/);
                pcr.seqs(fasta={output.full}, start=11894, end=25319, keepdots=F, processors={threads})"
        mv data/references/silva.seed.pcr.align {output.v4}
        """

rule get_rdp:
    output:
        reference='data/references/trainset16_022016.pds.fasta',
	    taxonomy='data/references/trainset16_022016.pds.tax'
    conda: "../envs/mothur.yml"
    shell:
        """
        source /etc/profile.d/http_proxy.sh
        wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset16_022016.pds.tgz
        tar xvzf trainset16_022016.pds.tgz trainset16_022016.pds
        mv trainset16_022016.pds/* data/references/
        rm -rf trainset16_022016.pds
        rm trainset16_022016.pds.tgz
        """

rule get_zymo:
    input:
        silva_v4=rules.get_silva.output.v4
    output:
        align='data/references/zymo_mock.align'
    log:
        "log/mothur/get_zymo.log"
    threads: 12
    conda: "../envs/mothur.yml"
    shell:
        """
        source /etc/profile.d/http_proxy.sh
        wget -N https://s3.amazonaws.com/zymo-files/BioPool/ZymoBIOMICS.STD.refseq.v2.zip
        unzip ZymoBIOMICS.STD.refseq.v2.zip
        rm ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*itochondria_ssrRNA.fasta #V4 primers don't come close to annealing to these
        cat ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*fasta > zymo_temp.fasta
        sed '0,/Salmonella_enterica_16S_5/{{s/Salmonella_enterica_16S_5/Salmonella_enterica_16S_7/}}' zymo_temp.fasta > zymo.fasta
        mothur "#set.logfile(name={log});
        align.seqs(fasta=zymo.fasta, reference={input.silva_v4}, processors={threads})"
        mv zymo.align {output.align}
        rm -rf zymo* ZymoBIOMICS.STD.refseq.v2* zymo_temp.fasta
        """

checkpoint get_srr_list:
    input:
        csv='data/SraRunTable.csv'
    output:
        txt='data/SRR_Acc_List.txt'
    log: 'log/get_srr_list.log'
    conda:
        "../envs/mikropml.yml"
    script:
        '../scripts/get_srr_list.R'

rule download_sra:
    input:
        txt=rules.get_srr_list.output.txt
    output:
        fastq=expand("data/raw/{{SRA}}_{i}.fastq.gz", i=(1,2))
    params:
        sra="{SRA}",
        outdir="data/raw/"
    conda: "../envs/mothur.yml"
    shell:
        """
        source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
        sra={params.sra}
        outdir={params.outdir}

        prefetch $sra
        fasterq-dump --split-files $sra -O $outdir
        gzip ${{outdir}}/${{sra}}_*.fastq
        """

def list_fastq(wildcards):
    sra_file = checkpoints.get_srr_list.get(**wildcards).output.txt
    with open(sra_file, 'r') as file:
        sra_list = [line.strip() for line in file]
    return expand("data/raw/{sra}_{i}.fastq.gz", sra = sra_list, i = (1,2))

rule process_samples:
    input:
        fastq=list_fastq,
        srr=rules.get_srr_list.output.txt,
        silva=rules.get_silva.output.v4,
        reference=rules.get_rdp.output.reference,
	    taxonomy=rules.get_rdp.output.taxonomy
    output:
        fasta="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta",
        taxonomy="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.taxonomy",
        count_table="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.denovo.vsearch.pick.pick.count_table"
    log:
        "log/mothur/process_samples.log"
    params:
        inputdir='data/raw',
        outputdir='data/mothur'
    threads: 10
    resources:
        mem_mb=MEM_PER_GB*8
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur "#
            set.logfile(name={log});
            set.current(processors={threads});
            make.file(inputdir={params.inputdir}, type=gz, prefix=cdi);
            make.contigs(file=cdi.files, inputdir={params.inputdir}, outputdir={params.outputdir}, processors={threads});
            summary.seqs(fasta=cdi.trim.contigs.fasta, processors={threads});
            screen.seqs(fasta=current, group=current, maxambig=0, maxlength=275, maxhomop=8, processors={threads});
            unique.seqs(fasta=current);
            count.seqs(name=current, group=current);
            summary.seqs(count=cdi.trim.contigs.good.count_table, processors={threads});
            align.seqs(fasta=current, reference={input.silva}, processors={threads});
            screen.seqs(fasta=current, count=current, start=1968, end=11550, processors={threads});
            summary.seqs(fasta=current, count=current, processors={threads});
            filter.seqs(fasta=current, vertical=T, trump=., processors={threads});
            unique.seqs(fasta=current, count=current);
            pre.cluster(fasta=current, count=current, diffs=2, processors={threads});
            chimera.vsearch(fasta=current, count=current, dereplicate=T, processors={threads});
            remove.seqs(fasta=current, accnos=current);
            summary.seqs(fasta=current, count=current, processors={threads});
            classify.seqs(fasta=current, count=current, reference={input.reference}, taxonomy={input.taxonomy}, cutoff=80);
            remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota);
            count.seqs(name=current, group=current)
        "
        """

rule dist_seqs:
    input:
        fasta=rules.process_samples.output.fasta,
    output:
        dist="data/mothur/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.dist"
    log: 'log/dist_seqs.log'
    params:
        inputdir='data/mothur',
        outputdir='data/mothur'
    threads: 16
    resources:
        mem_mb=MEM_PER_GB*8
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur "#
            set.logfile(name={log});
            set.dir(input={params.inputdir}, output={params.outputdir});
            set.current(processors={threads});
            dist.seqs(fasta={input.fasta}, cutoff=0.03)
        "
        """

rule cluster_otus:
    input:
        taxonomy=rules.process_samples.output.taxonomy,
        count_table=rules.process_samples.output.count_table,
        dist=rules.dist_seqs.output.dist
    output:
        shared="data/mothur/cluster/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.shared",
        taxonomy="data/mothur/cluster/cdi.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.opti_mcc.0.03.cons.taxonomy"
    log: 'log/cluster_otus.log'
    params:
        inputdir='data/mothur/',
        outputdir='data/mothur/cluster/'
    threads: 10
    resources:
        mem_mb=MEM_PER_GB*1
    conda: "../envs/mothur.yml"
    shell:
        """
        mothur "#
            set.logfile(name={log});
            set.dir(input={params.inputdir}, output={params.outputdir}, seed=19760620);
            set.current(processors={threads});
            cluster(count={input.count_table}, column={input.dist}, cutoff=0.03);
            count.groups(count=current);
            make.shared(list=current, count=current, label=0.03);
            classify.otu(list=current, count=current, taxonomy={input.taxonomy}, label=0.03)
            "
        """

rule alpha_diversity:
    input:
        shared=rules.cluster_otus.output.shared,
        taxonomy=rules.cluster_otus.output.taxonomy,
    output:
        shared="data/mothur/alpha/cdi.opti_mcc.shared",
        taxonomy="data/mothur/alpha/cdi.taxonomy",
        summary="data/mothur/alpha/cdi.opti_mcc.groups.ave-std.summary",
        rarefaction="data/mothur/alpha/cdi.opti_mcc.groups.rarefaction",
        subsample_shared="data/mothur/alpha/cdi.opti_mcc.0.03.subsample.shared"
    log:
        "log/mothur/alpha_diversity.log"
    params:
        inputdir='data/mothur/cluster',
        outputdir='data/mothur/alpha'
    threads: 8
    resources:
        time="48:00:00",
        mem_mb=MEM_PER_GB*1
    conda:
        "../envs/mothur.yml"
    shell:
        """
        mothur "#set.logfile(name={log});
        set.dir(input={params.inputdir}, output={params.outputdir}, seed=19760620);
        set.current(processors={threads});
        rename.file(taxonomy={input.taxonomy}, shared={input.shared});
        sub.sample(shared=cdi.opti_mcc.shared, size=5000);
        rarefaction.single(shared=cdi.opti_mcc.shared, calc=sobs, freq=100);
        summary.single(shared=cdi.opti_mcc.shared, calc=nseqs-coverage-invsimpson-shannon-sobs, subsample=5000)
        "
        """

rule beta_diversity:
    input:
        shared=rules.alpha_diversity.output.shared
    output:
        dist_shared = "data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.dist"
    log:
        "log/mothur/beta_diversity.log"
    params:
        inputdir='data/mothur/alpha/',
        outputdir='data/mothur/beta/'
    threads: 10
    resources:
        time="48:00:00",
        mem_mb=int(MEM_PER_GB*1.5)
    conda:
        "../envs/mothur.yml"
    shell:
        """
        mothur "#set.logfile(name={log});
        set.dir(input={params.inputdir}, output={params.output_dir}, seed=19760620);
        dist.shared(shared={input.shared}, calc=braycurtis, subsample=5000, processors={threads})
        "
        """

rule nmds_pcoa:
    input:
        dist_shared=rules.beta_diversity.output.dist_shared
    output:
        nmds_iters="data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.iters",
        nmds_stress="data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.stress",
        nmds_axes="data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.axes",
        pcoa_axes="data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.axes",
        pcoa_loadings="data/mothur/beta/cdi.opti_mcc.braycurtis.0.03.lt.ave.pcoa.loadings"
    log:
        "log/mothur/nmds_pcoa.log"
    params:
        workdir='data/mothur/beta/'
    threads: 10
    resources:
        time="48:00:00"
    conda:
        "../envs/mothur.yml"
    shell:
        """
        mothur "#set.logfile(name={log});
        set.dir(input={params.workdir}, output={params.workdir}, seed=19760620);
        nmds(phylip={input.dist_shared});
        pcoa(phylip={input.dist_shared})
        "
        """
