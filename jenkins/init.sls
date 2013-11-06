{#-
Copyright (c) 2013, Nicolas Plessis
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

Author: Nicolas Plessis <nicolasp@microsigns.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

TODO: add SSL through nginx.
-#}

include:
  - apt
  - java.7.jdk
  - nginx
{% if salt['pillar.get']('jenkins:ssl', False) %}
  - ssl
{% endif %}

jenkins_dependencies:
  pkg:
    - installed
    - names:
      - daemon
      - psmisc

jenkins:
  pkg:
    - installed
    - sources:
{%- if 'files_archive' in pillar %}
      - jenkins: {{ pillar['files_archive']|replace('file://', '') }}/mirror/jenkins_1.529_all.deb
{%- else %}
      - jenkins: http://pkg.jenkins-ci.org/debian/binary/jenkins_1.529_all.deb
{%- endif %}
    - require:
      - cmd: apt_sources
      - pkg: openjdk_jdk
      - pkg: jenkins_dependencies
  service:
    - running
    - require:
      - pkg: jenkins

/etc/nginx/conf.d/jenkins.conf:
  file:
    - managed
    - template: jinja
    - source: salt://jenkins/nginx.jinja2
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - pkg: nginx
      - service: jenkins

extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/conf.d/jenkins.conf
{% if salt['pillar.get']('jenkins:ssl', False) %}
        - cmd: /etc/ssl/{{ pillar['jenkins']['ssl'] }}/chained_ca.crt
        - module: /etc/ssl/{{ pillar['jenkins']['ssl'] }}/server.pem
        - file: /etc/ssl/{{ pillar['jenkins']['ssl'] }}/ca.crt
{% endif %}
