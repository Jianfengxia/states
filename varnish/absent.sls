{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

varnish:
  pkg:
    - purged
    - require:
      - service: varnish
  service:
    - dead

{% set varnish_dirs = ['/etc/varnish', '/var/lib/varnish'] %}
{% for dir in varnish_dirs %}
{{ dir }}:
  file:
    - absent
    - require:
      - pkg: varnish
{% endfor %}

{%- for user in ('varnish', 'varnishlog') %}
{{ user }}_user:
  user:
    - absent
    - name: {{ user }}
    - purge: True
    - require:
      - pkg: varnish
  group:
    - absent
    - name: {{ user }}
    - require:
      - user: {{ user }}_user
{%- endfor %}

varnishlog_statoverride:
  file:
    - replace
    - name: /var/lib/dpkg/statoverride
    - pattern: "^varnishlog .+\n"
    - repl: ''
    - require:
      - group: varnishlog_user
