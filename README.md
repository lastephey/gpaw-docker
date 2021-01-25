# gpaw-docker

Progress towards building a GPAW docker container

Aim is to run on NERSC Cori but since it's a container, hopefully it can run anywhere

GPAW project: https://wiki.fysik.dtu.dk/gpaw/index.html

Also using:

- OpenMPI
- BLAS
- LAPACK
- SCALAPACK
- libxc
- libvdwxc
- ASE
- fftw
- elpa

# Pull container from dockerhub:

https://hub.docker.com/repository/docker/stephey/gpaw

```
docker pull stephey/gpaw:1.0
```

# Testing continaer locally

```
docker run --rm -it --user 500 -cap-add=SYS_PTRACE stephey/gpaw:1.0 /bin/bash
```

`/bin/bash` will open a bash shell inside the container for interactive testing

`--user 500` runs with user-level permissions which are required for Shifter

`--cap-add=SYS_PTRACE` is required to silence openmpi messages in docker: https://github.com/open-mpi/ompi/issues/4948

# Making changes

You can see the Dockerfile for the build instructions. If you edit the
Dockerfile, you'll need to rebuild the container with something like:

```
docker build -t stephey/gpaw:1.0 .
```

You can name and tag the container however you like.

The Dockerfile requires the siteconfig.py file to be alongside the Dockerfile
at build time. It copies this file into the container and uses it to make
configuration adjustments.

# Can use shifter to pull onto Cori:


```
shifterimg pull docker:stephey/gpaw:1.0
```

You'll run the container on Cori using Shifter (very much like Docker but
without root privleges.)

How to use shifter: https://docs.nersc.gov/development/shifter/how-to-use/
