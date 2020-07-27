FROM    ${SOURCE_IMAGE}:${SOURCE_TAG}

VOLUME  ["/var/cache/apt-cacher-ng"]
RUN     DEBIAN_FRONTEND=noninteractive apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng=${CACHER_PACKAGE_VERSION} && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cron && \
        rm -rf /var/lib/apt/lists/*

RUN     echo "http://security.debian.org/debian-security" >/etc/apt-cacher-ng/backend_debian-security && \
        echo "Remap-secdeb: /debian-security ; security.debian.org deb.debian.org/debian-security" >>/etc/apt-cacher-ng/acng.conf && \
        echo "Remap-ubuportrep: ports.ubuntu.com /ubuntu-ports ; ports.ubuntu.com/ubuntu-ports" >>/etc/apt-cacher-ng/acng.conf && \
        sed -i 's#deb.debian.org#localhost:3142#g;s#security.debian.org#localhost:3142#g' /etc/apt/sources.list

EXPOSE  3142
CMD     chmod 777 /var/cache/apt-cacher-ng && cron && /etc/init.d/apt-cacher-ng start && tail -f /var/log/apt-cacher-ng/*
