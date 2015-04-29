{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - diamond
  - mysql.server
  - python.dev
  - salt.minion.diamond
  {#- mysqlclient-python depends on libssl-dev #}
  - ssl.dev

mysql_diamond_collector:
  file:
    - managed
    - name: /etc/diamond/collectors/MySQLCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://mysql/server/diamond/config.jinja2
    - require:
      - file: /etc/diamond/collectors
      - service: mysql-server
    - watch_in:
      - service: diamond

mysql_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[mysql]]
        exe = ^\/usr\/sbin\/mysqld

libmysqlclient-dev:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
      - pkg: mysql

diamond_mysql_python:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/mysql.server
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://mysql/server/diamond/requirements.jinja2
    - require:
      - virtualenv: diamond
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/diamond
    - requirements: {{ opts['cachedir'] }}/pip/mysql.server
    - require:
      - virtualenv: diamond
      - pkg: python-dev
      - pkg: ssl-dev
      - pkg: libmysqlclient-dev
    - watch:
      - file: diamond_mysql_python
    - watch_in:
      - service: diamond

extend:
  diamond:
    service:
      - require:
        - service: mysql-server
