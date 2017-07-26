#!/bin/bash

set -e
set -u

. /vagrant/settings.conf

yum -y install yum-utils epel-release
yum -y install jenkins
