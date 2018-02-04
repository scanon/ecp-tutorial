# Intro to Docker

## Pulling and running an existing image

Pull a public image such as ubuntu or centos using the docker pull command.  If a tag is not specified, docker will default to "latest".

```bash
$ docker pull ubuntu:14.04
```

Now run the image using the docker run command.  Use the "-it" option to get an interactive terminal during the run.

```bash
$ docker run -it ubuntu:14.04
$ whoami
$ lsb_release -a
```

## Making changes and committing them

Using standard linux commands, modify the image.  

```bash
$ docker run -it ubuntu:14.04
root@949eb1a6a099:/# (echo '#!/bin/bash'|echo "echo 'Hello World'") > /bin/hello
$ chmod 755 /bin/hello
# Test it
$ hello
# Exit
$ exit
```

Now find the container and commit the changes to a new image called hello.
```bash
docker ps -a|head -2
# Grab the Container ID
docker commit <ID> hello
```

Now try running the new image with your changes.

```bash
docker run -it hello
hello
```

## Creating and building a Dockerfile

While manually modifying and committing changes is one way to build images, using a Dockerfile provides a way to build images so that others can understand how the image was constructed and make modifications.

A Dockerfile has many options.  We will focus on a few basic ones (FROM, MAINTAINER, ADD, and RUN)

Create a simple shell script called script in your local directory using your favorite editor.

```
cat > hello << EOF
#!/bin/bash
echo "Shane says Hello World!"
EOF
```

Now create a file called Dockerfile in the same directory with contents similar to this.  Use your own name and e-mail for the maintainer.

```
FROM ubuntu:14.04
MAINTAINER Shane Canon <scanon@lbl.gov>

ADD ./hello /bin/hello
RUN chmod a+rx /bin/hello
```

Now build the image using the docker build command.  Be sure to use the `-t` option to tag it.  Tell the Dockerfile to build using the current directory by specifying `.`.  Alternatively you could place the Dockerfile and script in an alternate location and specify that directory in the docker build command.

```bash
docker build -t hello:1.0 .
```

Try running the image.

```bash
docker run -it hello:1.0
hello
```

## Pushing a Dockerfile to dockerhub

Docker provides a public hub that can be use to store and share images.  Before pushing an image, you will need to create an account at Dockerhub.  Go to [https://cloud.docker.com/](https://cloud.docker.com/) to create the account.  Once the account is created, push your test image using the docker push command.  In this example, we will assume the username is patsmith.

```bash
docker tag hello:1.0 patsmith/hello:1.0
docker push patsmith/hello:1.0
```

The first push make take some time depending on your network connection and the size of the image.

## Hands on Activity: MPI hello world

Now that you've practiced loading a simple script, try creating an image that can run this short MPI hello word code:

```code
// Hello World MPI app
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    int size, rank;
    char buffer[1024];

    MPI_Init(&argc, &argv);

    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    gethostname(buffer, 1024);

    printf("hello from %d of %d on %s\n", rank, size, buffer);

    MPI_Barrier(MPI_COMM_WORLD);

    MPI_Finalize();
    return 0;
}
```
Hints:
* You can start with the image "nersc/ubuntu-mpi:14.04". It already has MPI installed.
* You compile with "mpicc helloworld.c -o /app/hello"

<details>
  <summary>Expand to see the answer</summary>
  <p>

Dockerfile:
```bash
# MPI Dockerfile
FROM nersc/ubuntu-mpi:14.04

ADD helloworld.c /app/

RUN cd /app && mpicc helloworld.c -o /app/hello
```

docker build -t mydockerid/hellompi:latest .

docker push mydockerid/hellompi:latest

Log into the image and run the app:

docker run -it mydockerid/hellompi:latest

root@982d980864e5:/# mpirun -n 10 /app/hello
hello from 3 of 10 on 982d980864e5

hello from 4 of 10 on 982d980864e5

hello from 7 of 10 on 982d980864e5

hello from 9 of 10 on 982d980864e5

hello from 2 of 10 on 982d980864e5

hello from 5 of 10 on 982d980864e5

hello from 8 of 10 on 982d980864e5

hello from 0 of 10 on 982d980864e5

hello from 6 of 10 on 982d980864e5

hello from 1 of 10 on 982d980864e5

</p></details>

# Intro to Singularity

Unlike Docker Singularity does not provide an integrated virtual machine for Mac and Windows platforms. We will use
what was learned above to build and run Singularity inside of a Docker container. If you are running on a Linux system this
is still a good exercise, although you may install and run Singularity directly if desired.

## Singularity Dockerfile
To create a Docker image containing Singularity we'll use the following recipe

* Create a new folder on your host system to store your `Dockerfile`
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

## Running Docker images with Singularity
Now lets see how Singularity behaves at runtime. To do so we'll enter an interactive shell within our Docker container.
To run nested containers we will need to add `--privileged`.

```
$ docker run -it --privileged singularity:2.4.2 
```

First lets verify that singularity is installed correctly
```
foo@<id>:~$ singularity --version
2.4.2-dist
```
Now we should be the user `foo` and in `/home/foo`, as specified in the Dockerfile. For the rest of the tutorial we should 
forget that this we're in a Docker container and consider it our host system.
```
foo@<id>:~$ whoami
foo
```
```
foo@<id>:~$ pwd
/home/foo
```

Lets create a file, `bar`, in `foo`'s home directory
```
foo@<id>:~$ touch bar
foo@<id>:~$ ls
bar
```

Singularity can easily run Docker images. To get an interactive shell in ubuntu:17.10 from Docker Hub we can use the following 
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

```
Singularity ubuntu:17.10:~> ls
bar
```

When running a Singularity container your user inside of the container is the same as your user on the host. 
You also have access to the same user directories inside of the container that your user has outside of the container. This is
is in contrast to the Docker default where you run as root with no host directories mounted.

Type `exit` to return to our "host". 


## Creating and building a Singularity recipe
Let's use a Singularity definition file to run the `MPI example`. The recipe, which we'll create in a file called `mpi.def` will be:

* The first line should define the bootstrap method, we'll use docker
  * `BootStrap: docker`
* When using docker bootstrap we need to specify the Docker Hub image
  * `From: ubuntu:17.10`
* The `%post` section, which is an `sh` script that runs after the bootstrap process, will install mpich
  * `apt-get -y update`
  * `apt-get -y install mpich`

Now to build our image, `mpi.img`
```
foo@<id>:~$ sudo singularity build mpi.img mpi.def
```
If the image built successfully we should be able to see it, `mpi.img`, the current directory
```
foo@<id>:~$ ls
mpi.def  mpi.img
```

## Running in a Singularity container
On the host lets create a copy of the sample MPI application `helloworld.c`. 
Once the source is created compile and run the [MPI sample](01-hands-on.md#hands-on-activity-mpi-hello-world), as you did with the Docker example. To execute a command in the container you will use the following
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