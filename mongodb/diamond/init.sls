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

Diamond statistics for MongoDB.
-#}
include:
  - diamond
  - mongodb
  - pip

{#- TODO: remove that statement in >= 2014-04 #}
/usr/local/diamond/salt-pymongo-requirements.txt:
  file:
    - absent

diamond-pymongo:
  file:
    - managed
    - name: /usr/local/diamond/salt-mongodb-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://mongodb/diamond/requirements.jinja2
    - require:
      - virtualenv: diamond
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/diamond
    - requirements: /usr/local/diamond/salt-mongodb-requirements.txt
    - require:
      - virtualenv: diamond
    - watch:
      - file: diamond-pymongo

diamond_mongodb:
  file:
    - managed
    - template: jinja
    - name: /etc/diamond/collectors/MongoDBCollector.conf
    - user: root
    - group: root
    - mode: 440
    - source: salt://mongodb/diamond/config.jinja2
    - require:
      - module: diamond-pymongo
      - file: /etc/diamond/collectors

mongodb_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[mongodb]]
        exe = ^\/usr\/bin\/mongod$

extend:
  diamond:
    service:
      - watch:
        - file: diamond_mongodb
      - require:
        - service: mongodb
