# Minimal JupyterHub configuration
c = get_config()  #noqa

# Basic JupyterHub settings
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000

# Use dummy authenticator for testing (no passwords needed)
c.JupyterHub.authenticator_class = 'jupyterhub.auth.DummyAuthenticator'
c.DummyAuthenticator.password = "test"  # Everyone uses "test" as password

# Basic Docker settings - use Spark-enabled image
c.DockerSpawner.image = 'jupyter/pyspark-notebook:spark-3.5.0'
c.DockerSpawner.remove = True
c.DockerSpawner.network_name = 'rzv_de_project_online_airflow'

# Mount shared workspace - use host path, not JupyterHub container path
c.DockerSpawner.volumes = {
    '/home/lexxa/rzv_de_project_online/workspace/notebooks': {
        'bind': '/home/jovyan/work',
        'mode': 'rw'
    }
}

# Set notebook directory
c.DockerSpawner.notebook_dir = '/home/jovyan/work'

# Fix user permissions to match host user
c.DockerSpawner.environment.update({
    'NB_UID': 1001,
    'NB_GID': 1002,
    'CHOWN_EXTRA': '/home/jovyan/work',
    'CHOWN_EXTRA_OPTS': '-R',

    'SPARK_MASTER_URL': 'spark://spark-master:7077',
    'SPARK_DRIVER_HOST': '0.0.0.0',
    'SPARK_DRIVER_BIND_ADDRESS': '0.0.0.0',
    'SPARK_PUBLIC_DNS': 'spark.rzvde.pro',
    'SPARK_UI_PORT': 4042,

    # 'PYSPARK_SUBMIT_ARGS': '--conf spark.driver.port=4040 --conf spark.ui.port=4040 --conf spark.driver.host=0.0.0.0 --conf spark.driver.bindAddress=0.0.0.0 pyspark-shell'
}
)

# Must start as root for permission fixing to work
c.DockerSpawner.extra_create_kwargs = {'user': 'root'}

# Allow any user to login
c.Authenticator.allow_all = True

# Hub connection settings
c.JupyterHub.hub_ip = '0.0.0.0'

c.DockerSpawner.extra_host_config = {
    'publish_all_ports': False,
    'port_bindings': {
        '4042/tcp': ('0.0.0.0', 4042)
    }
}
