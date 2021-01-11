# Docker Stack For [InvenTree](https://github.com/inventree/InvenTree)/Postgres

Forked from [Zeigren/iventree-docker](https://github.com/Zeigren/inventree-docker) 

## Usage

```bash
git checkout https://github.com/rcludwick/inventree-docker
```

Create your docker compose file:

```yaml
  db:
    image: postgres
    container_name: db
    networks:
      - db
    expose:
      - 5432/tcp
    secrets:
      - postgres_password
      - postgres_user
    environment:
      - PGDATA=/var/lib/postgresql/data/pgdb
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
      - POSTGRES_USER_FILE=/run/secrets/postgres_user
    volumes:
      - /mnt/dockerdata/postgres/data:/var/lib/postgresql/data
    restart: unless-stopped

  inventree:
    build: ./inventree-docker
    container_name: inventree
    expose:
      - 9767/tcp
    networks:
      - proxy
      - db
    depends_on:
      - db
    volumes:
      - /mnt/dockerdata/inventree/static:/usr/src/static
      - /mnt/dockerdata/inventree/media:/usr/src/media
    secrets:
      - postgres_password
      - postgres_user
    environment:
      # CREATE SUPERUSER ONCE THEN DELETE THESE
      - CREATE_SUPERUSER=False
      - DJANGO_SUPERUSER_USERNAME=admin
      - DJANGO_SUPERUSER_EMAIL=admin@admin.com
      - DJANGO_SUPERUSER_PASSWORD=admin
      # Database Connection
      - DATABASE_NAME=inventree
      - DATABASE_USER_FILE=/run/secrets/postgres_user
      - DATABASE_PASSWORD_FILE=/run/secrets/postgres_password
      - DATABASE_PORT=5432
      - DATABASE_HOST=db
    restart: unless-stopped
```

Configure the configuration in ```docker-entrypoint.sh``` to you liking:

```yaml
# Database backend selection - Configure backend database settings
# Ref: https://docs.djangoproject.com/en/2.2/ref/settings/#std:setting-DATABASES
# Specify database parameters below as they appear in the Django docs
database:
  
  ENGINE: ${DATABASE_ENGINE:-django.db.backends.postgresql_psycopg2}
  NAME: ${DATABASE_NAME:-inventree}
  USER: ${DATABASE_USER:-inventree}
  PASSWORD: ${DATABASE_PASSWORD:-CHANGEME}
  HOST: ${DATABASE_HOST:-db}
  PORT: ${DATABASE_PORT:-5432}

# Select default system language (default is 'en-us')
language: ${DEFAULT_LANGUAGE:-en-us}

#Currencies to use
currencies:
  - USD
  - AUD
  - CAD
  - EUR
  - GBP
  - JPY
  - NZD

# Set debug to False to run in production mode
debug: ${DEBUG:-False}

# Set the default logging level:
log_level: ${LOG_LEVEL:-DEBUG}

# Leave this as star and assume set the appropriate gunicorn configuration in Dockerfile
allowed_hosts:
  - ${ALLOWED_HOSTS:-'*'}

# Cross Origin Resource Sharing (CORS) settings (see https://github.com/ottoyiu/django-cors-headers)
# Following parameters are 
cors:
  # CORS_ORIGIN_ALLOW_ALL - If True, the whitelist will not be used and all origins will be accepted.
  allow_all: ${CORS_ALLOW_ALL:-True}
  
  # CORS_ORIGIN_WHITELIST - A list of origins that are authorized to make cross-site HTTP requests. Defaults to []
  # whitelist:
  # - https://example.com
  # - https://sub.example.com

# MEDIA_ROOT is the local filesystem location for storing uploaded files
# By default, it is stored in a directory named 'media' local to the InvenTree directory
# This should be changed for a production installation
media_root: ${MEDIA_ROOT:-'/usr/src/media'}

# STATIC_ROOT is the local filesystem location for storing static files
# By default it is stored in a directory named 'static' local to the InvenTree directory
static_root: ${STATIC_ROOT:-'/usr/src/static'}

# Optional URL schemes to allow in URL fields
# By default, only the following schemes are allowed: ['http', 'https', 'ftp', 'ftps']
# Uncomment the lines below to allow extra schemes
#extra_url_schemes:
#  - mailto
#  - git
#  - ssh

# Set debug_toolbar to True to enable a debugging toolbar for InvenTree
# Note: This will only be displayed if DEBUG mode is enabled, 
#       and only if InvenTree is accessed from a local IP (127.0.0.1)
debug_toolbar: ${DEBUG_TOOLBAR:-False}

# Backup options
# Set the backup_dir parameter to store backup files in a specific location
# If unspecified, the local user's temp directory will be used
backup_dir: ${BACKUP_DIR:-'/home/inventree/backup/'}

# Sentry.io integration
# If you have a sentry.io account, it can be used to log server errors
# Ensure sentry_sdk is installed by running 'pip install sentry-sdk'
sentry:
  enabled: ${SENTRY_ENABLED:-False}
  dsn: ${SENTRY_DSN:-}

# LaTeX report rendering
# InvenTree uses the django-tex plugin to enable LaTeX report rendering
# Ref: https://pypi.org/project/django-tex/
# Note: Ensure that a working LaTeX toolchain is installed and working *before* starting the server
latex:
  # Select the LaTeX interpreter to use for PDF rendering
  # Note: The intepreter needs to be installed on the system!
  # e.g. to install pdflatex: apt-get texlive-latex-base
  enabled: ${LATEX_ENABLED:-False}
  # interpreter: pdflatex 
  # Extra options to pass through to the LaTeX interpreter
  # options: ''
```

Modify the ip whitelist in the Dockerfile

```Dockerfile
# Modify --forwarded-allow-ips to whitelist specific IP addresses.
CMD ["gunicorn", "--log-file=-", "--forwarded-allow-ips=*", "--workers=2", "--threads=4", "--worker-class=gthread", "--bind=:9767", "InvenTree.wsgi"]
```

Create the Docker secrets and expose them to the containers.  

Create the database in postgresql, this can be done by changing ```expose``` to ```ports``` and then logging in with pgcli with the username and password.

```postgresql
CREATE DATABASE inventree;
```

Build and run in docker compose:

```bash
docker-compose build inventree && docker-compose up -d inventree
```

To check to see if it's smoothly running:

```bash
docker-compose logs -f inventree
```
