FROM ubuntu:20.4

RUN mkdir build

WORKDIR /build

ubuntu 20.04 bugfix
ENV DEBIAN_FRONTEND noninteractive

RUN \
    apt-get update               && \
    apt-get install --yes           \
        build-essential             \
        gcc                         \
        gfortran                    \
        libopenblas-dev             \
        liblapack-dev               \
        libscalapack-mpich-dev      \
        libxc-dev                   \
        python3-dev                 \
        python3-pip                 \
        wget                     && \
    apt-get clean all

#mpich
ARG mpich=3.3
ARG mpich_prefix=mpich-$mpich

RUN \
    wget https://www.mpich.org/static/downloads/$mpich/$mpich_prefix.tar.gz && \
    tar xvzf $mpich_prefix.tar.gz                                           && \
    cd $mpich_prefix                                                        && \
    ./configure                                                             && \
    make -j 4                                                               && \
    make install                                                            && \
    make clean                                                              && \
    cd ..                                                                   && \
    rm -rf $mpich_prefix

RUN /sbin/ldconfig

#scalapack and elpa need blacs
#just copy in our edited Bmake.inc
RUN \
    wget http://www.netlib.org/blacs/mpiblacs.tgz && \
    tar -xzvf mpiblacs.tgz && \
    wget http://www.netlib.org/blacs/mpiblacs-patch03.tgz && \
    tar -xzvf mpiblacs-patch03.tgz

ADD Bmake.inc /build/BLACS/Bmake.inc

RUN cd /build/BLACS/TESTING && make

####scalapack
####apparently openmpi 4.0+ is broken in scalapack, here's a patch
####patch info: https://gitlab.com/arm-hpc/packages/-/wikis/packages/scalapack#open-mpi-40
####patch source: https://github.com/gentoo/sci/issues/911
###RUN for i in `grep -rlI "MPI_Type_struct" *`; do sed -i 's/MPI_Type_struct/MPI_Type_create_struct/g' $i; done
###
####their setup isn't controlled by flags so we have to copy in an edited makefile
####it's not great but ok
###RUN \
###    wget http://www.netlib.org/scalapack/scalapack-2.1.0.tgz && \
###    tar -xvf scalapack-2.1.0.tgz
###ADD SLmake.inc /build/scalapack-2.1.0/SLmake.inc
###RUN cd scalapack-2.1.0 && make -j 2

#fftw
RUN \
    wget http://fftw.org/fftw-3.3.9.tar.gz && \
    tar -xvf fftw-3.3.9.tar.gz             && \
    cd fftw-3.3.9                          && \
    ./configure --enable-mpi CFLAGS="-fPIC" FCFLAGS="-fPIC"              && \
    make -j 2 && make install

#libvdwxc
RUN \
    wget https://launchpad.net/libvdwxc/stable/0.4.0/+download/libvdwxc-0.4.0.tar.gz && \
    tar -xvf libvdwxc-0.4.0.tar.gz                                                   && \
    cd libvdwxc-0.4.0/                                                               && \
    ./configure CFLAGS="-fPIC" FCFLAGS="-fPIC" --with-mpi=/usr/ --prefix=/build/libvdwxc-0.4.0                 && \
    make -j 2 && make install

#elpa (have to figure out how to enable avx instructions, it won't work on my laptop) maybe podman?
#make this library build at runtime? hmm
RUN \
    wget https://elpa.mpcdf.mpg.de/html/Releases/2020.11.001/elpa-2020.11.001.tar.gz      && \
    tar -xvf elpa-2020.11.001.tar.gz                                                 && \
    cd elpa-2020.11.001                                                              && \
    ./configure CC="mpicc" --disable-sse --disable-avx --disable-avx2 --disable-avx512 --prefix=/build/elpa-2020.11.001 && \
    make -j 2 && make install

#alias python3 to python
RUN ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip

RUN python -m pip install --upgrade pip
RUN python -m pip install numpy==1.19 scipy==1.5 pytest pytest-xdist

#let's try ase manually too
RUN \
    wget https://files.pythonhosted.org/packages/33/b4/be18d165db7af1632fbfc8dcb22b3c8a29bb56de20bf556f46aec132c8a3/ase-3.21.1.tar.gz#sha256=78b01d88529d5f604e76bc64be102d48f058ca50faad72ac740d717545711c7b && \
    tar -xvf ase-3.21.1.tar.gz && \
    ln -s ase-3.21.1 ase       && \
    cd ase-3.21.1              && \
    python setup.py install

ENV /tmp/ase PYTHONPATH

#have to install gpaw from source so we can modify siteconfig to point to our custom libraries

RUN \
    wget https://files.pythonhosted.org/packages/16/62/cf268b7ea00581bf2f735f6abed89ab13f4effc73e17763dc1edd92fd465/gpaw-20.10.0.tar.gz#sha256=77c3d3918f5cc118e448f8063af4807d163b31d502067f5cbe31fc756eb3971d && \
    tar -xvf gpaw-20.10.0.tar.gz

ADD siteconfig.py /build/gpaw-20.10.0/siteconfig.py

RUN \
    cd /build/gpaw-20.10.0 && \
    python setup.py install



