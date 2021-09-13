
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