{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'macros.jinja2' import manage_pid with context -%}
{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{%- from "upstart/absent.sls" import upstart_absent with context %}
include:
  - python
  - apt
  - mongodb
  - mongodb.pymongo
  - java.7
  - graylog2
  - local
  - rsyslog
  - pysc
  - requests
{#-
  graylog2.server require elasticsearch, install it when testing to
  make the inputs importing work.  In production environment,
  elasticsearch doesn't need to be install in same machine as
  graylog2.server
#}
{%- set __test__ = salt['pillar.get']("__test__", False) %}
{%- if __test__ %}
  - elasticsearch
{%- endif %}

{%- set user = 'graylog' %}
{%- set mongodb_suffix = '0-20' %}
{%- set elasticsearch_suffix = '0-20' %}

/etc/graylog2:
  file:
    - absent

/var/lib/graylog2:
  file:
    - absent

/etc/graylog2.conf:
  file:
    - absent

/usr/local/graylog2-server-0.20.6:
  file:
    - absent

/var/log/graylog2:
  file:
    - absent

/var/run/graylog2:
  file:
    - absent

/etc/rsyslog.d/graylog2-server.conf:
  file:
    - absent

{{ upstart_absent('graylog2-server') }}
extend:
  graylog2-server:
    user:
      - absent
      - name: graylog2
      - require:
        - service: graylog2-server
    group:
      - absent
      - name: graylog2
      - require:
        - user: graylog2-server

{#- For cluster using, all node's data should be explicit: http,master,data,port and/or name #}
/etc/graylog/server/elasticsearch.yml:
  file:
    - managed
    - source: salt://elasticsearch/config.jinja2
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - context:
        master: 'false'
        data: 'false'
        origin_state: graylog2.server
    - require:
      - pkg: graylog-server

/etc/graylog/server/server.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - source: salt://graylog2/server/config.jinja2
    - context:
        mongodb_suffix: {{ mongodb_suffix }}
        elasticsearch_suffix: {{ elasticsearch_suffix }}
    - require:
      - pkg: graylog-server

/etc/default/graylog-server:
  file:
    - managed
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - source: salt://graylog2/server/default.jinja2
    - require:
      - pkg: graylog-server

graylog-server:
  pkg:
    - installed
    - name: graylog-server
    - require:
      - pkgrepo: graylog
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - pkg: jre-7
      - file: jre-7
      - file: /etc/graylog/server/server.conf
      - file: /etc/graylog/server/elasticsearch.yml
      - file: /etc/default/graylog-server
    - require:
      - service: mongodb
{%- if salt['pillar.get']("__test__", False) %}
      - process: elasticsearch
{%- endif %}
{%- set parsed_url = salt['common.urlparse'](salt['pillar.get']('graylog2:rest_listen_uri', 'http://127.0.0.1:12900')) -%}
{%- set hostname = parsed_url.hostname %}
{%- set port = parsed_url.port %}
  process:
    - wait_socket
    - address: {{ hostname }}
    - port: {{ port }}
    - require:
      - service: graylog-server

{{ manage_upstart_log('graylog-server') }}

import_graylog2_gelf:
  graylog:
    - gelf_input
    {#- The following parameters have their default values and are unnecessary #}
    - title: gelf
{%- set admin_username = salt['pillar.get']('graylog2:admin_username', 'admin') %}
    - stype: udp
    - port: 12201
    - creator: {{ salt['pillar.get']('graylog2:admin_username', 'admin') }}
    - bind_address: 0.0.0.0
    - buffer_size: 1048576
    - require:
      - process: graylog-server
      - module: requests

import_graylog2_syslog:
  graylog:
    - syslog_input
    {#- The following parameters have their default values and are unnecessary #}
    - title: syslog
    - stype: udp
    - port: 1514
    - creator: {{ salt['pillar.get']('graylog2:admin_username', 'admin') }}
    - bind_address: 0.0.0.0
    - buffer_size: 1048576
    - allow_override_date: true
    - store_full_message: false
    - force_rdns: false
    - require:
      - process: graylog-server
      - module: requests

{%- set streams = salt['pillar.get']('graylog2:streams', {}) %}
{%- for stream_name, stream_data in streams.iteritems() %}
  {%- set rules = stream_data['rules']|default([]) %}
  {%- set receivers = stream_data['receivers']|default([]) %}
  {%- set alert_grace = stream_data['alert_grace']|default(1) %}
  {% set receivers_type = stream_data['receivers_type']|default("emails") %}
{{ stream_name|lower|replace(' ', '_') }}_graylog2_stream:
  graylog_stream:
    - present
    - name: {{ stream_name }}
  {%- if rules %}
    - rules:
      {%- for rule in rules %}
      - field: {{ rule['field'] }}
        value: {{ rule['value'] }}
        inverted: {{ rule['inverted'] }}
        type: {{ rule['type'] }}
      {%- endfor %}
  {%- endif %}
    - receivers:
  {%- for receiver in receivers %}
      - {{ receiver }}
  {%- endfor %}
    - receivers_type: {{ receivers_type }}
    - alert_grace: {{ alert_grace }}
    - require:
      - process: graylog-server
      - module: requests
{%- endfor %}
