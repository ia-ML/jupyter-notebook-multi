# Use the Jupyter Data Science Notebook as the base image
# It already includes Python, R, and Julia
FROM jupyter/datascience-notebook:latest

USER root

# System dependencies and tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    wget \
    git \
    openjdk-11-jdk \
    golang-go \
    libzmq3-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN chown -R jovyan:users /home/jovyan && \
    chmod -R 755 /home/jovyan

USER jovyan


# C kernel
RUN pip install jupyter-c-kernel
RUN install_c_kernel --user

# C++ kernel
RUN conda install -c conda-forge xeus-cling

USER root

# Java kernel (IJava)
RUN git clone https://github.com/SpencerPark/IJava.git
RUN cd IJava && ./gradlew installKernel

# JavaScript kernel
RUN npm install -g ijavascript
RUN ijsinstall --install=global


# # Fortran kernel
# # https://github.com/Carltoffel/jupyter-fortran-kernel/
RUN git clone https://github.com/Carltoffel/jupyter-fortran-kernel.git && \
    cd jupyter-fortran-kernel && \
    python setup.py install  && \
    install_fortran_kernel


# # Go kernel
# Install Go
ENV GO_VERSION=1.17.3
ENV GO_OS=linux
ENV GO_ARCH=amd64
RUN wget https://dl.google.com/go/go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz -O go.tar.gz && \
    tar -xvf go.tar.gz && \
    mv go /usr/local && \
    rm go.tar.gz
# Set environment variables necessary for Go
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
# Switch back to jupyter user to avoid permission issues

# Install gophernotes
RUN go install github.com/gopherdata/gophernotes@v0.7.5
# Set up the kernel
RUN mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
    cd ~/.local/share/jupyter/kernels/gophernotes && \
    cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.5/kernel/* "." && \
    chmod +w ./kernel.json && \
    sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json

USER jovyan

# TODO: 
# Add GPU Support 

# Switch back to the jupyter user
USER $NB_UID

