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

Install all dependencies to create Python's virtualenv.
-#}
include:
  - git
  - mercurial
  - pip

python-virtualenv:
  pkg:
    - purged

{#- TODO: remove that statement in >= 2014-04 #}
{{ opts['cachedir'] }}/salt-virtualenv-requirements.txt:
  file:
    - absent

virtualenv:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/virtualenv
    - source: salt://virtualenv/requirements.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - module: pip
  module:
{%- if not salt['file.file_exists']('/usr/local/bin/virtualenv') -%}
    {#- force module to run if virtualenv isn't installed yet #}
    - run
{%- else %}
    - wait
    - watch:
      - file: virtualenv
{%- endif %}
    - name: pip.install
    - requirements: {{ opts['cachedir'] }}/pip/virtualenv
    - require:
      - pkg: git
      - module: mercurial
{%- if not salt['file.file_exists']('/usr/local/bin/virtualenv') %}
      - file: virtualenv
{%- endif -%}
