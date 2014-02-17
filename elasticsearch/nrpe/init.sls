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

 Nagios NRPE checks for elasticsearch
-#}
{%- from 'nrpe/passive.sls' import passive_check with context %}
{% set ssl = salt['pillar.get']('elasticsearch:ssl', False) %}
include:
  - apt.nrpe
  - cron.nrpe
  - nrpe
{% if ssl %}
  - ssl.nrpe
  - nginx.nrpe
{% endif %}

/etc/nagios/nrpe.d/elasticsearch.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://elasticsearch/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server

/etc/nagios/nrpe.d/elasticsearch-nginx.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nginx/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
      - file: /usr/lib/nagios/plugins/check_elasticsearch_cluster.py
    - context:
      deployment: elasticsearch
      http_port: 9200
      domain_name: 127.0.0.1
      https: {{ ssl }}

/usr/local/bin/check_elasticsearch_cluster.py:
  file:
    - absent

pyelasticsearch:
  file:
    - managed
    - name: /usr/local/nagios/elasticsearch-requirements.txt
    - source: salt://elasticsearch/nrpe/requirements.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - virtualenv: nrpe-virtualenv
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/nagios
    - requirements: /usr/local/nagios/elasticsearch-requirements.txt
    - watch:
      - file: pyelasticsearch

/usr/lib/nagios/plugins/check_elasticsearch_cluster.py:
  file:
    - managed
    - source: salt://elasticsearch/nrpe/check.py
    - user: nagios
    - group: nagios
    - mode: 550
    - require:
      - module: pyelasticsearch
      - pkg: nagios-nrpe-server

{{ passive_check('elasticsearch') }}

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/elasticsearch.cfg
        - file: /etc/nagios/nrpe.d/elasticsearch-nginx.cfg
