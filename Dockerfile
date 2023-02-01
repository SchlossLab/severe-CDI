FROM condaforge/mambaforge:latest
LABEL io.github.snakemake.containerized="true"
LABEL io.github.snakemake.conda_env_hash="068ba1f953564d5ff1b55d2946529bff9219bf036e07ca7c1e398f5d33867ddc"

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
#   prefix: /conda-envs/0ce0073f1c2e0c894e2b808f7d978e7f
#   name: mothur
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - mothur=1.46
RUN mkdir -p /conda-envs/0ce0073f1c2e0c894e2b808f7d978e7f
COPY workflow/envs/mothur.yml /conda-envs/0ce0073f1c2e0c894e2b808f7d978e7f/environment.yaml

# Step 2: Generate conda environments

RUN mamba env create --prefix /conda-envs/6ff87ff01b88a68c415c2b2075c74202 --file /conda-envs/6ff87ff01b88a68c415c2b2075c74202/environment.yaml && \
    mamba env create --prefix /conda-envs/0ce0073f1c2e0c894e2b808f7d978e7f --file /conda-envs/0ce0073f1c2e0c894e2b808f7d978e7f/environment.yaml && \
    mamba clean --all -y
