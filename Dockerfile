FROM debian:stretch-slim

WORKDIR /app

ARG SBCL_VERSION=1.5.1
ARG SBCL_INSTALL_DIR=sbcl-$SBCL_VERSION-x86-64-linux
ARG SBCL_TAR=$SBCL_INSTALL_DIR-binary.tar
ARG SBCL_BZIP=$SBCL_TAR.bz2

# Required packages
RUN apt-get update && \
    apt-get install -y \
            bzip2 \
            git \
            libssl-dev \
            make \
            wget \
    && \
    rm -rf /var/lib/apt/lists/*

# Install SBCL (should confirm checksum)
RUN wget http://prdownloads.sourceforge.net/sbcl/$SBCL_BZIP && \
    bzip2 -d $SBCL_BZIP && \
    tar xf $SBCL_TAR && \
    cd $SBCL_INSTALL_DIR && \
    sh install.sh && \
    cd $WORKDIR && \
    rm -rf $SBCL_TAR $SBCL_INSTALL_DIR

# Install Quicklisp (should confirm checksum)
RUN mkdir -p /usr/local/quicklisp && \
    wget https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --load quicklisp.lisp \
         --eval '(quicklisp-quickstart:install :path "/usr/local/lib/quicklisp")' && \
    rm quicklisp.lisp

COPY sbclrc /root/.sbclrc

# Start Lisp
#ENTRYPOINT ["/usr/local/bin/sbcl"]
