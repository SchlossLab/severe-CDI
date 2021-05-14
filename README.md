
## Repository where we started to look at bacterial features associated with adverse CDI outcomes. 

YOUR PAPER'S ABSTRACT GOES HERE
Note: Initial analysis used IDSA severe CDI definition to group cases into not severe and IDSA severe categories.

### Overview

	project
	|- README          # the top level description of content (this doc)
	|- CONTRIBUTING    # instructions for how to contribute to your project
	|- LICENSE         # the license for this project
	|
	|- submission/
	| |- manuscript.Rmd    # executable Rmarkdown for this manuscript
	| |- manuscript.md     # Markdown (GitHub) version of the *.Rmd file
	| |- manuscript.tex    # TeX version of *.Rmd file
	| |- manuscript.pdf    # PDF version of *.Rmd file
	| |- header.tex   # LaTeX header file to format pdf version of manuscript
	| |- references.bib # BibTeX formatted references
	| |- XXXX.csl     # csl file to format references for journal XXX
	|
	|- data           # raw and primary data, are not changed once created
	| |- references/  # reference files to be used in analysis
	| |- raw/         # raw data, will not be altered
	| |- mothur/      # mothur processed data
	| +- process/     # cleaned data, will not be altered once created;
	|                 # will be committed to repo
	|
	|- code/          # any programmatic code
	|
	|- results        # all output from workflows and analyses
	| |- tables/      # text version of tables to be rendered with kable in R
	| |- figures/     # graphs, likely designated for manuscript figures
	| +- pictures/    # diagrams, images, and other non-graph graphics
	|
	|- exploratory/   # exploratory data analysis for study
	| |- notebook/    # preliminary analyses
	| +- scratch/     # temporary files that can be safely deleted or lost
	|
	+- Makefile       # executable Makefile for this study, if applicable


### How to regenerate this repository

#### Dependencies and locations
* Gnu Make should be located in the user's PATH
* mothur (v1.43.0) should be located in the user's PATH
* FFmpeg should be located in the user's PATH
* R (v. 4.0.2) should be located in the user's PATH
* R packages:
    * broom v0.7.0
    * tidyverse_1.3.0
    * cowplot v1.0.0
    * vegan v2.5-6
    * knitr v1.29
    * rmarkdown v2.3
    * ggpubr v.0.4.0
    * gganimate v1.0.6
    * readxl v1.3.1
    * glue v1.4.1
    * ggtext v0.1.0
	 * magick v2.6.0
	 * here 1.0.1
* Analysis assumes the use of 10 processors

#### Running analysis

Download 16S rRNA sequencing dataset from the NCBI Sequence Read Archive (BioProject Accession no. PRJN_______).
```
git clone https://github.com/SchlossLab/XXXX_adverse_CDIs
```

Transfer 16S rRNA sequencing fastq.gz files into XXXX_adverse_CDIs/data/raw
```
cd XXXX_adverse_CDIs
```

Classify CDI case samples into severe and not severe categories based on IDSA severity criteria.
```
Rscript code/severity_analysis.R
```

Obtain the SILVA reference alignment from version 132 described at https://mothur.org/blog/2018/SILVA-v132-reference-files/. We will use the SEED v. 132, which contain 12,083 bacterial sequences. This also contains the reference taxonomy. We will limit the databases to only include bacterial sequences.
```
wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v132.tgz
tar xvzf Silva.seed_v132.tgz silva.seed_v132.align silva.seed_v132.tax
mothur "#get.lineage(fasta=silva.seed_v132.align, taxonomy=silva.seed_v132.tax, taxon=Bacteria);degap.seqs(fasta=silva.seed_v132.pick.align, processors=8)"
mv silva.seed_v132.pick.align data/references/silva.seed.align
rm Silva.seed_v132.tgz silva.seed_v132.*
#Narrow to v4 region
mothur "#pcr.seqs(fasta=data/references/silva.seed.align, start=11894, end=25319, keepdots=F, processors=8)"
mv data/references/silva.seed.pcr.align data/references/silva.v4.align
```
Obtain the RDP reference taxonomy. The current version is v11.5 and we use a "special" pds version of the database files, which are described at https://mothur.org/blog/2017/RDP-v16-reference_files/.
```
wget -N https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset16_022016.pds.tgz
tar xvzf Trainset16_022016.pds.tgz trainset16_022016.pds
mv trainset16_022016.pds/* data/references/
rm -rf trainset16_022016.pds
rm Trainset16_022016.pds.tgz
```
Obtain the Zymo mock community data; note that Zymo named the 5 operon of Salmonella twice instead of the 7 operon.
```
wget -N https://s3.amazonaws.com/zymo-files/BioPool/ZymoBIOMICS.STD.refseq.v2.zip
unzip ZymoBIOMICS.STD.refseq.v2.zip
rm ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*itochondria_ssrRNA.fasta #V4 primers don't come close to annealing to these
cat ZymoBIOMICS.STD.refseq.v2/ssrRNAs/*fasta > zymo_temp.fasta
sed '0,/Salmonella_enterica_16S_5/{s/Salmonella_enterica_16S_5/Salmonella_enterica_16S_7/}' zymo_temp.fasta > zymo.fasta
mothur "#align.seqs(fasta=zymo.fasta, reference=data/references/silva.v4.align, processors=12)"
mv zymo.align data/references/zymo_mock.align
rm -rf zymo* ZymoBIOMICS.STD.refseq.v2* zymo_temp.fasta
```

Starting with the shared and metadata files from Tomkovich_CDI_clinical_samples, which were generated as described below.

Generate a shared file and a cons.taxonomy file for the final set of sequencing files. Calculate the overall error rate by comparing Mock control sequences to the Mock reference community from Zymo.
```
bash code/get_good_seqs_shared_otus.batch
bash code/get_error.batch

```
Script to read in shared_file
```
Rscript code/shared_file.R
```
Subsample shared file to 5000 sequences.
```
bash code/alpha_beta.batch
```
Examine potential *C. difficile* sequences in the dataset.
```
bash code/get_oturep.batch
Rscript code/blast_otus.R

#To run get_oturep.batch on HPC:
sbatch code/slurm/get_oturep.sh
```
Visualize alpha diversity in R.
```
Rscript code/diversity_data.R
```
Create input files for lefse analysis using mothur. Run lefse analysis in mothur. Visualize lefse results in R.
```
Rscript code/lefse_prep_files.R
bash code/lefse.batch
Rscript code/lefse_analysis.R
```
Prepare OTU, genus, and lefse input data for mikropml pipeline. Remove the OTU with most abundant *C. difficile* sequences from the imput data.
```
Rscript code/mikropml_input_data.R
```
Run mikropml pipeline on the input data using snakemake and an HPC.
Note: need to modify snakemake file to account for multiple types of input data. Currently set up to run one type of input data table at a time. Once finished, combine feature importance results.
Tip: snakemake -n (Dry run). Snakemake --unlock (If you get an error that the directory is locked)
```
sbatch code/ml_submit_slurm.sh
sbatch code/combine_feat_imp.sh.
```
Examine feature importance for best performing model (random forest) after running mikropml pipeline.
```
Rscript code/ml_feature_importance.R
```
Visualize bacterial relative abundances in R.
```
Rscript code/read_taxa_data.R
Rscript code/taxa.R
```
Create IDSA severity analysis summary figure.
```
Rscript code/idsa_analysis_summary.R
```

Generate the paper.
```
open submission/manuscript.Rmd and knit to Word or PDF document.
```