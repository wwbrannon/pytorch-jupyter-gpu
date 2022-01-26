ARG IMAGE_VERSION=11.3.0-cudnn8-devel-ubuntu20.04
ARG LOCALE=en_US.UTF-8

ARG TORCH_URL=https://download.pytorch.org/whl/cu113/torch_stable.html
ARG TORCH_VERSION=1.10.0+cu113
ARG TV_VERSION=0.11.2+cu113
ARG TA_VERSION=0.10.1+cu113
ARG TT_VERSION=0.11.0
ARG PYG_VERSION=1.10.0+cu113

FROM nvidia/cuda:${IMAGE_VERSION}
USER root

#
# Install system software
#

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update # && apt-get -y dist-upgrade
RUN apt-get install -y --no-install-recommends \
    ca-certificates apt-transport-https apt-utils curl lsb-release \
    software-properties-common

RUN curl https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB | apt-key add -
RUN apt-add-repository "deb https://apt.repos.intel.com/mkl all main"

RUN apt-get install -y --no-install-recommends \
    "$(: Kerberos support for bigdisk fs)" \
    krb5-user kstart \
    \
    "$(: Development tools)" \
    build-essential gfortran binutils cmake \
    autoconf automake m4 bison flex gdb libtool \
    jq pkg-config shellcheck ctags \
    bzip2 gzip zip unzip \
    git git-lfs subversion \
    curl wget \
    vim nano \
    screen less \
    openssh-client ssh-askpass \
    \
    "$(: apt utils)" \
    gnupg apt-utils lsb-release \
    \
    "$(: Python basics)" \
    python3 pip pipenv \
    \
    "$(: Database tools)" \
    sqlite3 unixodbc unixodbc-dev odbc-postgresql pgtop \
    postgresql-client mysql-client libpq-dev \
    \
    "$(: Torch deps)" \
    intel-mkl libjpeg-dev libpng-dev openmpi-bin \
    \
    "$(: Misc Jupyter dependencies including tex)" \
    sudo locales tzdata fonts-liberation fonts-dejavu inkscape ffmpeg \
    libsm6 libxext-dev libxrender1 lmodern netcat pandoc python-dev \
    texlive-fonts-extra texlive-fonts-recommended texlive-xetex \
    texlive-generic-recommended texlive-latex-base texlive-latex-extra

RUN rm -rf /var/lib/apt/lists/*

#
# Install packages
#
# This is systemwide for simplicity, can use venv for particular projects
# if needed
#

RUN pip install -f ${TORCH_URL} \
                torch=${TORCH_VERSION} torchaudio=${TA_VERSION} \
                torchvision=${TV_VERSION} torchtext=${TT_VERSION}

RUN pip install \
    numpy pandas numexpr pandasql \
    scipy scikit-learn statsmodels scikit-image patsy networkx nltk spacy \
    jinja2 tqdm pyyaml requests unidecode python-louvain \
    graphviz pydot matplotlib seaborn \
    \
    sqlalchemy psycopg2 \
    \
    transformers datasets sentencepiece emoji \
    torchviz torchsummary captum tensorboard \
    pytorch-lightning pytorch-lightning-bolts skorch

RUN pip install -f https://data.pyg.org/whl/torch-${PYG_VERSION}.html \
                torch-scatter torch-sparse torch-cluster torch-spline-conv \
                torch-geometric

#
# Install jupyter
#

RUN python3 -m venv /opt/jupyter
RUN /opt/jupyter/pip install \
    notebook jupyter jupyterhub jupyterlab nbconvert nbformat ipywidgets \
    jupyterlab-git

#
# Configuration
#

RUN echo "${LOCALE} UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL=$LOCALE \
    LANG=$LOCALE \
    LANGUAGE=$LOCALE \
    SHELL=/bin/bash \
    PATH=/opt/conda/bin:$PATH

RUN mkdir -p /etc/jupyter/
COPY jupyterhub_config.py /etc/jupyter/

COPY start.sh /usr/local/bin/
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod ugo+x /usr/local/bin/fix-permissions

#
# Finalize
#

EXPOSE 8000

# expected to be run with --init
# ENTRYPOINT ["tini", "-g", "--"]

CMD ["start.sh"]
