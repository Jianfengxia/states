#!/bin/bash
# {{ salt['pillar.get']('message_do_not_modify') }}
# Use of this is governed by a license that can be found in doc/license.rst.

set -e

# TODO: rewrite in Python
if [ -d /root/salt/states/salt/minion ]; then
    LOCAL_MODE=1
else
    LOCAL_MODE=0
fi

if [ -z "$1" ]; then
    echo "Usage: bootstrap.sh minion-id"
    exit 1
fi
if [ $LOCAL_MODE -eq 0 ] && [ -z "$2" ]; then
    echo "Usage: bootstrap.sh minion-id master-host-or-addr"
    exit 1
fi

# some modules/states require HOME environment variable
# if current HOME is not set to HOME of user who run salt (often is root),
# software may misbehave.

root_home=$(eval echo "~root")
if [ "$HOME" != "$root_home" ]; then
    echo "Current \$HOME set to $HOME. Expected '$root_home'. Please set it correctly (maybe run sudo with -H option)"
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends python-software-properties python-pip
pip install --upgrade pip==6.0.8
/usr/local/bin/pip install requests==2.4.3 raven==4.1.1
echo "deb http://archive.robotinfra.com/mirror/salt/2014.1.10-1/ `lsb_release -c -s` main" > /etc/apt/sources.list.d/saltstack-salt-`lsb_release -c -s`.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0E27C0A6
apt-get update
apt-get install -y --force-yes salt-minion
# end of section

if [ $LOCAL_MODE -eq 1 ]; then
    echo "Salt master-less (local) mode"
    echo $1 > /etc/hostname
    hostname `cat /etc/hostname`
    echo """master: 127.0.0.1
id: $1
mysql.default_file: '/etc/mysql/debian.cnf'
file_log_level: debug
file_client: local
file_roots:
  base:
    - /root/salt/states
pillar_roots:
  base:
    - /root/salt/pillar""" > /etc/salt/minion

    salt-call state.sls salt.patch_salt
    restart salt-minion
    salt-call saltutil.sync_all
else
    echo """id: $1
log_level: debug
master: $2""" > /etc/salt/minion
    restart salt-minion
    salt-call state.sls salt.patch_salt
    restart salt-minion
fi
