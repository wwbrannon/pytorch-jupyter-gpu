import os, sys
c = get_config()

c.JupyterHub.bind_url = 'http://0.0.0.0:8000/'

c.Spawner.notebook_dir = '~/notebooks'
c.Spawner.default_url = '/lab'

