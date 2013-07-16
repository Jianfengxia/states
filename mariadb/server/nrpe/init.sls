{#
 Nagios NRPE checks for mariadb
#}
include:
  - nrpe
  - apt.nrpe

/etc/nagios/nrpe.d/mysql.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://mariadb/server/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/mysql.cfg
