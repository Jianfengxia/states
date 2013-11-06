{#-
Copyright (c) 2013, Hung Nguyen Viet
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

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

A webmail software.
-#}
include:
  - local
  - nginx
  - php.dev
  - postgresql.server
  - uwsgi.php
{%- if salt['pillar.get']('roundcube:ssl', False) %}
  - ssl
{%- endif %}
  - web

{%- set version = "0.9.0" %}
{%- set roundcubedir = "/usr/local/roundcubemail-" + version %}
{%- set dbname = salt['pillar.get']('roundcube:db:name', 'roundcube') %}
{%- set dbuser = salt['pillar.get']('roundcube:db:username', 'roundcube') %}
{%- set dbuserpass = salt['password.pillar']('roundcube:db:password', 10) %}

php5-pgsql:
  pkg:
    - installed
    - require:
      - pkg: php-dev

roundcube:
  archive:
    - extracted
    - name: /usr/local/
{%- if 'files_archive' in pillar %}
    - source: {{ pillar['files_archive'] }}/mirror/roundcubemail-{{ version }}.tar.gz
{%- else %}
    - source: http://jaist.dl.sourceforge.net/project/roundcubemail/roundcubemail/{{ version }}/roundcubemail-{{ version }}.tar.gz
{%- endif %}
    - source_hash: md5=843de3439886c2dddb0f09e9bb6a4d04
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/roundcubemail-{{ version }}
    - require:
      - file: /usr/local
  postgres_user:
    - present
    - name: {{ dbuser }}
    - password: {{ dbuserpass }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ dbname }}
    - owner: {{ dbuser }}
    - runas: postgres
    - require:
      - postgres_user: roundcube

{{ roundcubedir }}:
  file:
    - directory
    - user: root
    - group: root
    - recurse:
      - user
      - group
    - require:
      - archive: roundcube

{{ roundcubedir }}/config/db.inc.php:
  file:
    - managed
    - source: salt://roundcube/database.jinja2
    - template: jinja
    - makedirs: True
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - file: {{ roundcubedir }}
      - archive: roundcube
      - user: web
    - context:
      password: {{ dbuserpass }}
      dbname: {{ dbname }}
      username: {{ dbuser }}

{{ roundcubedir }}/config/main.inc.php:
  file:
    - managed
    - source: salt://roundcube/config.jinja2
    - template: jinja
    - makedirs: True
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - file: {{ roundcubedir }}
      - user: web
      - archive: roundcube

{% for dir in ('logs', 'temp') %}
{{ roundcubedir }}/{{ dir }}:
  file:
    - directory
    - user: www-data
    - recurse:
      - user
    - require:
      - file: {{ roundcubedir }}
      - user: web
    - require_in:
      - uwsgi: uwsgi_roundcube
{% endfor %}

/etc/nginx/conf.d/roundcube.conf:
  file:
    - managed
    - source: salt://roundcube/nginx.jinja2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - pkg: nginx
      - user: web
      - uwsgi: uwsgi_roundcube
    - context:
      dir: {{ roundcubedir }}

uwsgi_roundcube:
  uwsgi:
    - available
    - enabled: True
    - name: roundcube
    - source: salt://roundcube/uwsgi.jinja2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - context:
      dir: {{ roundcubedir }}
    - require:
      - service: uwsgi_emperor
      - module: roundcube_initial
    - watch:
      - file: {{ roundcubedir }}/config/main.inc.php
      - file: {{ roundcubedir }}/config/db.inc.php
      - archive: roundcube
      - pkg: php5-pgsql

roundcube_initial:
  cmd:
    - wait
    - name: psql -f {{ roundcubedir }}/SQL/postgres.initial.sql -d roundcube
    - user: postgres
    - group: postgres
    - require:
      - service: postgresql
      - postgres_database: roundcube
    - watch:
      - archive: roundcube
  module:
    - wait
    - name: postgres.owner_to
    - dbname: roundcube
    - ownername: roundcube
    - runas: postgres
    - watch:
      - cmd: roundcube_initial

extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/conf.d/roundcube.conf
{%- if salt['pillar.get']('roundcube:ssl', False) %}
        - cmd: /etc/ssl/{{ pillar['roundcube']['ssl'] }}/chained_ca.crt
        - module: /etc/ssl/{{ pillar['roundcube']['ssl'] }}/server.pem
        - file: /etc/ssl/{{ pillar['roundcube']['ssl'] }}/ca.crt
{% endif %}
