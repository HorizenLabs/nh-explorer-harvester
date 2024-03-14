ARG ARG_FROM_IMAGE=python
ARG ARG_FROM_IMAGE_TAG=3.8-buster

# base image
FROM ${ARG_FROM_IMAGE}:${ARG_FROM_IMAGE_TAG}

ARG ARG_VIRTUAL_ENV=/opt/venv
ARG ARG_GOSU_VERSION=1.16
ARG ARG_TINI_VERSION=v0.19.0
ARG ARG_WORKDIR=/usr/src

ENV GOSU_VERSION="${ARG_GOSU_VERSION}" \
    TINI_VERSION="${ARG_TINI_VERSION}" \
    VIRTUAL_ENV="${ARG_VIRTUAL_ENV}" \
    PATH="${ARG_VIRTUAL_ENV}/bin:${PATH}" \
    WORKDIR="${ARG_WORKDIR}" \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="${PYTHONPATH}:/usr/src"

WORKDIR "${WORKDIR}"

SHELL ["/bin/bash", "-c"]

## add requirements
COPY ci/docker-entrypoint.sh /usr/local/bin/entrypoint.sh
COPY . /usr/src

RUN set -eEuo pipefail \
    && apt-get update \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils \
    && DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install wget git vim ca-certificates gnupg software-properties-common lsb-release curl pigz btrfs-progs \
    && savedAptMark="$(apt-mark showmanual)" \
    && if ! command -v gosu &> /dev/null; then \
      if ! command -v gpg2 &> /dev/null; then \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg2 dirmngr; \
      fi \
      && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
      && curl -sSfL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" > /usr/local/bin/gosu \
      && curl -sSfL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" > /usr/local/bin/gosu.asc \
      && export GNUPGHOME="$(mktemp -d)" \
      && ( gpg2 --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || \
       gpg2 --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || \
       gpg2 --batch --keyserver pgp.mit.edu --recv-key B42F6819007F00F88E364FD4036A9C25BF357DD4 ) \
      && gpg2 --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
      && ( gpgconf --kill dirmngr || true ) \
      && ( gpgconf --kill gpg-agent || true ) \
      && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
      && unset GNUPGHOME \
      && chmod +x /usr/local/bin/gosu \
      && gosu --version; \
    fi \
    && if ! command -v tini &> /dev/null; then \
      if ! command -v gpg2 &> /dev/null; then \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg2 dirmngr; \
      fi \
      && curl -sSfL "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" > /usr/local/bin/tini \
      && curl -sSfL "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc" > /usr/local/bin/tini.asc \
      && export GNUPGHOME="$(mktemp -d)" \
      && ( gpg2 --batch --keyserver hkps://keys.openpgp.org --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 || \
       gpg2 --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 || \
       gpg2 --batch --keyserver pgp.mit.edu --recv-key 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 ) \
      && gpg2 --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
      && ( gpgconf --kill dirmngr || true ) \
      && ( gpgconf --kill gpg-agent || true ) \
      && rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc \
      && unset GNUPGHOME \
      && chmod +x /usr/local/bin/tini \
      && tini --version; \
    fi \
    && apt-mark auto '.*' &> /dev/null && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark &> /dev/null \
    && rm -rf /var/cache/apt/archives/*.deb /var/lib/apt/lists/* /root/.cache /tmp/*

## install requirements
RUN set -eEuo pipefail  \
    && mkdir -p "${VIRTUAL_ENV}" \
    && python -m venv "${VIRTUAL_ENV}" \
    && . "${VIRTUAL_ENV}"/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["./start.sh"]
