FROM condaforge/mambaforge:latest
LABEL io.github.snakemake.containerized="true"
LABEL io.github.snakemake.conda_env_hash="11d16f60d678805b6579433210c0c51000facbb7566a241f1b913aa32cf13940"

# Step 1: Retrieve conda environments

# Conda environment:
#   source: workflow/envs/mikropml.yml
#   prefix: /conda-envs/6ff87ff01b88a68c415c2b2075c74202
#   name: mikropml
#   channels:
#     - conda-forge
#     - r
#   dependencies:
#     - r-base=4
#     - r-cowplot
#     - r-devtools
#     - r-doFuture
#     - r-foreach
#     - r-future
#     - r-future.apply
#     - r-here
#     - r-mikropml=1.4.0
#     - r-rmarkdown
#     - r-rpart
#     - r-schtools>=0.3
#     - r-testthat
#     - r-tidyverse>=1.3
RUN mkdir -p /conda-envs/6ff87ff01b88a68c415c2b2075c74202
COPY workflow/envs/mikropml.yml /conda-envs/6ff87ff01b88a68c415c2b2075c74202/environment.yaml

# Conda environment:
#   source: workflow/envs/mothur.yml
#   prefix: /conda-envs/dc449269669867553feb137ee915a8a4
#   name: mothur
#   channels:
#     - bioconda
#     - defaults
#   dependencies:
#     - mothur=1.46
RUN mkdir -p /conda-envs/dc449269669867553feb137ee915a8a4
COPY workflow/envs/mothur.yml /conda-envs/dc449269669867553feb137ee915a8a4/environment.yaml

# Step 2: Generate conda environments

RUN mamba env create --prefix /conda-envs/6ff87ff01b88a68c415c2b2075c74202 --file /conda-envs/6ff87ff01b88a68c415c2b2075c74202/environment.yaml && \
    mamba env create --prefix /conda-envs/dc449269669867553feb137ee915a8a4 --file /conda-envs/dc449269669867553feb137ee915a8a4/environment.yaml && \
    mamba clean --all -y
