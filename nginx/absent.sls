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

Uninstall the Nginx web server.
-#}
nginx-old-init:
  cmd:
    - wait
    - name: dpkg-divert --rename --remove /etc/init.d/nginx
    - watch:
      - file: nginx-old-init
  file:
    - absent
    - name: /usr/share/nginx/init.d

nginx:
  file:
    - absent
    - name: /etc/init/nginx.conf
    - require:
      - service: nginx
  pkg:
    - purged
    - require:
      - service: nginx
      - file: nginx-old-init
  service:
    - dead

nginx-upstart-log:
  cmd:
    - run
    - name: find /var/log/upstart/ -maxdepth 1 -type f -name 'nginx.log.*' -delete
    - require:
      - service: nginx

{% for type in ('etc', 'var/log', 'etc/logrotate.d') %}
/{{ type }}/nginx:
  file:
    - absent
    - require:
      - pkg: nginx
{% endfor %}

{% for log_type in ('access', 'error') %}
nginx-logger-{{ log_type }}:
  file:
    - absent
    - name: /etc/init/nginx-logger-{{ log_type }}.conf
    - require:
      - service: nginx-logger-{{ log_type }}
  service:
    - dead
{% endfor %}
