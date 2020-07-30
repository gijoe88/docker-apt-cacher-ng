ARG     SOURCE_IMAGE=debian
ARG     SOURCE_TAG=buster

FROM    ${SOURCE_IMAGE}:${SOURCE_TAG}

ARG     CACHER_PACKAGE_VERSION=3.2.1-1

VOLUME  ["/var/cache/apt-cacher-ng"]
RUN     set -eux ; \
  DEBIAN_FRONTEND=noninteractive apt-get update ; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng=${CACHER_PACKAGE_VERSION} gawk gosu ; \
  rm -rf /var/lib/apt/lists/*

RUN     set -eux ; \
  sed -i 's#deb.debian.org#localhost:3142#g;s#security.debian.org#localhost:3142#g' /etc/apt/sources.list ; \
  echo 'Foreground: 1' >>/etc/apt-cacher-ng/acng.conf

EXPOSE  3142

ENV     ACNG_CACHE_DIR=/var/cache/apt-cacher-ng \
  ACNG_LOG_DIR=/var/log/apt-cacher-ng \
  ACNG_USER=root \
  REMAP_UBUPORTREP="ports.ubuntu.com /ubuntu-ports ; ports.ubuntu.com/ubuntu-ports" \
  REMAP_SECDEB="security.debian.org /debian-security ; security.debian.org deb.debian.org/debian-security"

COPY    entrypoint.sh /sbin/entrypoint.sh

RUN     chmod 755 /sbin/entrypoint.sh
ENTRYPOINT      [ "/sbin/entrypoint.sh" ]

CMD     [ "apt-cacher-ng" , "-c" , "/etc/apt-cacher-ng" ]
