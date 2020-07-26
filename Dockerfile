FROM    ${SOURCE_IMAGE}:${SOURCE_TAG}

VOLUME  ["/var/cache/apt-cacher-ng"]
RUN     DEBIAN_FRONTEND=noninteractive apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng=${CACHER_PACKAGE_VERSION} && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cron

EXPOSE  3142
CMD     chmod 777 /var/cache/apt-cacher-ng && cron && /etc/init.d/apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*