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

 Nagios NRPE check for uWSGI
-#}
include:
  - nrpe
  - sudo
  - git.nrpe
  - nginx.nrpe
  - pip.nrpe
  - ruby.nrpe
  - xml.nrpe
  - python.dev.nrpe
  - rsyslog.nrpe
  - web

/etc/nagios/nrpe.d/uwsgi.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://uwsgi/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server
      - file: /usr/lib/nagios/plugins/check_uwsgi
      - file: /etc/sudoers.d/nrpe_uwsgi

/etc/sudoers.d/nagios_uwsgi:
  file:
    - absent

/etc/sudoers.d/nrpe_uwsgi:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
    - require_in:
      - pkg: nagios-nrpe-server

/usr/local/bin/uwsgi-nagios.sh:
  file:
   - absent

/usr/lib/nagios/plugins/check_uwsgi:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/nrpe/check.jinja2
    - mode: 550
    - user: www-data
    - group: www-data
    - require:
      - pkg: nagios-nrpe-server
      - user: web

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/uwsgi.cfg
