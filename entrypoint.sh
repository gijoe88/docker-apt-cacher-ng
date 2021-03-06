#!/bin/bash
set -e

create_pid_dir() {
  mkdir -p /run/apt-cacher-ng
  chmod -R 0755 /run/apt-cacher-ng
  chown ${ACNG_USER}:${ACNG_USER} /run/apt-cacher-ng
}

create_cache_dir() {
  mkdir -p ${ACNG_CACHE_DIR}
  ownership=$(stat --format="%U:%G" ${ACNG_CACHE_DIR})
  rights=$(stat --format="%a" ${ACNG_CACHE_DIR})
  if [ ! "x$rights" = "x755" ] ; then
    chmod -R 0755 ${ACNG_CACHE_DIR} ;
  fi ;
  if [ ! "x$ownership" = "x${ACNG_USER}:root" ] ; then
    chown -R ${ACNG_USER}:root ${ACNG_CACHE_DIR} ;
  fi ;
  sed -i "s#^CacheDir.*\$#CacheDir: ${ACNG_CACHE_DIR}#g" /etc/apt-cacher-ng/acng.conf
}

create_log_dir() {
  mkdir -p ${ACNG_LOG_DIR}
  rights=$(stat --format="%a" ${ACNG_LOG_DIR})
  ownership=$(stat --format="%U:%G" ${ACNG_LOG_DIR})
  if [ ! "x$rights" = "x755" ] ; then
    chmod -R 0755 ${ACNG_LOG_DIR} ;
  fi ;
  if [ ! "x$ownership" = "x${ACNG_USER}:${ACNG_USER}" ] ; then
    chown -R ${ACNG_USER}:${ACNG_USER} ${ACNG_LOG_DIR} ;
  fi ;
  sed -i "s#^LogDir.*\$#LogDir: ${ACNG_LOG_DIR}#g" /etc/apt-cacher-ng/acng.conf
}

add_rules() {
  env | gawk 'match( $0, /^REMAP_(.*)=(.*)$/, captured ) { printf "Remap-%s: %s\n", tolower(captured[1]), captured[2] ; }' >>/etc/apt-cacher-ng/acng.conf
}

change_port() {
  sed -i "s#Port:.*\$#Port: ${ACNG_PORT:-3142}#" /etc/apt-cacher-ng/acng.conf
}

change_config_folder_rights() {
  chown -R ${ACNG_USER}:${ACNG_USER} /etc/apt-cacher-ng
}

set_report_page() {
  if [[ ! -z "${ACNG_REPORTPAGE}" ]] ; then
    sed -i "s#ReportPage.*\$#ReportPage: ${ACNG_REPORTPAGE}#" /etc/apt-cacher-ng/acng.conf
  fi
}

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

  create_pid_dir
  create_cache_dir
  create_log_dir
  add_rules
  change_port
  set_report_page
  change_config_folder_rights

  sed -i "s#deb.debian.org#mydeb.debian.org:${ACNG_PORT:-3142}#g;s#security.debian.org#mysecurity.debian.org:${ACNG_PORT:-3142}#g" /etc/apt/sources.list
  echo "127.0.0.2 mydeb.debian.org mysecurity.debian.org" >>/etc/hosts

  exec gosu ${ACNG_USER} /usr/sbin/apt-cacher-ng ${EXTRA_ARGS}
else
  exec gosu ${ACNG_USER} $@
fi
