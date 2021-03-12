
## TITLE OF YOUR PAPER GOES HERE

YOUR PAPER'S ABSTRACT GOES HERE




### Overview

	project
	|- README          # the top level description of content (this doc)
	|- CONTRIBUTING    # instructions for how to contribute to your project
	|- LICENSE         # the license for this project
	|
	|- submission/
	| |- study.Rmd    # executable Rmarkdown for this study, if applicable
	| |- study.md     # Markdown (GitHub) version of the *.Rmd file
	| |- study.tex    # TeX version of *.Rmd file
	| |- study.pdf    # PDF version of *.Rmd file
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
R (v. 4.0.2) should be located in the user's PATH
* R packages:
  * tidyverse_1.3.0
  * knitr v1.29
  * rmarkdown v2.3
* Analysis assumes the use of 10 processors


#### Running analysis
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

Record of commands used to copy raw data files from miseq_runs folder to my project's raw data folders.
```
copy_fastqs_to_data
```

Test of mothur v1.44 in schloss-lab/bin. I initially had errors and Pat helped figure out what the issue was.
```
test_fastqs_to_data
mothur code/test_get_good_seqs_shared_otus.batch
```

Initial analysis runs to determine number of sequences per sample:
```
mothur code/get_good_seqs_shared_otus.batch
Rscript code/seq_per_sample.R
```

Analysis of the 7 samples that were accidentally not transferred over from the MiSeq:
```
mothur code/missing_get_good_seqs_shared_otus.batch
```

Resequencing analysis runs to determine number of sequences per sample for library (repeat of the library since the 1st run had a MiSeq clustering error) and 2 individual plates of resequenced samples:
```
mothur code/reseq_get_good_seqs_shared_otus.batch
mothur code/reseq_repeat_get_good_seqs_shared_otus.batch
mothur code/plate52_get_good_seqs_shared_otus.batch
mothur code/plate53_get_good_seqs_shared_otus.batch
Rscript code/reseq_seq_per_sample.R
```

Test if it is feasible to combine sequences across different MiSeq runs
```
bash code/copy_fastqs_to_combine_test
mothur code/combine_test_get_good_seqs.batch
Rscript code/reseq_samples_compare_across_runs.R
```
After visualization of theta yc between runs, there was too much variation in theta yc distance for the same samples across runs. Since combining would only be relevant for a small subset of the samples (< 50), we decided to try resequencing these samples one last time (plate_53).

Finalize the pairs of sequencing files we will analyze for each sample (choose the run that yielded the most sequences out of all resequencing runs). Generate 16S sequencing preparation metadata file that tracks which microbiome aliquot was used, which plate and MiSeq library the sample was sequenced in, and which microbiome aliquot was used.
```
Rscript code/select_analysis_seqs.R
```
Also see lines 233 and onward from code/copy_fastqs_to_data for how files were transferred to data/raw.

Generate a shared file and a cons.taxonomy file for the final set of sequencing files. Calculate the overall error rate by comparing Mock control sequences to the Mock reference community from Zymo.
```
bash code/get_good_seqs_shared_otus.batch
bash code/get_error.batch

```
Script to read in shared_file
```
Rscript code/shared_file.R
```

Check for contaminated samples based on Notes column, which were notes entered during DNA extractions and library preparation. 2 samples were contaminated: KR01747 and KR0179. Remove these samples from all downstream analysis
```
Rscript code/utilities.R
```

Subsample shared file to 5000 sequences.
```
bash code/alpha_beta.batch
```

Create custom list of samples to paste into groups argument to generate distance matrix and ordinations with the 2 contaminated samples removed:
```
Rscript code/dist.shared_groups_list.R
```

Create distance file and ordinations
```
bash code/jsd_ordination.batch
bash code/braycurtis_ordination.batch
```

Create genus level files for community type analysis. Run get.communitytype() in mothur. Visualize results in R.
```
Rscript code/community_type_analysis.R
bash code/community_type.batch
Rscript code/community_type_analysis.R
```

Visualize alpha diversity and ordinations in R.
```
Rscript code/diversity_data.R
Rscript code/ordination_data.R
```
Create input files for lefse analysis using mothur. Run lefse analysis in mothur. Visualize lefse results in R.
```
Rscript code/lefse_prep_files.R
bash code/lefse.batch
Rscript code/lefse_analysis.R
```
Visualize bacterial relative abundances in R.
```
Rscript code/read_taxa_data.R
Rscript code/taxa.R
```

Prepare OTU, genus, and lefse input data for mikropml pipeline.
```
Rscript code/mikropml_input_data.R
Rscript code/mikropml_input_data_lefse.R
```

Run mikropl pipeline on all the different types of input data using snakemake and HPC
Note: need to modify snakemake file to account for multiple types of input data. Currently set up to run one type of input data table at a time. Once finished, combine feature importance results.
Tip: snakemake -n (Dry run). Snakemake --unlock (If you get an error that the directory is locked)
```
sbatch code/ml_submit_slurm.sh
sbatch code/combine_feat_imp.sh.
```

```
git clone https://github.com/SchlossLab/LastName_BriefDescription_Journal_Year.git
make write.paper
```
