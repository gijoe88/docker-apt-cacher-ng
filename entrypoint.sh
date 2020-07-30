#!/bin/bash
set -e

create_pid_dir() {
  mkdir -p /run/apt-cacher-ng
  chmod -R 0755 /run/apt-cacher-ng
  chown ${ACNG_USER}:${ACNG_USER} /run/apt-cacher-ng
}

create_cache_dir() {
  mkdir -p ${ACNG_CACHE_DIR}
  chmod -R 0755 ${ACNG_CACHE_DIR}
  chown -R ${ACNG_USER}:root ${ACNG_CACHE_DIR}
  egrep -q '^CacheDir' /etc/apt-cacher-ng/acng.conf && sed -i "s#^CacheDir.*$#CacheDir: ${ACNG_CACHE_DIR}#g" || echo "CacheDir: ${ACNG_CACHE_DIR}" >>/etc/apt-cacher-ng/acng.conf
}

create_log_dir() {
  mkdir -p ${ACNG_LOG_DIR}
  chmod -R 0755 ${ACNG_LOG_DIR}
  chown -R ${ACNG_USER}:${ACNG_USER} ${ACNG_LOG_DIR}
  egrep -q '^LogDir' /etc/apt-cacher-ng/acng.conf && sed -i "s#^LogDir.*$#LogDir: ${ACNG_LOG_DIR}#g" || echo "CacheDir: ${ACNG_LOG_DIR}" >>/etc/apt-cacher-ng/acng.conf
}

add_rules() {
  env | gawk 'match( $0, /^REMAP_(.*)=(.*)$/, captured ) { printf "MyRemap-%s: nimp  %s\n", tolower(captured[1]), captured[2] ; }' >>/etc/apt-cacher-ng/acng.conf
}

change_port() {
  echo "Port:${ACNG_PORT:-3142}" >>/etc/apt-cacher-ng/acng.conf
}

create_pid_dir
create_cache_dir
create_log_dir
add_rules
change_port

# allow arguments to be passed to apt-cacher-ng
if [[ "x${1:0:1}" = "x-" ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ "x${1}" == "xapt-cacher-ng" || "x${1}" == "x$(command -v apt-cacher-ng)" ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch apt-cacher-ng
if [[ -z "${1}" ]]; then
  gosu ${ACNG_USER} /usr/sbin/apt-cacher-ng ${EXTRA_ARGS}
else
  exec $@
fi
