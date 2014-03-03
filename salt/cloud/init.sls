{#-
Copyright (c) 2013, Hung Nguyen Viet

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
-#}
include:
  - apt
  - salt
  - pip

{%- for type in ('profiles', 'providers') %}
/etc/salt/cloud.{{ type }}:
  file:
    - managed
    - template: jinja
    - mode: 440
    - source: salt://salt/cloud/{{ type }}.jinja2
    - require:
      - pkg: salt-cloud
{%- endfor %}

/etc/salt/cloud:
  file:
    - managed
    - template: jinja
    - mode: 440
    - source: salt://salt/cloud/config.jinja2
    - require:
      - pkg: salt-cloud

salt_cloud_remove_old_version:
  pkg:
    - removed
    - name: salt-cloud

{%- set version = '0.8.11' %}
salt-cloud:
  pkg:
    - installed
    - name: python-libcloud
    - skip_verify: True
    - require:
      - pkg: salt
      - apt_repository: salt
      - pkg: salt_cloud_remove_old_version
  pip:
    - installed
{%- if 'files_archive' in pillar %}
    - name: {{ pillar['files_archive'] }}/pip/salt-cloud-{{ version }}.tar.gz
{%- else %}
    - name: salt-cloud=={{ version }}
{%- endif %}
    - require:
      - module: pip
      - pkg: salt-cloud

salt-cloud-boostrap-script:
  file:
    - managed
    - name: /etc/salt/cloud.deploy.d/bootstrap_salt.sh
    - source: salt://salt/cloud/bootstrap.jinja2
    - mode: 500
    - user: root
    - group: root
    - mkdirs: True
    - template: jinja
    - require:
      - pkg: salt-cloud
