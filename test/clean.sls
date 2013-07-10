{#
 This state take a salt-minion and remove all debian packages that aren't
 required to run only it.
 Useful to identify if dependencies are missing.
#}

include:
  - deborphan
  - ttys
  - kernel_modules

{%- set root_info = salt['user.info']('root') -%}

{#-
 You can't uninstall sudo, if no root password
 #}
root:
  user:
    - present
    - shell: {{ root_info['shell'] }}
    - home: {{ root_info['home'] }}
    - uid: {{ root_info['uid'] }}
    - gid: {{ root_info['gid'] }}
    - enforce_password: True
    {# password: root #}
    - password: $6$FAsR0aKa$JoJGdUhaFGY1YxNEBDc8CEJig4L2GpAuAD8mP9UHhjViiJxJC2BTm9vFceEFDbB/yru5dEzLGHAssXthWNvON.

clean_pkg:
  pkg:
    - purged
    - names:
      - accountsservice
      - acpid
      - anacron
      - apparmor
      - apparmor-utils
      - apport
      - apport-symptoms
      - apt-transport-https
      - apt-utils
      - apt-xapian-index
      - aptitude
      - at
      - bc
      - bind9-host
      - busybox-static
      - byobu
      - ca-certificates
      - cloud-init
      - cloud-initramfs-growroot
      - cloud-initramfs-rescuevol
      - cloud-utils
      - command-not-found
      - command-not-found-data
      - console-data
      - console-setup
      - cpp
      - cpp-4.6
      - cron
      - curl
      - dbus
      - dmidecode
      - dnsutils
      - dosfstools
      - dpkg-dev
      - ed
      - eject
      - euca2ools
      - fonts-ubuntu-font-family-console
      - friendly-recovery
      - ftp
      - fuse
      - fuse-utils
      - g++
      - gcc
      - geoip-database
      - gir1.2-glib-2.0
      - groff-base
      - hdparm
      - info
      - install-info
      - installation-report
      - iptables
      - iputils-ping
      - iputils-tracepath
      - irqbalance
      - iso-codes
      - iw
      - kbd
      - keyboard-configuration
      - krb5-locales
      - landscape-client
      - landscape-common
      - language-selector-common
      - laptop-detect
      - less
      - libapt-inst1.4
      - libclass-accessor-perl
      - libclass-isa-perl
      - libcurl3
      - libcurl3-gnutls
      - libdpkg-perl
      - liberror-perl
      - libio-string-perl
      - libjs-jquery
      - liblockfile-bin
      - libparse-debianchangelog-perl
      - libsub-name-perl
      - libswitch-perl
      - libtimedate-perl
      - libx11-data
      - locales
      - lockfile-progs
      - logrotate
      - lshw
      - lsof
      - ltrace
      - man-db
      - manpages
      - memtest86+
      - mlocate
      - mtr-tiny
      - nano
      - netcat-openbsd
      - ntfs-3g
      - ntpdate
      - openssh-client
      - openssh-server
      - openssl
      - os-prober
      - parted
      - patch
      - pciutils
      - perl
      - perl-modules
      - popularity-contest
      - powermgmt-base
      - ppp
      - pppconfig
      - pppoeconf
      - psmisc
      - python-apport
      - python-apt
      - python-apt-common
      - python-boto
      - python-chardet
      - python-cheetah
      - python-configobj
      - python-dbus
      - python-dbus-dev
      - python-debian
      - python-gdbm
      - python-gi
      - python-gnupginterface
      - python-httplib2
      - python-keyring
      - python-launchpadlib
      - python-lazr.restfulclient
      - python-lazr.uri
      - python-newt
      - python-oauth
      - python-openssl
      - python-pam
      - python-paramiko
      - python-problem-report
      - python-pycurl
      - python-serial
      - python-simplejson
      - python-software-properties
      - python-twisted-bin
      - python-twisted-core
      - python-twisted-names
      - python-twisted-web
      - python-wadllib
      - python-xapian
      - python-zope.interface
      - rsync
      - rsyslog
      - screen
      - sgml-base
      - ssh-import-id
      - strace
      - sudo
      - tasksel
      - tasksel-data
      - tcpd
      - tcpdump
      - telnet
      - time
      - tmux
      - ubuntu-minimal
      - ubuntu-minimal
      - ubuntu-standard
      - ubuntu-standard
      - ufw
      - unattended-upgrades
      - update-manager-core
      - update-notifier-common
      - ureadahead
      - usbutils
      - uuid-runtime
      - vim
      - vim-common
      - vim-runtime
      - vim-tiny
      - w3m
      - wget
      - whiptail
      - whoopsie
      - wireless-tools
      - wpasupplicant
      - xauth
      - xkb-data
      - xml-core
    - require:
      - user: root

{% for service in ('acpid', 'console-setup', 'dbus', 'whoopsie') %}
/var/log/upstart/{{ service }}.log:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{% endfor %}

{% for pkg in ('cloud-init', 'ufw') %}
/var/log/{{ pkg }}.log:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{% endfor %}

{% for file in ('/tmp/bootstrap-salt.log', '/var/lib/cloud', '/var/cache/apt-xapian-index') %}
{{ file }}:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{% endfor %}

{% if salt['cmd.has_exec']('deborphan') %}
{% for pkg in salt['cmd.run']('deborphan').split("\n") %}
{% if pkg != '' %}
{% if loop.first %}
orphans:
  pkg:
    - purged
    - require:
      - pkg: clean_pkg
    - names:
{% endif %}
      -  {{ pkg }}
{% endif %}
{% endfor %}
{% endif %}
