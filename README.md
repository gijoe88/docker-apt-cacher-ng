# gijoe88/docker-apt-cacher-ng

My thanks to [sameersbn](https://github.com/sameersbn) from who I copied this README and the entrypoint script. I promise I'll fork his project and propose a pull request to add my modifications.

- [Introduction](#introduction)
  - [Contributing](#contributing)
  - [Issues](#issues)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Command-line arguments](#command-line-arguments)
  - [Persistence](#persistence)
  - [Docker Compose](#docker-compose)
  - [Usage](#usage)
  - [Logs](#logs)
- [Maintenance](#maintenance)
  - [Cache expiry](#cache-expiry)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)

# Introduction

`Dockerfile` to create a [Docker](https://www.docker.com/) container image for [Apt-Cacher NG](https://www.unix-ag.uni-kl.de/~bloch/acng/).

Apt-Cacher NG is a caching proxy, specialized for package files from Linux distributors, primarily for [Debian](http://www.debian.org/) (and [Debian based](https://en.wikipedia.org/wiki/List_of_Linux_distributions#Debian-based)) distributions but not limited to those.

## Contributing

The [github repo](https://github.com/gijoe88/docker-apt-cacher-ng) is just a mirror of my personal repository on a private gitlab instance. Once I have put in place some secure settings, I'll open the sign-up from Github.
*But you can still open issues on Github!*

## Issues

Before reporting your issue please try updating Docker to the latest version and check if it resolves the issue. Refer to the Docker [installation guide](https://docs.docker.com/installation) for instructions.

SELinux users should try disabling SELinux using the command `setenforce 0` to see if it resolves the issue.

If the above recommendations do not help then [report your issue](../../issues/new) along with the following information:

- Output of the `docker version` and `docker info` commands
- The `docker run` command or `docker-compose.yml` used to start the image. Mask out the sensitive bits.
- Please state if you are using [Boot2Docker](http://www.boot2docker.io), [VirtualBox](https://www.virtualbox.org), etc.

# Getting started

## Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/gijoe88/docker-apt-cacher-ng) and is the recommended method of installation.
Automated build are only on adm64 architecture, I'll push other architectures later, notably aarch64 for example for Raspberry (3B+ and 4B are really useful).


```bash
docker pull gijoe88/docker-apt-cacher-ng
```

Alternatively you can build the image yourself.

```bash
docker build -t gijoe88/docker-apt-cacher-ng github.com/gijoe88/docker-apt-cacher-ng
```

## Quickstart

Start Apt-Cacher NG using:

```bash
docker run --name apt-cacher-ng --init -d --restart=always \
  --env ACNG_PORT=3142 \
  --publish 3142:3142 \
  --env ACNG_USER=1000 \
  --env ACNG_CACHE_DIR=/var/cache/apt-cacher-ng \
  --volume /srv/docker/apt-cacher-ng/cache:/var/cache/apt-cacher-ng \
  --env ACNG_LOG_DIR=/var/log/apt-cacher-ng \
  --volume /srv/docker/apt-cacher-ng/log:/var/log/apt-cacher-ng \
  gijoe88/docker-apt-cacher-ng
```

## Command-line arguments

You can customize the launch command of Apt-Cacher NG server by specifying arguments to `apt-cacher-ng` on the `docker run` command. For example the following command prints the help menu of `apt-cacher-ng` command:

```bash
docker run --name apt-cacher-ng --init -it --rm \
  gijoe88/docker-apt-cacher-ng -h
```

## Environment variables

**Non root user**: **not fully tested!**
- `ACNG_USER`: set this environment variable to uid to use, or to a user present in bare distro image. Event the EXEC commands when container is alive become rootless.

**Data location inside container**
- `ACNG_CACHE_DIR`: location of cache inside the container.
- `ACNG_LOG_DIR`: location of log files inside container

**Port to bind to inside container**
- `ACNG_PORT`: port to bind to in the container (3142 is the default). Pay attention to the fact that if `ACNG_USER` is not root, ports below 1024 cannot be binded to.

**Enabling ReportPage (aka admin)**
- `ACNG_REPORTPAGE`: page location of the report (default: not set, usual value: `acng-report.html`)

**Remapping rules**<br />
Some rules are already added in this image to the default ones from base distro package.
To add others, you can use the variables `REMAP_{yourdebalias}` with the value you want it to take in apt-cacher-ng configuration.<br />Example with the two already added inside the image:
- The environment variable `REMAP_SECDEB` with value `/debian-security ; security.debian.org deb.debian.org/debian-security` gives the rule<br />
`Remap-secdeb: /debian-security ; security.debian.org deb.debian.org/debian-security`
- `REMAP_UBUPORTREP` with value `ports.ubuntu.com /ubuntu-ports ; ports.ubuntu.com/ubuntu-ports` gives the rule<br />
`Remap-ubuportrep: ports.ubuntu.com /ubuntu-ports ; ports.ubuntu.com/ubuntu-ports`

The explanation of the rules may be found on [apt-cacher-ng documentation](https://www.unix-ag.uni-kl.de/~bloch/acng/html/config-serv.html#repmap).

## Persistence

For the cache to preserve its state across container shutdown and startup you should mount a volume at `/var/cache/apt-cacher-ng` (or whatever is the value of `ACNG_CACHE_DIR` environment variable).

> *The [Quickstart](#quickstart) command already mounts a volume for persistence.*

SELinux users should update the security context of the host mountpoint so that it plays nicely with Docker:

```bash
mkdir -p /srv/docker/apt-cacher-ng
chcon -Rt svirt_sandbox_file_t /srv/docker/apt-cacher-ng
```

## Docker Compose

To run Apt-Cacher NG with Docker Compose, create the following `docker-compose.yml` file

```yaml
version: '3'

services:
  apt-cacher-ng:
    image: sameersbn/apt-cacher-ng
    container_name: apt-cacher-ng
    ports:
      - "3142:3142"
    volumes:
      - apt-cacher-ng:/var/cache/apt-cacher-ng
    restart: always

volumes:
  apt-cacher-ng:
---
```

The Apt-Cache NG service can then be started in the background with:

```bash
docker-compose up -d
```

## Usage

To start using Apt-Cacher NG on your Debian (and Debian based) host, create the configuration file `/etc/apt/apt.conf.d/01proxy` with the following content:

```config
Acquire::HTTP::Proxy "http://{YOUR_APT_CACHER_IP}:3142";
Acquire::HTTPS::Proxy "false";
```
`YOUR_APT_CACHER_IP` is the IP of the docker host if port 3142 is exposed, or the IP of the container, which may be found using
```bash
docker container inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apt-cacher-ng
```


Similarly, to use Apt-Cacher NG in your Docker containers add the following line to your `Dockerfile` before any `apt-get` commands.

```dockerfile
RUN echo 'Acquire::HTTP::Proxy "http://{YOUR_APT_CACHER_IP}:3142";' >> /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy
```

## Logs

To access the Apt-Cacher NG logs, located at `/var/log/apt-cacher-ng`, you can use `docker exec`. For example, if you want to tail the logs:

```bash
docker exec -it apt-cacher-ng tail -f /var/log/apt-cacher-ng/apt-cacher.log
```

# Maintenance

## Cache expiry

Using the [Command-line arguments](#command-line-arguments) feature, you can specify the `-e` argument to initiate Apt-Cacher NG's cache expiry maintenance task.

```bash
docker run --name apt-cacher-ng --init -it --rm \
  --volume /srv/docker/apt-cacher-ng:/var/cache/apt-cacher-ng \
  gijoe88/docker-apt-cacher-ng -e
```

The same can also be achieved on a running instance by visiting the url http://localhost:3142/acng-report.html in the web browser and selecting the **Start Scan and/or Expiration** option.

## Upgrading

To upgrade to newer releases:

  1. Download the updated Docker image:

  ```bash
  docker pull gijoe88/docker-apt-cacher-ng
  ```

  2. Stop the currently running image:

  ```bash
  docker stop apt-cacher-ng
  ```

  3. Remove the stopped container

  ```bash
  docker rm -v apt-cacher-ng
  ```

  4. Start the updated image

  ```bash
  docker run --name apt-cacher-ng --init -d \
    [OPTIONS] \
    gijoe88/docker-apt-cacher-ng
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it apt-cacher-ng bash
```
