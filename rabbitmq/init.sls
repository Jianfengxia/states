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

Install a server or cluster of RabbitMQ message queue servers.

To properly use this state, the user monitor need to be changed
in WebUI to grant read access across all vhost.
as this is not yet implemented in salt.

and a admin user should be created and the user guest with default
password dropped.
as long as the default guest user and guest password combination is
is the pillar, the WebUI won't be available.
-#}
{#- TODO: configure logging to GELF -#}
{#- TODO: SSL support http://www.rabbitmq.com/ssl.html -#}

include:
  - apt
  - logrotate
  - hostname
{% if pillar['rabbitmq']['management'] != 'guest' -%}
  {%- if salt['pillar.get']('rabbitmq:ssl', False) %}
  - ssl
  {%- endif %}
  - nginx
{% endif %}

{% set master_id = pillar['rabbitmq']['cluster']['master'] %}

rabbitmq:
  user:
    - present
    - shell: /bin/false
    - home: /var/lib/rabbitmq
    - password: "*"
    - enforce_password: True
    - gid_from_name: True

/var/lib/rabbitmq:
  file:
    - directory
    - user: rabbitmq
    - group: rabbitmq
    - mode: 700
    - require:
      - user: rabbitmq

{#
 Clustering requires the same cookie to be the same on all nodes.
 It need to be created BEFORE rabbitmq-server package is installed.
 If the cookie is changed while the daemon is running, it cannot be stopped
 using regular startup script and need to be manually killed.
#}

{%- set version = '3.1.2' %}
{%- set sub_version = version + '-1' %}
rabbitmq_erlang_cookie:
  file:
    - managed
    - name: /var/lib/rabbitmq/.erlang.cookie
    - template: jinja
    - user: rabbitmq
    - group: rabbitmq
    - mode: 400
    - source: salt://rabbitmq/cookie.jinja2
    - require:
      - file: /var/lib/rabbitmq

rabbitmq_dependencies:
  pkg:
    - installed
    - pkgs:
      - erlang-nox
    - require:
      - cmd: apt_sources
      - pkg: logrotate

{%- if salt['pkg.version']('rabbitmq-server') not in ('', sub_version) %}
rabbitmq_old_version:
  pkg:
    - removed
    - name: rabbitmq-server
    - require_in:
      - pkg: rabbitmq-server
{%- endif %}

rabbitmq-server:
  file:
    - directory
    - name: /etc/rabbitmq/rabbitmq.conf.d
    - require:
      - pkg: rabbitmq-server
  service:
    - running
    - enable: True
    - order: 50
{# until https://github.com/saltstack/salt/issues/5027 is fixed, this is required #}
    - sig: beam{% if grains['num_cpus'] > 1 %}.smp{% endif %}
    - require:
      - pkg: rabbitmq-server
    - watch:
      - file: rabbitmq-server
      - rabbitmq_plugins: rabbitmq-server
{% for node in pillar['rabbitmq']['cluster']['nodes'] %}
    {% if node != grains['id'] %}
      - host: host_{{ node }}
    {% endif %}
{% endfor %}
  rabbitmq_plugins:
    - enabled
    - name: rabbitmq_management
    - env: HOME=/var/lib/rabbitmq
    - require:
      - pkg: rabbitmq-server
  pkg:
    - installed
    - sources:
{%- if 'files_archive' in pillar %}
      - rabbitmq-server: {{ pillar['files_archive']|replace('file://', '')|replace('https://', 'http://') }}/mirror/rabbitmq-server_{{ sub_version }}_all.deb
{%- else %}
      - rabbitmq-server: http://www.rabbitmq.com/releases/rabbitmq-server/v{{ version }}/rabbitmq-server_{{ sub_version }}_all.deb
{%- endif %}
    - require:
      - pkg: rabbitmq_dependencies
      - host: hostname
      - file: rabbitmq_erlang_cookie
{% if grains['id'] == master_id %}
{#  rabbitmq_vhost:#}
{#    - present#}
{#    - name: test#}
{#    - require:#}
{#      - service: rabbitmq-server#}
  rabbitmq_user:
    - present
    - name: {{ salt['pillar.get']('rabbitmq:monitor:user', salt['pillar.get']('salt_monitor') )}}
    - password: {{ salt['password.pillar']('rabbitmq:monitor:password') }}
    - force: True
    - require:
      - service: rabbitmq-server

{% for vhost in salt['pillar.get']('rabbitmq:vhosts', []) %}
rabbitmq-vhost-{{ vhost }}:
  rabbitmq_user:
    - present
    - name: {{ vhost }}
    - password: {{ pillar['rabbitmq']['vhosts'][vhost] }}
    - force: True
    - require:
      - service: rabbitmq-server
  rabbitmq_vhost:
    - present
    - name: {{ vhost }}
    - user: {{ vhost }}
    - require:
      - rabbitmq_user: rabbitmq-vhost-{{ vhost }}
{% endfor %}

{% endif %}

{% if grains['id'] != master_id %}
in_rabbitmq_cluster:
  rabbitmq_cluster:
    - joined
    - master: {{ master_id }}
    - env: HOME=/var/lib/rabbitmq
    - user: {{ pillar['rabbitmq']['management']['user'] }}
    - password: {{ pillar['rabbitmq']['management']['password'] }}
    - disk_node: True
    - require:
      - rabbitmq_plugins: rabbitmq-server
      - service: rabbitmq-server
{% endif %}

{% for node in pillar['rabbitmq']['cluster']['nodes'] -%}
    {% if node != grains['id'] -%}
host_{{ node }}:
  host:
    - present
    - name: {{ node }}
    - ip: {{ pillar['rabbitmq']['cluster']['nodes'][node]['private'] }}
    {% endif %}
{% endfor %}

{% if pillar['rabbitmq']['management'] != 'guest' %}
/etc/nginx/conf.d/rabbitmq.conf:
  file:
    - managed
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 400
    - source: salt://nginx/proxy.jinja2
    - require:
      - pkg: nginx
    - context:
      destination: http://127.0.0.1:15672
      ssl: {{ salt['pillar.get']('rabbitmq:ssl', False) }}
      hostnames: {{ pillar['rabbitmq']['hostnames'] }}
{% endif %}

{% if pillar['rabbitmq']['management'] != 'guest' %}
extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/conf.d/rabbitmq.conf
  {% if salt['pillar.get']('rabbitmq:ssl', False) %}
        - cmd: /etc/ssl/{{ pillar['rabbitmq']['ssl'] }}/chained_ca.crt
        - module: /etc/ssl/{{ pillar['rabbitmq']['ssl'] }}/server.pem
        - file: /etc/ssl/{{ pillar['rabbitmq']['ssl'] }}/ca.crt
  {% endif %}
{% endif %}


/etc/apt/sources.list.d/www.rabbitmq.com-debian-testing.list:
  file:
    - absent
