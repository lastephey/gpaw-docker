FROM ubuntu:20.04

WORKDIR /tmp

#ubuntu 20.04 bugfix
ENV DEBIAN_FRONTEND noninteractive

RUN \
    apt-get update               && \
    apt-get install --yes           \
        build-essential             \
        gcc                         \
        gfortran                    \
        libopenmpi-dev              \
        libopenblas-dev             \
        liblapack-dev               \
        libscalapack-openmpi-dev    \
        libxc-dev                   \
        python3-dev                 \
        python3-pip                 \
        wget                     && \
    apt-get clean all


#fftw
RUN \
    wget http://fftw.org/fftw-3.3.9.tar.gz && \
    tar -xvf fftw-3.3.9.tar.gz             && \
    cd fftw-3.3.9                          && \
    ./configure --enable-mpi CFLAGS="-fPIC" FCFLAGS="-fPIC"              && \
    make -j 2 && make install

####libxc
###RUN \
###    wget http://www.tddft.org/programs/libxc/down.php?file=4.3.4/libxc-4.3.4.tar.gz && \
###    tar -xvf down.php?file=4.3.4%2Flibxc-4.3.4.tar.gz                               && \
###    cd libxc-4.3.4/                                                                 && \
###    ./configure CFLAGS="-fPIC" FCFLAGS="-fPIC" --prefix=$HOME/libxc-4.3.4                                     && \
###    make -j 2 && make install

#libvdwxc
RUN \
    wget https://launchpad.net/libvdwxc/stable/0.4.0/+download/libvdwxc-0.4.0.tar.gz && \
    tar -xvf libvdwxc-0.4.0.tar.gz                                                   && \
    cd libvdwxc-0.4.0/                                                               && \
    ./configure CFLAGS="-fPIC" FCFLAGS="-fPIC" --with-mpi=/usr/ --prefix=/tmp/libvdwxc-0.4.0                 && \
    make -j 2 && make install

#elpa (have to figure out how to enable avx instructions, it won't work on my laptop) maybe podman?
#make this library build at runtime? hmm
RUN \
    wget https://elpa.mpcdf.mpg.de/html/Releases/2020.11.001/elpa-2020.11.001.tar.gz      && \
    tar -xvf elpa-2020.11.001.tar.gz                                                 && \
    cd elpa-2020.11.001                                                              && \
    ./configure CC="mpicc" --disable-sse --disable-avx --disable-avx2 --disable-avx512 --prefix=/tmp/elpa-2020.11.001 && \
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

ADD siteconfig.py /tmp/gpaw-20.10.0/siteconfig.py

RUN \
    cd /tmp/gpaw-20.10.0 && \
    python setup.py install



