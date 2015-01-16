{#-
-*- ci-automatic-discovery: off -*-

Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
include:
  - diamond
  - python.dev
  - postgresql
  - postgresql.common.user
  - rsyslog.diamond

diamond_collector-psycopg2:
  file:
    - managed
    - name: /usr/local/diamond/salt-postgresql-requirements.txt
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://postgresql/common/diamond/requirements.jinja2
    - require:
      - virtualenv: diamond
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/diamond
    - requirements: /usr/local/diamond/salt-postgresql-requirements.txt
    - watch:
      - pkg: python-dev
      - pkg: postgresql-dev
      - file: diamond_collector-psycopg2
    - watch_in:
      - service: diamond

postgresql_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[postgresql]]
        exe = ^\/usr\/lib\/postgresql/\d+\.\d+\/bin\/postgres$

postgresql_diamond_collector:
  file:
    - managed
    - name: /etc/diamond/collectors/PostgresqlCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://postgresql/common/diamond/config.jinja2
    - require:
      - file: /etc/diamond/collectors
    - watch_in:
      - service: diamond

extend:
  diamond:
    service:
      - watch:
        - postgres_database: postgresql_monitoring
