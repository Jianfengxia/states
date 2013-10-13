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

 Diamond statistics for Elasticsearch
 TODO: Diamond + http://www.elasticsearch.org/guide/reference/modules/jmx/
-#}
{% set ssl = pillar['elasticsearch']['ssl']|default(False) %}
include:
  - diamond
  - cron.diamond
{% if ssl %}
  - nginx.diamond
{% endif %}

elasticsearch_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[elasticsearch]]
        cmdline = .+java.+\-cp \:\/usr\/share\/elasticsearch\/lib\/elasticsearch\-.+\.jar

/etc/diamond/collectors/ElasticSearchCollector.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://elasticsearch/diamond/config.jinja2
    - require:
      - file: /etc/diamond/collectors

extend:
  diamond:
    service:
      - watch:
        - file: /etc/diamond/collectors/ElasticSearchCollector.conf
