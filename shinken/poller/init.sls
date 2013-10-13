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

 Shinken Poller state.

 The poller daemon launches check plugins as requested by schedulers. When the
 check is finished it returns the result to the schedulers. Pollers can be
 tagged for specialized checks (ex. Windows versus Unix, customer A versus
 customer B, DMZ) There can be many pollers for load-balancing or hot standby
 spare roles.
-#}
include:
  - shinken
  - apt
  - nrpe

nagios-nrpe-plugin:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
      - pkg: nagios-plugins

shinken-poller:
  file:
    - managed
    - name: /etc/init/shinken-poller.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://shinken/upstart.jinja2
    - context:
      shinken_component: poller
  service:
    - running
    - enable: True
    - order: 50
    - require:
      - file: /var/lib/shinken
      - file: /var/log/shinken
      - pkg: nagios-nrpe-plugin
    - watch:
      - module: shinken
      - file: /etc/shinken/poller.conf
      - file: shinken-poller

/etc/shinken/poller.conf:
  file:
    - managed
    - template: jinja
    - user: shinken
    - group: shinken
    - mode: 440
    - source: salt://shinken/config.jinja2
    - context:
      shinken_component: poller
    - require:
      - virtualenv: shinken
      - user: shinken
