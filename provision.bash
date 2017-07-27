#!/bin/bash

set -e
set -u

. /vagrant/settings.conf

PATH=/vagrant/utils:${PATH}

provision_packages yum-utils epel-release

# See https://pkg.jenkins.io/redhat/
wget -nv -N -P /etc/yum.repos.d https://pkg.jenkins.io/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

provision_packages java-1.8.0-openjdk-devel git docker
if [ ! -f /etc/systemd/system/docker.service ] ; then
  systemctl disable --now docker
  sed -e '/^ExecReload=/s#.*#ExecStartPost=/usr/bin/chown dockerroot:dockerroot /var/run/docker.sock\n&#' < /usr/lib/systemd/system/docker.service > /etc/systemd/system/docker.service
fi
systemctl enable --now docker

provision_packages jenkins
usermod -a -G dockerroot jenkins
systemctl start jenkins

initialAdminPassword=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

cat <<EOF
== http://localhost:8080/
 * Unlock Jenkins
   | Administrator password | $initialAdminPassword |
 * Customize Jenkins
   [ Install suggested plugins ]
 * Create First Admin User
   [ Continue as admin ]
 * Jenkins is ready!
   [ Start using Jenkins ]

== http://localhost:8080/pluginManager/available
   (Optional) Use "Filter" to search for "blue ocean"
   Check box for "Blue Ocean"
   [ Download now and install after restart ]
   Check box for "Restart Jenkins when installation is complete and no jobs are running"
   Wait a few minutes for Jenkins to restart

== http://localhost:8080/blue/create-pipeline
   | Where do you store your code? | Git            |
   | Repository URL                | /vagrant       |
   | Credentials                   | System Default |
EOF
