FROM registry.access.redhat.com/ubi7/ubi

MAINTAINER Mark Sutton <msutton@redhat.com>
LABEL Description="Containerized SUMO (Simulation of Urban MObility)"

ENV SUMO_VERSION 0.31.0
ENV SUMO_HOME /usr/local/share/sumo/
ENV SUMO_USER root

# Copy entitlements
COPY ./etc-pki-entitlement /etc/pki/entitlement

# Copy subscription manager configurations
COPY ./rhsm-conf /etc/rhsm
COPY ./rhsm-ca /etc/rhsm/ca

# Delete /etc/rhsm-host to use entitlements from the build container
RUN rm /etc/rhsm-host && \
    # Initialize /etc/yum.repos.d/redhat.repo
    # See https://access.redhat.com/solutions/1443553
    yum repolist --disablerepo=*

RUN subscription-manager repos \
        --disable=*

RUN curl -o /tmp/epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum -y install /tmp/epel-release-latest-7.noarch.rpm

RUN subscription-manager repos \
        --enable=rhel-7-server-rpms \
        --enable=rhel-7-server-extras-rpms \
        --enable=rhel-7-server-optional-rpms \
        --enable=amq-clients-2-for-rhel-7-server-rpms 

RUN yum-config-manager --enable epel

#RUN yum -y update

RUN mkdir -p /usr/local/share/cmake3/Modules && \
    curl -o /usr/local/share/cmake3/Modules/FindProj.cmake https://raw.githubusercontent.com/qgis/QGIS/master/cmake/FindProj.cmake

RUN yum -y install gcc-c++ git glibc xerces-c xerces-c-devel make proj proj-devel cmake3 libxml2 libxml2-devel libcurl libcurl-devel 

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

RUN yum -y install python-qpid-proton

RUN yum clean all

RUN pushd /opt && git clone https://github.com/complexmind/sumosimulator.git && popd

USER 1000

CMD python /opt/sumosimulator/scripts/sumolistener.py

