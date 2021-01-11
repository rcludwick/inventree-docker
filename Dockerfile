ARG VERSION=master
ARG DOCKER_TAG=latest

FROM python:alpine AS production

ARG VERSION
ARG DOCKER_TAG

ENV PYTHONUNBUFFERED 1
ENV INVENTREE_ROOT="/usr/src/app"
ENV INVENTREE_HOME="/usr/src/app/InvenTree"
ENV INVENTREE_STATIC="/usr/src/static"
ENV INVENTREE_MEDIA="/usr/src/media"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"


RUN apk add --no-cache gcc libgcc g++ libstdc++ postgresql-contrib postgresql-dev
RUN apk add --no-cache libjpeg-turbo zlib jpeg libffi zlib-dev cairo pango gdk-pixbuf musl libpq fontconfig
RUN apk add --no-cache libjpeg-turbo-dev zlib-dev jpeg-dev libffi-dev cairo-dev pango-dev gdk-pixbuf-dev musl-dev
RUN apk add --no-cache ttf-dejavu ttf-opensans ttf-ubuntu-font-family font-croscore font-noto ttf-droid ttf-liberation msttcorefonts-installer
RUN apk add --no-cache git make bash python3

RUN python -m venv $VIRTUAL_ENV && pip install --upgrade pip setuptools wheel
RUN python -m venv $VIRTUAL_ENV && pip install --no-cache-dir -U gunicorn
RUN python -m venv $VIRTUAL_ENV && pip install --no-cache-dir -U psycopg2 pgcli ipython

RUN if [ $DOCKER_TAG = latest ] ; \
    then git clone --branch master --depth 1 https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT} ; \
    else git clone --branch ${VERSION} --depth 1 https://github.com/inventree/InvenTree.git ${INVENTREE_ROOT} ; fi

ENV DEV_FILE="False"
RUN python -m venv $VIRTUAL_ENV && pip install --no-cache-dir -U -r /usr/src/app/requirements.txt
RUN if [ $DEV_FILE = True ] ; then pip install --no-cache-dir -U -r /usr/src/dev_requirements.txt; fi

RUN apk del --no-cache gcc g++ postgresql-dev
RUN apk del --no-cache libjpeg-turbo-dev zlib-dev jpeg-dev libffi-dev cairo-dev pango-dev gdk-pixbuf-dev git make musl-dev

RUN apk add --no-cache ttf-dejavu ttf-opensans ttf-ubuntu-font-family font-croscore font-noto ttf-droid ttf-liberation msttcorefonts-installer
RUN update-ms-fonts
RUN fc-cache -fv

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$DATE \
    org.label-schema.vendor="rcludwick" \
    org.label-schema.name="rcludwick/inventree-docker" \
    #org.label-schema.url="https://hub.example.com/r/some-user/inventree-docker" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$URL \
    org.label-schema.vcs-branch=$BRANCH \
    org.label-schema.vcs-ref=$COMMIT

COPY start_gunicorn.sh wait-for.sh /
RUN chmod +x /start_gunicorn.sh /wait-for.sh

WORKDIR ${INVENTREE_HOME}

CMD /start_gunicorn.sh

