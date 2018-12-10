ARG BASE=ubuntu:bionic
FROM $BASE
ENV PYTHONUNBUFFERED 1
ENV DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/Paris
ARG BUILD_DEV=y
ARG PY_VER=3.6
# See https://github.com/nodejs/docker-node/issues/380
ARG GPG_KEYS=B42F6819007F00F88E364FD4036A9C25BF357DD4
ARG GPG_KEYS_SERVERS="hkp://p80.pool.sks-keyservers.net:80 hkp://ipv4.pool.sks-keyservers.net hkp://pgp.mit.edu:80"

WORKDIR /code
ADD apt.txt /code/apt.txt

# setup project timezone, dependencies, user & workdir, gosu
RUN bash -c 'set -ex \
    && : "set correct timezone" \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && : "install packages" \
    && apt-get update -qq \
    && apt-get install -qq -y $(grep -vE "^\s*#" /code/apt.txt  | tr "\n" " ") \
    && apt-get clean all && apt-get autoclean \
    && : "project user & workdir" \
    && useradd -ms /bin/bash django --uid 1000 \
    && : ::: \
    && : install gosu \
    && : ::: \
    && mkdir /tmp/gosu && cd /tmp/gosu \
    && : :: gosu: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && : one keyserver may fail, try on multiple servers \
    && for k in $GPG_KEYS;do \
        touch /k_$k \
        && for s in $GPG_KEYS_SERVERS;do \
          if ( gpg -q --batch --keyserver $s --recv-keys $k );then \
            rm -f /k_$k && break;else echo "Keyserver failed: $s" >&2;fi;done \
        && if [ -e /k_$k ];then exit 1;fi \
       done \
    && urls="$( curl -s "https://api.github.com/repos/tianon/gosu/releases/latest" \
               | grep browser_download_url | cut -d "\"" -f 4\
               | egrep -i "sha|$arch"; )" \
    && : :: gosu: download artefacts \
    && while read u;do curl -sLO $u;done <<< "$urls" \
    && : :: gosu: integrity check \
    && for i in SHA256SUMS gosu-$arch;do gpg -q --batch --verify $i.asc $i &> /dev/null;done \
    && grep gosu-$arch SHA256SUMS | sha256sum -c - >/dev/null \
    && : :: gosu: filesystem install \
    && mv -f gosu-$arch /usr/bin/gosu \
    && chmod +x /usr/bin/gosu && cd / && rm -rf /tmp/gosu \
    && : ::: \
    && : "install https://github.com/jwilder/dockerize" \
    && : ::: \
    && mkdir /tmp/dockerize && cd /tmp/dockerize \
    && : :: dockerize: search latest artefacts and SHA files \
    && arch=$( uname -m|sed -re "s/x86_64/amd64/g" ) \
    && urls="$(curl -s \
        "https://api.github.com/repos/jwilder/dockerize/releases/latest" \
        | grep browser_download_url | cut -d "\"" -f 4\
        | ( if [ -e /etc/alpine-release ];then grep alpine;else grep -v alpine;fi; ) \
        | egrep -i "($(uname -s).*$arch|sha)" )" \
    && : :: dockerize: download and unpack artefacts \
    && while read u;do curl -sLO $u && tar -xf $(basename $u);done <<< "$urls" \
    && mv -f dockerize /usr/bin/dockerize \
    && chmod +x /usr/bin/dockerize && cd / && rm -rf /tmp/dockerize'

ADD crontab /etc/cron.d/django
CMD chmod 0644 /etc/cron.d/django

ADD local/terra-back-deploy/prod/start.sh \
    local/terra-back-deploy/prod/cron.sh \
    local/terra-back-deploy/prod/init.sh \
    /code/init

ADD requirements-dev.txt requirements.txt /code/
ADD src /code/src/
ADD lib /code/lib/
ADD private /code/private/

RUN bash -c 'set -ex \
    && chown django:django -R /code \
    && cd /code \
    && gosu django:django bash -c "python${PY_VER} -m venv venv \
    && venv/bin/pip install -U setuptools wheel \
    && venv/bin/pip install -U --no-cache-dir -r ./requirements.txt \
    && if [[ -n "$BUILD_DEV" ]];then \
      : dev requirements will be handled separatly in a later iteration;\
      venv/bin/pip install -U --no-cache-dir \
      -r ./requirements-dev.txt;\
    fi \
    && mkdir -p public/static public/media"'

# image will drop privileges itself using gosu
WORKDIR /code/src
CMD "/code/init.sh"
