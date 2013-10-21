{#-
Copyright (c) 2013, Bruno Clermont
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Author: Bruno Clermont <patate@fastmail.cn>
Maintainer: Bruno Clermont <patate@fastmail.cn>

Nagios NRPE check for Backup Server.
-#}
include:
  - nrpe
  - sudo
  - sudo.nrpe
  - apt.nrpe
  - ssh.server.nrpe
  - pip.nrpe
  - cron.nrpe
  - rsyslog.nrpe

/usr/local/bin/check_backups.py:
  file:
    - absent

/usr/lib/nagios/plugins/check_backups.py:
  file:
    - managed
    - user: root
    - group: root
    - mode: 550
    - source: salt://backup/server/nrpe/check.py
    - require:
      - pkg: nagios-nrpe-server

/etc/sudoers.d/nrpe_backups:
  file:
    - managed
    - source: salt://backup/server/nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - template: jinja
    - require:
      - pkg: sudo

/etc/nagios/nrpe.d/backups.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://backup/server/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server
      - file: /etc/sudoers.d/nrpe_backups
      - file: /usr/lib/nagios/plugins/check_backups.py

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/backups.cfg
