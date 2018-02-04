# Second hands-on - HPC

## Logging in to NERSC

Use ssh to connect to Cori.  The username and password will be on the training account sheet.

```bash
ssh <account>@cori.nersc.gov
```

## Pulling an image with Shifter

Pull an image using shifterimg.  You can pull a standard image such as Ubuntu or an image you pushed to dockerhub in the previous session.

```bash
shifterimg pull ubuntu:14.04
# OR
shifterimg pull scanon/shanetest:latest
```

## Running an image interactively with Shifter

Use salloc and shifter to test the image.

```bash
salloc -N 1 -C haswell -q regular --reservation=ecp_tut --image ubuntu:14.04 -A ntrain
shifter bash
```

You should be able to browse inside the image and confirm that it matches what you pushed to dockerhub earlier.

```bash
ls -l /app
lsb_release -a
```

Once you are done exploring, exit out.
```bash
exit
exit
```

## Submitting a Shifter batch job

Now create a batch submission script and try running a batch job with shifter.  Use vi or your other favorite editor to create the submission script or cat the contents into a file.

```bash
cat << EOF > submit.sl
#!/bin/bash
#SBATCH -N 1 -C haswell
#SBATCH --reservation=ecp_tut
#SBATCH -q regular
#SBATCH -A ntrain
#SBATCH --image ubuntu:latest

srun -N 1 shifter /app/app.py
EOF
```
Use the SLURM sbatch command to submit the script.

```bash
sbatch ./submit.sl
```

## Running a parallel Python MPI job with Shifter

It is possible to run MPI jobs in Shifter and obtain native performance.  There are several ways to achieve this. We will demonstrate one approach here.

On your laptop create and push a docker image with MPICH and a sample application installed.


First, create and save a Hello World MPI application.  You can find the code in the examples/shifter directory too.
```code
// Hello World MPI app
#include <mpi.h>

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

Next create, a Dockerfile that install MPICH and the application.

```bash
# MPI Dockerfile
FROM nersc/ubuntu-mpi:14.04

ADD helloworld.c /app/

RUN cd /app && mpicc helloworld.c -o /app/hello

ENV PATH=/usr/bin:/bin:/app:/usr/local/bin
```

Build and push the image.
```bash
docker build -t <mydockerid>/hellompi:latest .
docker push <mydockerid>/hellompi:latest
```

Next, return to your Cori login, pull your image down and run it.

```bash
shifterimg pull <mydockerid>/hellompi:latest
#Wait for it to complete
salloc -N 2 -C haswell -q regular -A ntrain --reservation=ecp_tut --image <mydockerid>/hellompi:latest
# Wait for prepare_compilation_report
# Cori has 32 physical cores per node with 2 hyper-threads per core.  
# So you can run up to 64 tasks per node.
srun -N 2 -n 128 shifter /app/hello
exit
```

If you have your own MPI applications, you can attempt to Docker-ize them using the steps above and run it on Cori.  As a courtesy, limit your job sizes to leave sufficient resources for other participants.  _Don't forget to exit from any "salloc" shells once you are done testing._

## Using Volume mounts with Shifter

Like Docker, Shifter allows you to mount directories into your container.
The syntax is similar to Docker but uses "--volume".  Here we will mount a
scratch directory into the volume as /data.

```bash
mkdir $SCRATCH/input
echo 3.141592 > $SCRATCH/input/data.txt
shifter --volume $SCRATCH/input:/data --image=ubuntu bash
cat /data/data.txt
```

## Logging into the OLCF
Use ssh to connect to Titan. The account name will be on your RSA token envelope, e.g. `csep123`. To setup your account the steps are as follows

* `ssh <csep#>@titan.ccs.ornl.gov`
* When prompted for a `PASSCODE`, enter the (6) digit code shown on the RSA token.
* You will be asked if you are ready to set your `PIN`. Answer with `Y`.
* You will be prompted to enter a `PIN`. Enter a (4) digit number you can remember. You will then be prompted to re-enter your `PIN`.
* You will then be prompted to wait until the next code appears on your RSA token and to enter your `PASSCODE`. When the (6) digits on your RSA token change, enter your (4) PIN digits followed immediately by the new (6) digits displayed on your RSA token. 
  * Note that any set of (6) digits on the RSA token can only be “used” once.
