{#-
Copyright (C) 2013 the Institute for Institutional Innovation by Data
Driven Design Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE  MASSACHUSETTS INSTITUTE OF
TECHNOLOGY AND THE INSTITUTE FOR INSTITUTIONAL INNOVATION BY DATA
DRIVEN DESIGN INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the names of the Institute for
Institutional Innovation by Data Driven Design Inc. shall not be used in
advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the
Institute for Institutional Innovation by Data Driven Design Inc.

Author: Hung Nguyen Viet hvnsweeting@gmail.com
Maintainer: Hung Nguyen Viet hvnsweeting@gmail.com
-#}
include:
  - postgresql
  - postgresql.server
  - virtualenv
  - uwsgi
  - local
  - nginx
  - pip
  - web
  - python.dev
  - apt
  - memcache
  - rsyslog
{% if salt['pillar.get']('djangopypi2:ssl', False) %}
  - ssl
{% endif %}
{% if 'graphite_address' in pillar %}
  - statsd
{% endif %}

{%- set root_dir = "/usr/local/djangopypi2" %}

djangopypi2:
  virtualenv:
    - manage
    - name: /usr/local/djangopypi2
    - no_site_packages: True
    - require:
      - module: virtualenv
      - file: /usr/local
  file:
    - managed
    - name: /usr/local/djangopypi2/salt-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://djangopypi2/requirements.jinja2
    - require:
      - virtualenv: djangopypi2
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/djangopypi2/bin/pip
    - requirements: /usr/local/djangopypi2/salt-requirements.txt
    - require:
      - virtualenv: djangopypi2
    - watch:
      - pkg: python-dev
      - pkg: postgresql-dev
      - file: djangopypi2
  cmd:
    - wait
    - name: find /usr/local/djangopypi2 -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: djangopypi2
  postgres_user:
    - present
    - name: {{ salt['pillar.get']('djangopypi2:db:username', 'djangopypi2') }}
    - password: {{ salt['password.pillar']('djangopypi2:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ salt['pillar.get']('djangopypi2:db:name', 'djangopypi2') }}
    - owner: {{ salt['pillar.get']('djangopypi2:db:username', 'djangopypi2') }}
    - runas: postgres
    - require:
      - postgres_user: djangopypi2
      - service: postgresql

djangopypi2_urls:
  file:
    - managed
    - name: {{ root_dir }}/lib/python2.7/site-packages/djangopypi2/website/urls.py
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - module: djangopypi2
    - source: salt://djangopypi2/urls.jinja2

djangopypi2_settings:
  file:
    - managed
    - name: {{ root_dir }}/lib/python2.7/site-packages/djangopypi2/website/settings.py
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - module: djangopypi2
    - source: salt://djangopypi2/config.jinja2
  module:
    - wait
    - name: django.syncdb
    - settings_module: djangopypi2.website.settings
    - bin_env: {{ root_dir }}
    - require:
      - cmd: djangopypi2
      - service: rsyslog
    - watch:
      - file: djangopypi2_settings
      - file: djangopypi2_urls
      - postgres_database: djangopypi2

{{ root_dir }}/manage:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - source: salt://django/manage.jinja2
    - context:
      settings: djangopypi2.website.settings
      virtualenv: {{ root_dir }}
    - require:
      - virtualenv: djangopypi2

djangopypi2_collectstatic:
  module:
    - wait
    - name: django.collectstatic
    - settings_module: djangopypi2.website.settings
    - bin_env: {{ root_dir }}
    - require:
      - module: djangopypi2_settings
      - cmd: djangopypi2
    - watch:
      - file: djangopypi2_settings
      - module: djangopypi2

djangopypi2_loaddata:
  module:
    - wait
    - name: django.loaddata
    - settings_module: djangopypi2.website.settings
    - fixtures: initial
    - bin_env: {{ root_dir }}
    - require:
      - module: djangopypi2_settings
    - watch:
      - postgres_database: djangopypi2

djangopypi2_admin_user:
  module:
    - wait
    - name: django.command
    - command: createsuperuser_plus --username={{ pillar['djangopypi2']['initial_admin_user']['username'] }} --email={{ salt['pillar.get']('djangopypi2:initial_admin_user:email', 'root@example.com') }} --password={{ pillar['djangopypi2']['initial_admin_user']['password'] }}
    - settings_module: djangopypi2.website.settings
    - bin_env: {{ root_dir }}
    - require:
      - module: djangopypi2_loaddata
    - watch:
      - postgres_database: djangopypi2

{{ root_dir }}/django_contrib_sites.yaml:
  file:
    - absent

{# set django.contrib.sites.models.Site id=1 #}
djangopypi2-django_contrib_sites:
  file:
    - managed
    - name: {{ root_dir }}/django_contrib_sites.xml
    - source: salt://django/site.jinja2
    - template: jinja
    - context:
      domain_name: {{ pillar['djangopypi2']['hostnames'][0] }}
    - user: root
    - group: root
    - mode: 440
  module:
    - wait
    - name: django.loaddata
    - settings_module: djangopypi2.website.settings
    - fixtures: {{ root_dir }}/django_contrib_sites.xml
    - bin_env: {{ root_dir }}
    - require:
      - module: djangopypi2_settings
      - file: djangopypi2-django_contrib_sites
    - watch:
      - postgres_database: djangopypi2

/var/lib/deployments/djangopypi2/media:
  file:
    - directory
    - user: www-data
    - group: www-data
    - makedirs: True

uwsgi_djangopypi2:
  uwsgi:
    - available
    - enabled: True
    - name: djangopypi2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - source: salt://uwsgi/template.jinja2
    - context:
      chdir: {{ root_dir }}
      appname: djangopypi2
      module: djangopypi2.website.wsgi
      django_settings: djangopypi2.website.settings
      virtualenv: {{ root_dir }}
    - require:
      - service: uwsgi_emperor
      - postgres_database: djangopypi2
      - service: memcached
      - service: rsyslog
      - module: djangopypi2-django_contrib_sites
    - watch:
      - cmd: djangopypi2
      - file: djangopypi2_settings
      - file: djangopypi2_urls
      - file: /var/lib/deployments/djangopypi2/media
      - module: djangopypi2_loaddata

/etc/nginx/conf.d/djangopypi2.conf:
  file:
    - managed
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - source: salt://nginx/template.jinja2
    - context:
      appname: djangopypi2
      root: /var/lib/deployments/djangopypi2
      statics:
        - static
    - require:
      - pkg: nginx

extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/conf.d/djangopypi2.conf
{% if salt['pillar.get']('djangopypi2:ssl', False) %}
        - cmd: /etc/ssl/{{ pillar['djangopypi2']['ssl'] }}/chained_ca.crt
        - module: /etc/ssl/{{ pillar['djangopypi2']['ssl'] }}/server.pem
        - file: /etc/ssl/{{ pillar['djangopypi2']['ssl'] }}/ca.crt
{% endif %}
