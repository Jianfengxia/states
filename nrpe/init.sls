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

Author: Bruno Clermont <bruno@robotinfra.com>
Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>
-#}
include:
  - apt
{#- include $formula.nrpe here as this is root of all nrpe SLSes,
    there is no nrpe.nrpe to do that as other formulas.
    Although, this looks recursive as apt.nrpe includes nrpe but Salt
    can handle that properly #}
  - apt.nrpe
  - bash
  - bash.nrpe
  - cron
  - cron.nrpe
  - hostname
  - local
{% if salt['pillar.get']('graphite_address', False) %}
  - nrpe.diamond
{% endif %}
  - pip
  - pip.nrpe
  - python.dev
  - rsyslog
  - rsyslog.nrpe
  - ssh.client
  - sudo
  - sudo.nrpe
  - virtualenv
  - virtualenv.nrpe

{#- TODO: remove that statement in >= 2014-04 #}
/usr/local/nagiosplugin:
  file:
    - absent

{#- TODO: remove that statement in >= 2014-04 #}
{{ opts['cachedir'] }}/nagiosplugin-requirements.txt:
  file:
    - absent

{#- TODO: remove that statement in >= 2014-04 #}
/usr/local/nagios/nagiosplugin-requirements.txt:
  file:
    - absent

{#- all new config files are generated by _state/monitoring and do not
    contains `-` or '_' #}

{%- for filepath in salt['file.find']('/etc/nagios/nrpe.d', name='*-*|*_*', type='f') %}
nrpe_remove_old_config_files_{{ filepath }}:
  file:
    - absent
    - name: {{ filepath }}
    - require:
      - pkg: nagios-nrpe-server
    - watch_in:
      - service: nagios-nrpe-server
{%- endfor %}

/etc/nagios/python.yml:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/python.jinja2
    - user: root
    - group: nagios
    - mode: 440
    - require:
      - pkg: nagios-nrpe-server

nrpe-virtualenv:
  {# remove system-wide nagiosplugin, only use one in our nrpe-virtualenv #}
  pip:
    - removed
    - name: nagiosplugin
    - require:
      - module: pip
  virtualenv:
    - manage
    - upgrade: True
    {#- some check need import salt code #}
    - system_site_packages: True
    - name: /usr/local/nagios
    - require:
      - module: virtualenv
      - pip: nrpe-virtualenv
      - file: /usr/local
  file:
    - managed
    - name: /usr/local/nagios/salt-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://nrpe/requirements.jinja2
    - require:
      - virtualenv: nrpe-virtualenv
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/nagios
    - requirements: /usr/local/nagios/salt-requirements.txt
    - require:
      - virtualenv: nrpe-virtualenv
    - watch:
      - file: nrpe-virtualenv
      - pkg: nrpe-virtualenv
      - pkg: python-dev
  pkg:
    - installed
    - name: libyaml-dev {#- PyYAML needs this pkg #}

/usr/local/nagios/src:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755
    - require:
      - virtualenv: nrpe-virtualenv

{#- hack for making sure that above virtualenv is used system_site_packages
    this only neccessary for existing virtualenv because the `virtualenv`
    state module does not support that properly #}
/usr/local/nagios/local/lib/python2.7/no-global-site-packages.txt:
  file:
    - absent
    - require:
      - virtualenv: nrpe-virtualenv
    - watch_in:
      - module: nrpe-virtualenv

nagios-plugins:
  pkg:
    - installed
    - pkgs:
      - nagios-plugins-standard
      - nagios-plugins-basic

/etc/nagios/nrpe_local.cfg:
  file:
    - absent

/etc/nagios/nrpe.d/000.nagios.servers.cfg:
  file:
    - absent

nagios-nrpe-server:
{#- all states that require nrpe should require this state or
service: nagios-nrpe-server #}
  pkg:
    - latest
    - require:
      - pkg: nagios-plugins
      - cmd: apt_sources
      - module: nrpe-virtualenv
      - file: bash
  group:
    - present
    - name: nagios
  user:
    - present
    - name: nagios
    - shell: /bin/false
    - require:
      - pkg: nagios-nrpe-server
      - group: nagios-nrpe-server
  file:
    - managed
    - name: /etc/nagios/nrpe.cfg
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nrpe/server.jinja2
    - require:
      - pkg: nagios-nrpe-server
      - file: /usr/lib/nagios/plugins/check_memory.py
  service:
    - running
    - enable: True
    - order: 50
    - require:
      - file: /etc/nagios/python.yml
    - watch:
      - pkg: nagios-nrpe-server
      - file: nagios-nrpe-server
      - file: /etc/nagios/nrpe_local.cfg
      - file: /etc/nagios/nrpe.d/000.nagios.servers.cfg

{%- from 'macros.jinja2' import manage_pid with context %}
{%- call manage_pid('/var/run/nagios/nrpe.pid', 'nagios', 'nagios', 'nagios-nrpe-server') %}
- pkg: nagios-nrpe-server
{%- endcall %}

{#- Change /usr/local/nagios owner #}
/usr/local/nagios:
  file:
    - directory
    - user: nagios
    - group: nagios
    - mode: 750
    - require:
      - pkg: nagios-nrpe-server

/usr/local/nagios/bin/passive_check.py:
  file:
    - absent

/usr/lib/nagios/plugins/check_domain.sh:
  file:
    - managed
    - source: salt://nrpe/check_domain.sh
    - user: nagios
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server

{#- TODO: remove that statement in >= 2014-04 #}
/usr/local/bin/check_memory.py:
  file:
    - absent

/usr/lib/nagios/plugins/check_memory.py:
  file:
    - managed
    - source: salt://nrpe/check.py
    - user: nagios
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/usr/lib/nagios/plugins/check_oom.py:
  file:
    - managed
    - source: salt://nrpe/check_oom.py
    - user: nagios
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/sudoers.d/nrpe_oom:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
    - require_in:
      - file: nsca-nrpe

/etc/nagios/nsca.conf:
  file:
    - absent

/etc/nagios/nsca.d:
  file:
    - directory
    - user: nagios
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server

/etc/nagios/nsca.yaml:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/nsca.jinja2
    - user: nagios
    - group: nagios
    - mode: 440
    - require:
      - pkg: nagios-nrpe-server
    - context:
        daemon_user: nagios
        daemon_group: nagios

/etc/send_nsca.conf:
  file:
    - absent

/usr/local/nagios/bin/nsca_passive:
  file:
    - managed
    - source: salt://nrpe/nsca_passive.py
    - mode: 500
    - user: nagios
    - group: nagios
    - require:
      - module: nrpe-virtualenv
      - file: /etc/nagios/nsca.yaml
      - file: /etc/nagios/nsca.d

nsca_passive:
  file:
    - managed
    - name: /etc/init/nsca_passive.conf
    - source: salt://nrpe/upstart.jinja2
    - user: root
    - group: root
    - mode: 400
    - template: jinja
  service:
    - running
    - require:
      - service: rsyslog
      - pkg: nagios-nrpe-server
      - file: /etc/nagios/python.yml
    - watch:
      - file: nsca_passive
      - file: /usr/local/nagios/bin/nsca_passive
      - module: nrpe-virtualenv
      - file: /etc/nagios/nsca.yaml
      - file: /etc/nagios/nsca.d
      - file: hostname

{% from 'nrpe/passive.jinja2' import passive_check with context %}
{{ passive_check('nrpe') }}

{% if not salt['pillar.get']('debug', False) %}
/etc/rsyslog.d/nrpe.conf:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/rsyslog.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: rsyslog
    - watch_in:
      - service: rsyslog
{% endif %}

extend:
{%- for state_id in ('apt', 'apt.conf', 'dpkg.conf') %}
  {{ state_id }}:
    file:
      - group: nagios
      - require:
        - group: nagios-nrpe-server
{%- endfor %}

{%- from 'macros.jinja2' import change_ssh_key_owner with context %}
{{ change_ssh_key_owner('nagios', {'pkg': 'nagios-nrpe-server'}) }}
