#!/bin/bash

set -e
set -u

. /vagrant/settings.conf

yum -y install jenkins
