# Intro to Singularity

Unlike Docker Singularity does not provide an integrated virtual machine for Mac and Windows platforms. We will use
what was learned above to build and run Singularity inside of a Docker container. If you are running on a Linux system this
is still a good exercise, although you may install and run Singularity directly if desired.

## Singularity Dockerfile
To create a Docker image containing Singularity we'll use the following recipe

* Create a new folder to store your `Dockerfile`
* Use `ubuntu:17.10` as the base image
* Install system packages required to build and run Singularity
  * `apt-get -y update && apt-get -y install vim sudo wget git autoconf libtool build-essential python squashfs-tools`
* Follow the installation instructions for [Singularity/2.4.2](http://singularity.lbl.gov/install-linux#option-1-download-latest-stable-release)
  * Each instance of `RUN` is executed in `/`, make sure you're in the right directory
  * `sudo` is not needed as you are running the build as `root`
* For demonstration purposes we'll setup a user named `foo` and tell docker to run under this user
  * `RUN useradd -ms /bin/bash foo && usermod -aG sudo foo && passwd -d foo`
  * `USER foo` 
  * `WORKDIR /home/foo`
* Build the Docker container and name it `singularity:2.4.2`

<details>
  <summary>Expand to see solution Dockerfile</summary>
  <p>
  
  ```
  FROM ubuntu:17.10
       
  RUN apt-get -y update && \
      apt-get -y install vim sudo git wget autoconf libtool build-essential python squashfs-tools
     
  RUN VERSION=2.4.2 && \
      wget https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz && \
      tar xvf singularity-$VERSION.tar.gz && \
      cd singularity-$VERSION && \
      ./configure --prefix=/usr/local && \
      make && \
      make install
     
  RUN useradd -ms /bin/bash foo && \
      usermod -aG sudo foo && \
      passwd -d foo
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

`exit` the interactive Singularity shell and return to our Docker container with Singularity installed. 


## Creating and building a Singularity recipe
Let's use a Singularity definition file to run the `MPI example`. The recipe, which we'll create in a file called `mpi.def` will be:

* The first line should define the bootstrap method, we'll use docker
  * `BootStrap: docker`
* When using docker bootstrap we need to specify the Docker Hub image
  * `From: ubuntu:17.10`
* The `%post` section, which is an `sh` script that runs after the bootstrap process, will do the following
  * `apt-get -y update`
  * `apt-get -y install mpich`

Now to build our image, `mpi.img`
```
foo@<id>:~$ sudo singularity build mpi.img mpi.def
```
If the image built successfully we should be able to see it `mpi.img` the current directory
```
foo@<id>:~$ ls
mpi.def  mpi.img
```

## Running the Singularity container
Outside of our Singularity container lets create a copy of the sample MPI application `helloworld.c`. 
Once created compile and run the MPI sample, as you did with the Docker example. To execute a command in the container you will use the following
```
singularity exec <container> <command>
```
<details>
  <summary>Expand to see solution</summary><p>
  
We begin by compiling
  
```
foo@<id>:~$ singularity exec mpi.img mpicc helloworld.c -o hello
```

We can check that this created the executable `hello` in the currently directory, which exists outside of our Singularity container

```
foo@<id>:~$ ls
mpi.def  mpi.img  hello
```

Now to run inside of our container
```
foo@<id>:~$ singularity exec mpi.img mpirun -n 10 ./hello
hello from 2 of 10 on <id>
hello from 4 of 10 on <id>
hello from 5 of 10 on <id>
hello from 0 of 10 on <id>
hello from 7 of 10 on <id>
hello from 3 of 10 on <id>
hello from 1 of 10 on <id>
hello from 8 of 10 on <id>
hello from 9 of 10 on <id>
hello from 6 of 10 on <id>
```
</p></details>