FROM debian:buster as builder
USER root
ARG DEBIAN_FRONTEND="noninteractive"
ARG VERSION=v2.3.4
ARG MAKE_THREADS=1
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
           git \
           build-essential \
           zlib1g-dev  \
           make \
           cmake \
           g++ \
           gcc \
           clang \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8"
RUN mkdir /tmp/antsbuild && cd /tmp/antsbuild \
    && git clone https://github.com/ANTsX/ANTs.git && cd ANTs && git checkout $VERSION
RUN mkdir /tmp/antsbuild/build && cd /tmp/antsbuild/build \
    && cmake \
      -DCMAKE_INSTALL_PREFIX=/opt/ants \
      -DBUILD_SHARED_LIBS=OFF \
      -DUSE_VTK=OFF \
      -DSuperBuild_ANTS_USE_GIT_PROTOCOL=OFF \
      -DBUILD_TESTING=OFF \
      -DRUN_LONG_TESTS=OFF \
      -DRUN_SHORT_TESTS=OFF \
      /tmp/antsbuild/ANTs 2>&1 | tee cmake.log \
      && make -j $MAKE_THREADS 2>&1 | tee build.log
RUN cd /tmp/antsbuild/build/ANTS-build \
    && make install 2>&1 | tee install.log
RUN rm -rf /tmp/antsbuild
RUN apt-get remove -y -q --purge  \
            build-essential \
            zlib1g-dev  \
            make \
            cmake \
            g++-8 \
            gcc-8 \
            clang-7 \
    && apt-get autoremove -y -q --purge \
    && apt-get autoclean -y -q

FROM debian:buster-slim
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
           git \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* \
     && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
     && dpkg-reconfigure --frontend=noninteractive locales \
     && update-locale LANG="en_US.UTF-8"
COPY --from=builder /opt/ants /opt/ants
RUN echo $(/opt/ants/bin/antsRegistration --version)
ENV ANTSPATH="/opt/ants" \
    PATH="/opt/ants/bin:$PATH"
ENV SHELL=/bin/bash
CMD ["/bin/bash"]
