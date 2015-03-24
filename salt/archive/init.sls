{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set ssl = salt['pillar.get']('salt_archive:ssl', False) -%}

include:
  - bash
  - cron
  - local
  - nginx
  - pysc
{%- set source = salt['pillar.get']('salt_archive:source', False) %}
{%- if not source %}
  - requests
{%- endif %}
  - rsync
  - ssh.server
{%- if ssl %}
  - ssl
{%- endif %}

salt_archive:
  user:
    - present
    - fullname: Salt Archive
    - shell: /bin/false
    - home: /var/lib/salt_archive
    - createhome: False
  file:
    - directory
    - name: /var/lib/salt_archive
    - user: root
    - group: salt_archive
    - mode: 755
    - require:
      - user: salt_archive

/etc/cron.d/salt-archive:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 500
    - source: salt://salt/archive/cron.jinja2
    - require:
      - user: salt_archive
      - pkg: rsync
      - file: bash
{%- if not source %}
      - file: /usr/local/bin/salt_archive_incoming.py
    {#-
     if source is not defined, create an incoming
     directory.
    #}

/var/lib/salt_archive/incoming:
  file:
    - directory
    - user: root
    - group: salt_archive
    - mode: 750
    - require:
      - file: salt_archive

    {%- for type in ('pip', 'mirror') %}
/var/lib/salt_archive/incoming/{{ type }}:
  file:
    - directory
    - user: root
    - group: salt_archive
    - mode: 770
    - require:
      - user: salt_archive
      - file: /var/lib/salt_archive/incoming
    {%- endfor %}

    {%- for type in ('pip', 'mirror') %}
/var/lib/salt_archive/{{ type }}:
  file:
    - directory
    - user: root
    - group: salt_archive
    - mode: 750
    - require:
      - file: salt_archive
    {%- endfor %}

/var/lib/salt_archive/mirror/clamav:
    file:
    - directory
    - user: root
    - group: salt_archive
    - mode: 750
    - require:
      - file: /var/lib/salt_archive/mirror

/usr/local/bin/salt_archive_incoming.py:
  pkg:
    - installed
    - name: lsof
  file:
    - managed
    - user: root
    - group: root
    - source: salt://salt/archive/incoming.py
    - mode: 550
    - require:
      - pkg: /usr/local/bin/salt_archive_incoming.py
      - pkg: rsync
      - file: /usr/local
      - file: /var/lib/salt_archive/incoming/pip
      - file: /var/lib/salt_archive/incoming/mirror
      - file: /var/lib/salt_archive/pip
      - file: /var/lib/salt_archive/mirror
      - file: /usr/local/bin/salt_archive_set_owner_mode.sh
      - module: pysc
{%- else %}
    {#-
     if source is defined, can't have an incoming
     directory.
    #}

/var/lib/salt_archive/incoming:
  file:
    - absent

/usr/local/bin/salt_archive_sync.sh:
  file:
    - managed
    - user: root
    - group: root
    - source: salt://salt/archive/salt_archive_sync.jinja2
    - template: jinja
    - mode: 550
    - require:
      - file: /usr/local
      - file: bash
      - file: /usr/local/bin/salt_archive_set_owner_mode.sh
    - require_in:
      - file: /etc/cron.d/salt-archive

archive_rsync:
  cmd:
    - wait
    - name: /usr/local/bin/salt_archive_sync.sh -v
    - user: root
    - require:
      - pkg: rsync
      - file: /usr/local/bin/salt_archive_sync.sh
    - watch:
      - file: salt_archive
{%- endif %}

/usr/local/bin/salt_archive_set_owner_mode.sh:
  file:
    - managed
    - user: root
    - group: root
    - source: salt://salt/archive/salt_archive_set_owner_mode.jinja2
    - template: jinja
    - mode: 550
    - require:
      - file: /usr/local
      - file: bash

/etc/nginx/conf.d/salt_archive.conf:
  file:
    - managed
    - template: jinja
    - source: salt://salt/archive/nginx.jinja2
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - file: salt_archive
      - pkg: nginx
    - watch_in:
      - service: nginx

/usr/local/bin/salt_archive_clamav.sh:
  file:
    - absent

salt-archive-clamav:
  file:
    - name: /usr/local/bin/salt_archive_clamav.py
{%- if source %}
    - absent
{%- else %}
    - managed
    - source: salt://salt/archive/clamav.py
    - user: root
    - group: root
    - mode: 550
    - require:
      - module: requests
      - pkg: salt-archive-clamav
      - file: /usr/local/bin/salt_archive_set_owner_mode.sh
      - file: /var/lib/salt_archive/mirror/clamav
  cmd:
    - run
    - name: /usr/local/bin/salt_archive_clamav.py
    - require:
      - file: salt-archive-clamav
      - user: salt_archive
  pkg:
    - installed
    - name: wget
    - require:
      - cmd: apt_sources
{%- endif -%}

{%- for key, enc in salt['pillar.get']('salt_archive:keys', {}).iteritems() %}
salt_archive_{{ key }}:
  ssh_auth:
    - present
    - name: {{ key }}
    - user: salt_archive
    - enc: {{ enc }}
    - require:
      - file: salt_archive
      - service: openssh-server
{%- endfor %}

extend:
  web:
    user:
      - groups:
        - salt_archive
      - require:
        - user: salt_archive
  nginx:
    service:
      - watch:
        - user: salt_archive
{%- if ssl %}
        - cmd: ssl_cert_and_key_for_{{ ssl }}
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
{%- endif -%}