* Your account is now ready to use, now when prompted for a `PASSCODE` you will enter your (4) digit `PIN` followed by the (6) digits on the RSA token

## Get situated
Your NFS home directory, `/ccs/home<csep#>`, is not visible to the Titan compute nodes. To simplify this demo 
we'll work out of a lustre scratch space that is available  read/write on the login, batch, and compute nodes.

```
$ cd /lustre/atlas/scratch/<csep#>/trn001
```

## Building HPC containers
Although users are free to build their own Singularity container from scratch and run on OLCF resources the diverse set of 
 architectures and often propriety vendor software stack makes this an exceedingly difficult task. 
 
 To integrate containers into this environment the OLCF provides `container-builder`, a utility for building Singularity images based on Singularity or Docker recipe files 
 directly from OLCF HPC login nodes. 
 
 `container-builder` has access to a private Docker repository containing system specific base images that come 
 with vendor specific software such as MPI and CUDA pre-installed.
 
## Using container-builder
To see how `container-builder` works we'll create a container capable of running mpi4py and CUDA applications on Titan. You are free to use 
either Dockerfile or Singularity recipe syntax, `container-builder` will automatically detect the type and build the Singularity container accordingly.

* Create the recipe file, `mpi.def`
* Use the following base image `olcf/titan:ubuntu-16.04_2018-01-18`
  * This image is based on Ubuntu/16.04 and includes a snapshot of Titan's MPI/CUDA software stack from 2018-01-18
* Install mpi4py, `pip install mpi4py`

Now to build our recipe into a Singularity image, `mpi.img`
```
$ module load container-builder
$ container-builder mpi.img mpi.def
```

The output of the build process will be streamed as it's run on a remote ephemeral VM and the final container image will be 
transferred if the build succeeds.
```
$ ls
mpi.def  mpi.img
```

## Running a Python container on Titan
Lets first begin by entering an interactive batch job, reserving (2) compute nodes. 
We will then return to the scratch directory and load the Singularity module
```
$ qsub -I -ATRN001 -lwalltime=02:00:00,nodes=2
qsub: waiting for job <id> to start
qsub: job <id> ready

$ cd /lustre/atlas/scratch/<csep#>/trn001
$ module load singularity
```

Create `HelloMPI.py` in the current directory with the following format
```
from mpi4py import MPI
import sys
import platform

size = MPI.COMM_WORLD.Get_size()
rank = MPI.COMM_WORLD.Get_rank()

sys.stdout.write("Hello from mpi4py %s : rank %d of %d \n" % (platform.linux_distribution(), rank, size))
```

We can use Cray's `aprun` utility to launch (1) instance of `command` per node across (2) nodes using the following syntax
```
$ aprun -n 2 -N 1 <command>
```

Try and construct an `aprun` command to execute the python example, `python HelloMPI.py`, inside of the singularity image `mpi.img`.

<details> <summary>Expand to see solution</summary><p>
  
```
$ aprun -n 2 -N 1 singularity exec ./mpi.img python ./HelloMPI.py
Hello from mpi4py ('Ubuntu', '16.04', 'xenial') : rank 1 of 2 
Hello from mpi4py ('Ubuntu', '16.04', 'xenial') : rank 0 of 2
```
</p></details>

## Running a CUDA container on Titan
You should still be in an interactive batch job, if not run the `qsub` command from the previous exercise. 

Create HelloCuda.cu in the current directory with the following format
```
#include <stdio.h>
#include <cuda.h>

// CUDA kernel. Each thread takes care of one element of c
__global__ void hello_cuda() {
  printf("hello from the GPU\n");
}
 
int main( int argc, char* argv[] )
{
  // Execute the kernel
  hello_cuda<<<1, 1>>>();

  cudaDeviceSynchronize(); 

  return 0;
}
```

The CUDA compiler, `nvcc`, has similar basic syntax to gcc, using `mpi.img` compile `HelloCuda.cu` into `HelloCuda.out` and then run 
 on a single node using the launch command `aprun -n 1 <command>`
 
<details> <summary>Expand to see solution</summary><p>
 
Compile
```
$ singularity exec nvcc HelloCuda.cu -o HelloCuda.out
```

And run
```
$ aprun -n 1 singularity exec ./mpi.img ./HelloCuda.out 
```

</p></details>