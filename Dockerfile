FROM registry.access.redhat.com/rhel7

MAINTAINER Mark Sutton <msutton@redhat.com>
LABEL Description="Containerized SUMO (Simulation of Urban MObility)"

ENV SUMO_VERSION 0.31.0
ENV SUMO_HOME /usr/local/share/sumo/
ENV SUMO_USER root

RUN yum -y update

RUN mkdir -p /usr/local/share/cmake3/Modules && \
    curl -o /usr/local/share/cmake3/Modules/FindProj.cmake https://raw.githubusercontent.com/qgis/QGIS/master/cmake/FindProj.cmake && \
    curl -o /tmp/epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y --disablerepo=rhel-7-server-htb-rpms install /tmp/epel-release-latest-7.noarch.rpm

RUN yum -y \
        --disablerepo=rhel-7-server-htb-rpms \
        --enablerepo=rhel-7-server-optional-rpms \
        install gcc-c++ git glibc xerces-c xerces-c-devel make proj proj-devel cmake3 libxml2 libxml2-devel libcurl libcurl-devel 

RUN cd /root && \
    echo "INSTALLING SUMO..." && \
    git clone --recursive https://github.com/eclipse/sumo && \
    cd sumo && \
    git fetch origin refs/replace/*:refs/replace/* && \
    mkdir -p build/sumo-build && \
    cd build/sumo-build && \
    cmake3 ../.. && \
    make -j4 && \
    make install && \
    ldconfig && \
    useradd -m -s /bin/bash -u 1000 sumo && \
    cd /root && \
    rm -rf sumo

RUN yum -y --enablerepo=rhel-7-server-optional-rpms --enablerepo=amq-clients-2-for-rhel-7-server-rpms \
    install python-qpid-proton

RUN yum clean all

USER 1000


