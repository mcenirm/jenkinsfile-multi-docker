#!/bin/bash

set -e
set -u

. /vagrant/settings.conf

PATH=/vagrant/utils:${PATH}

provision_packages yum-utils epel-release

# See https://pkg.jenkins.io/redhat/
wget -nv -N -P /etc/yum.repos.d https://pkg.jenkins.io/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

provision_packages java-1.8.0-openjdk-devel

provision_packages jenkins
