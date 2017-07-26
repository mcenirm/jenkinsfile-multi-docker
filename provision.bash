#!/bin/bash

set -e
set -u

. /vagrant/settings.conf

yum -y install yum-utils epel-release

# See https://pkg.jenkins.io/redhat/
wget -nv -N -P /etc/yum.repos.d https://pkg.jenkins.io/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

yum -y install jenkins
