ARG PYTORCH_VERSION=1.7.0-cuda11.0-cudnn8-runtime
FROM pytorch/pytorch:${PYTORCH_VERSION}

ARG PYTORCH_GEOMETRIC_VERSION=1.7.0+cu110
ARG LOCALE=en_US.UTF-8

USER root

#
# Configure repos, install updates
#

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates apt-transport-https apt-utils lsb-release \
    software-properties-common

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-add-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main"

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
# Update conda and install software
#

RUN conda update -n base -c defaults conda

RUN conda install -y \
    tini notebook jupyter jupyterhub jupyterlab nbconvert nbformat ipywidgets \
    \
    numpy pandas numexpr pandasql \
    scipy scikit-learn statsmodels scikit-image patsy networkx nltk spacy \
    jinja2 tqdm pyyaml requests unidecode python-louvain \
    graphviz pydot matplotlib seaborn \
    sqlalchemy sqlite psycopg2

RUN conda install -y -c pytorch \
    torchtext torchvision torchaudio captum

RUN conda install -y -c huggingface -c conda-forge \
    datasets

RUN conda install -y -c conda-forge \
    transformers sentencepiece emoji tensorboard jupyterlab-git

# These are not kept up to date enough on conda and so we go elsewhere
RUN pip install torchviz torchsummary pytorch-lightning pytorch-lightning-bolts
RUN pip install torch-scatter -f https://pytorch-geometric.com/whl/torch-${PYTORCH_GEOMETRIC_VERSION}.html && \
    pip install torch-sparse -f https://pytorch-geometric.com/whl/torch-${PYTORCH_GEOMETRIC_VERSION}.html && \
    pip install torch-cluster -f https://pytorch-geometric.com/whl/torch-${PYTORCH_GEOMETRIC_VERSION}.html && \
    pip install torch-spline-conv -f https://pytorch-geometric.com/whl/torch-${PYTORCH_GEOMETRIC_VERSION}.html && \
    pip install torch-geometric

# so we can use widgets in notebooks
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix

# facets, which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    cd && \
    rm -rf /tmp/facets

RUN conda clean --all -y && \
    npm cache clean --force

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

