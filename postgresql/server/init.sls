{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "postgresql/init.sls" import postgresql_version with context -%}
{%- from 'macros.jinja2' import manage_pid with context %}
{% set ssl = salt['pillar.get']('postgresql:ssl', False) %}
include:
  - apt
  - hostname
  - locale
  - postgresql
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}

{% set version = postgresql_version() %}

postgresql:
  pkg:
    - latest
    - pkgs:
      - postgresql-{{ version }}
      - postgresql-client-{{ version }}
    - require:
      - host: hostname
      - cmd: system_locale
      - pkgrepo: postgresql-dev
      - cmd: apt_sources
{% set encoding = salt['pillar.get']('encoding', 'en_US.UTF-8') %}
    - env:
        LANG: {{ encoding }}
        LC_CTYPE: {{ encoding }}
        LC_COLLATE: {{ encoding }}
        LC_ALL: {{ encoding }}
  file:
    - managed
    - name: /etc/postgresql/{{ version }}/main/postgresql.conf
    - source: salt://postgresql/server/config.jinja2
    - user: postgres
    - group: postgres
    - mode: 440
    - template: jinja
    - require:
      - pkg: postgresql
      - user: postgres
    - context:
        version: {{ version }}
  service:
    - running
    - enable: True
    - order: 50
    - name: postgresql
    - require:
      - service: rsyslog
    - watch:
      - user: postgres
      - pkg: postgresql
      - file: postgresql
      - file: /etc/init.d/postgresql
{% if ssl %}
      - cmd: ssl_cert_and_key_for_{{ ssl }}
{% endif %}

/etc/init.d/postgresql:
  file:
    - managed
    - source: salt://postgresql/server/sysvinit.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - require:
      - pkg: postgresql

{%- call manage_pid('/var/run/postgresql/' + version + '-main.pid', 'postgres', 'postgres', 'postgresql') %}
- pkg: postgresql
{%- endcall %}

/etc/logrotate.d/postgresql-common:
  file:
    - absent
    - require:
      - pkg: postgresql

/var/log/postgresql/postgresql-{{ version }}-main.log:
  file:
    - absent
    - require:
      - pkg: postgresql
    - require_in:
      - service: postgresql
