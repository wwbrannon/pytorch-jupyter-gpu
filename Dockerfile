# or use something like nvidia/cuda:11.3.0-cudnn8-devel-ubuntu18.04 ?
ARG PYTORCH_VERSION=1.10.0-cuda11.3-cudnn8-runtime
ARG PYG_VERSION=1.10.0+cu113
ARG LOCALE=en_US.UTF-8

FROM pytorch/pytorch:${PYTORCH_VERSION}
USER root

#
# Configure repos, install updates
#

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates apt-transport-https apt-utils lsb-release \
    software-properties-common

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-add-repository "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main"

RUN apt-get update && apt-get -y dist-upgrade

#
# Install system software
#

RUN apt-get install -y --no-install-recommends \
    "$(: Kerberos support for bigdisk fs)" \
    krb5-user kstart \
    \
    "$(: Development tools)" \
    build-essential gfortran binutils \
    autoconf automake m4 bison flex gdb libtool \
    jq pkg-config shellcheck ctags \
    bzip2 gzip zip unzip \
    git subversion \
    curl wget \
    vim nano \
    screen less \
    openssh-client ssh-askpass \
    \
    "$(: Database tools)" \
    sqlite3 unixodbc unixodbc-dev odbc-postgresql pgtop \
    postgresql-client mysql-client libpq-dev \
    \
    "$(: Misc Jupyter dependencies including tex)" \
    sudo locales tzdata fonts-liberation fonts-dejavu inkscape ffmpeg \
    libsm6 libxext-dev libxrender1 lmodern netcat pandoc python-dev \
    texlive-fonts-extra texlive-fonts-recommended texlive-xetex \
    texlive-generic-recommended texlive-latex-base texlive-latex-extra

RUN rm -rf /var/lib/apt/lists/*

#
# Update conda and install jupyter
#

RUN conda update -n base -c defaults conda

RUN conda install -y \
    tini notebook jupyter jupyterhub jupyterlab nbconvert nbformat ipywidgets

RUN conda install -y -c conda-forge jupyterlab-git

RUN conda clean --all -y && \
    npm cache clean --force

#
# Install other software
#

RUN pip install \
    numpy pandas numexpr pandasql \
    scipy scikit-learn statsmodels scikit-image patsy networkx nltk spacy \
    jinja2 tqdm pyyaml requests unidecode python-louvain \
    graphviz pydot matplotlib seaborn \
    \
    sqlalchemy psycopg2 \
    \
    torchviz torchsummary captum tensorboard \
    transformers datasets sentencepiece emoji \
    pytorch-lightning pytorch-lightning-bolts

RUN pip install -f https://data.pyg.org/whl/torch-${PYG_VERSION}.html \
                torch-scatter torch-sparse torch-cluster torch-spline-conv \
                torch-geometric

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

ENTRYPOINT ["tini", "-g", "--"]
CMD ["start.sh"]

