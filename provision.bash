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
systemctl start jenkins

if ! grep -q '^localhost ' /etc/ssh/ssh_known_hosts ; then
  ssh-keyscan localhost >> /etc/ssh/ssh_known_hosts
fi
if ! grep -q localdocker ~jenkins/.ssh/id-localdocker.pub ; then
  rm -f ~jenkins/.ssh/id-localdocker
  sudo -u jenkins ssh-keygen -N '' -C localdocker -f ~jenkins/.ssh/id-localdocker
fi

if ! getent passwd jenkins-docker > /dev/null ; then
  useradd -M -r -c 'Jenkins slave for using Docker' -d /var/lib/jenkins-docker jenkins-docker
fi
install -o jenkins-docker -g jenkins-docker -m 0700 -d ~jenkins-docker ~jenkins-docker/.ssh
install -o jenkins-docker -g jenkins-docker -m 0600 ~jenkins/.ssh/id-localdocker.pub ~jenkins-docker/.ssh/authorized_keys

sudo -u jenkins ssh -o LogLevel=QUIET -i ~jenkins/.ssh/id-localdocker jenkins-docker@localhost id

initialAdminPassword=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

cat <<EOF
== http://localhost:8080/
== initial admin password:  $initialAdminPassword

== http://localhost:8080/credentials/store/system/domain/_/newCredentials
   | Kind        | SSH Username with private key        |
   | Scope       | System (Jenkins and nodes only)      |
   | Username    | jenkins-docker                       |
   | Private Key | From a file on Jenkins master        |
   | File        | /var/lib/jenkins/.ssh/id-localdocker |
   | Passphrase  | (blank)                              |
   | ID          | localdocker                          |
   | Description | Local docker slave                   |

== http://localhost:8080/computer/new
   | Node name                      | localdocker                                               |
   | (type)                         | Permanent Agent                                           |
   ----------------------------------------------------------------------------------------------
   | Name                           | localdocker                                               |
   | Description                    | Local docker                                              |
   | # of executors                 | 1                                                         |
   | Remote root directory          | /var/lib/jenkins-docker/jenkins-root                      |
   | Labels                         | docker                                                    |
   | Usage                          | Only build jobs with label expressions matching this node |
   | Launch method                  | Launch slave agents via SSH                               |
   | Host                           | localhost                                                 |
   | Credentials                    | jenkins-docker (Local docker slave)                       |
   | Host Key Verification Strategy | Known hosts file Verification Strategy                    |
   | Availability                   | Keep this agent online as much as possible                |
   | Environment variables          | (unchecked)                                               |
   | Tool Locations                 | (unchecked)                                               |

== http://localhost:8080/computer/localdocker/log
EOF
