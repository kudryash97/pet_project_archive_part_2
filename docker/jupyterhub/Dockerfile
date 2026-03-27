FROM jupyterhub/jupyterhub:5.3

# Install minimal requirements
RUN pip3 install --no-cache-dir dockerspawner

# Create directories
RUN mkdir -p /srv/jupyterhub

WORKDIR /srv/jupyterhub

# Simple start command
CMD ["jupyterhub"]