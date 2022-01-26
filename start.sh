#!/bin/bash

set -e

/opt/jupyter/bin/jupyterhub -f /etc/jupyter/jupyterhub_config.py
