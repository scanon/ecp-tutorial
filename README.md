# Container Computing for HPC and Scientific Workflows

Containers are rapidly gaining traction in HPC because they promise significantly greater software flexibility, reliability, and portability for users. Tools like Docker, and Shifter, Charliecloud and Singularity enable a new paradigm for scientific and technical computing. However, to fully unlock its potential, users and administrators need to understand how to utilize these new approaches.  This tutorial includes an overview of linux container technology, options for containers in HPC environments and use cases they are enabling, as well as an interactive period to try out containers on HPC resources. A key goal of the tutorial is to provide participants with hands-on experience with linux containers on HPC resources and how this can enable their scientific workflows.

The content for the handouts and slides will be posted and updated at [https://github.com/scanon/ecp-tutorial](https://github.com/scanon/ecp-tutorial).

## Prerequisites

This is hands-on tutorial. Participants should bring a laptop and pre-install Docker in advance to make the best use of time during the tutorial (see the [Setup](setup.md) section for details). Users can also create a docker account in advance at [https://cloud.docker.com/](https://cloud.docker.com/). This account will be needed to create images on docker cloud and dockerhub. In addition, users should install an ssh client for their operating system so they can access the HPC resources we will use for the Shifter portion of the tutorials.

For more detailed instructions, see [Setup](setup.md).

## Communication
Please raise your hand if you need assistance. You can also ask questions on this [Google Doc](https://docs.google.com/document/d/1UYGPcGbq_wrvktBVSp5k41cQLkpap1WeNq_P3z1eT6s/edit?usp=sharing).

## Agenda

- 13:30: [Introduction and Getting Started](00-intro.md)
    - Overview of linux containers
    - Building container images
    - Managing images Containers
    - [Hands-on Basics](01-hands-on.md)
      - [Pulling and running an existing image](01-hands-on.md#pulling-and-running-an-existing-image)
      - [Making changes and committing them](01-hands-on.md#making-changes-and-committing-them)
      - [Creating and building a Dockerfile](01-hands-on.md#creating-and-building-a-dockerfile)
      - [Pushing a Dockerfile to dockerhub](01-hands-on.md#pushing-a-dockerfile-to-dockerhub)
      - [Intro to Singularity](01-hands-on.md#intro-to-singularity)
      - [Singularity Dockerfile](01-hands-on.md#singularity-dockerfile)
      - [Running Docker images with Singularity](01-hands-on.md#running-docker-images-with-singularity)
      - [Creating and building a Singularity recipe](01-hands-on.md#creating-and-building-a-singularity-recipe)
      - [Running in a Singularity container](01-hands-on.md#running-in-a-singularity-container)
- 14:45: Break
    - Distribute of NERSC and ORNL logins. **Please obtain logins from tutorial staff during the break**
- 15:00: [Containers and HPC](02-hpc.md)
    - Common Issues for HPC containers
    - Review of HPC Container Technologies
      - Charliecloud
      - Shifter
      - Singularity
    - [Hands-on HPC](03-hands-on.md)
      - Using Charliecloud (NERSC)
      - Using Shifter (NERSC)
      - [Using Singularity (ORNL)](03-hands-on.md#logging-into-olcf)
    - [Advanced Use Cases](04-advanced.md)
      - MPI versions and hardware access
      - Considerations for Charliecloud, Shifter and Singularity
      - Considerations for non-x86 architectures
    - [End User Examples](05-use-cases.md) (time permitting)
- 17:00: [Wrap-Up](06-wrap-up.md)
