{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

/etc/nagios/nrpe.d/mysql.cfg:
  file:
    - absent

/usr/lib/nagios/plugins/check_mysql_query.py:
  file:
    - absent

{%- from 'nrpe/passive.jinja2' import passive_absent with context %}
{{ passive_absent('mysql.server') }}
