# Intro to Singularity

Unlike Docker Singularity does not provide an integrated virtual machine for Mac and Windows platforms. We will use
what we learned in the `intro to Docker` section to build and run Singularity inside of a Docker container.

## Singularity Dockerfile
To create a Docker image containing Singularity we'll use the following recipe

* Create a new folder to store your `Dockerfile`
* Use `ubuntu:17.10` as the base image
* Install system packages required to build and run Singularity
  * `apt-get -y update && apt-get -y install wget git autoconf libtool build-essential python squashfs-tools`
* Follow the installation instructions for [Singularity/2.4.2](http://singularity.lbl.gov/install-linux#option-1-download-latest-stable-release)
  * Each instance of `RUN` is executed in `/`, make sure you're in the right directory
  * `sudo` is not needed as you are running the build as `root`
* For demonstration purposes we'll setup a user named `foo` and tell docker to run under this user
  * `RUN useradd -ms /bin/bash foo`
  * `USER foo` 
  * `WORKDIR /home/foo`
* Build the Docker container and name it `singularity:2.4.2`

<details>
  <summary>Expand to see solution Dockerfile</summary>
  <p>
  
  ```
  FROM ubuntu:17.10
       
  RUN apt-get -y update && \
      apt-get -y install git wget autoconf libtool build-essential python squashfs-tools
     
  RUN VERSION=2.4.2 && \
      wget https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz && \
      tar xvf singularity-$VERSION.tar.gz && \
      cd singularity-$VERSION && \
      ./configure --prefix=/usr/local && \
      make && \
      make install
     
  RUN useradd -ms /bin/bash foo
  USER foo
  WORKDIR /home/foo
  ```
  </p></details>

## Running
Now lets see how Singularity behaves at runtime. To do so we'll enter an interactive shell within our Docker container.
`--privileged` is needed to run nested containers.

```
$ docker run -it --privileged singularity:2.4.2 
```

First lets verify that singularity is installed correctly
```
foo@<id>:~$ singularity --version
2.4.2-dist
```
Now we should be the user `foo` and in `/home/foo`, as specified in the Dockerfile
```
foo@<id>:~$ whoami
foo
```
```
foo@<id>:~$ pwd
/home/foo
```

Singularity can easily run images directly from Docker Hub
```
foo@<id>:~$ singularity shell docker://ubuntu:17.10
```

Now that we're in a Singularity container lets see how it differs from Docker
```
Singularity ubuntu:17.10:~> whoami
foo
```

```
Singularity ubuntu:17.10:~> pwd
/home/foo
```
When running a Singularity container your user inside of the container is the same as your user outside of the container.
You also have access to many of the same directories inside of the container that your user has outside of the container. This is
is in contrast to the Docker default where you run as root with no host directories mounted.

## Creating and building a Singularity recipe