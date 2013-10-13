{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Hung Nguyen Viet hvnsweeting@gmail.com
 
 Remove carbon
 -#}
{%- set prefix = '/etc/init.d/' %}
{%- set init_files = salt['file.find'](prefix, name='carbon-cache-*', type='f') %}
{%- for filename in init_files %}
  {% set instance = filename.replace(prefix + 'carbon-cache-', '') %}
carbon-cache-{{ instance }}:
  file:
    - absent
    - name: /etc/init.d/carbon-cache-{{ instance }}
    - require:
      - service: carbon-cache-{{ instance }}
  service:
    - dead
    - enable: False
{# until https://github.com/saltstack/salt/issues/5027 is fixed, this is required #}
    - sig: /usr/local/graphite/bin/python /usr/local/graphite/bin/carbon-cache.py --config=/etc/graphite/carbon.conf --instance={{ instance }} start
{% endfor %}

/usr/local/graphite/salt-carbon-requirements.txt:
  file:
    - absent

carbon-relay:
  file:
    - absent
    - name: /etc/init.d/carbon-relay
    - require:
      - service: carbon-relay
  service:
    - dead
    - enable: False
    - sig: /usr/local/graphite/bin/python /usr/local/graphite/bin/carbon-relay.py --config=/etc/graphite/carbon.conf start

/etc/graphite/relay-rules.conf:
  file:
    - absent
    - require:
      - service: carbon-relay

{% for file in ('/etc/logrotate.d/carbon', '/var/log/graphite/carbon', '/etc/graphite/storage-schemas.conf', '/etc/graphite/carbon.conf', '/var/lib/graphite/whisper') %}
{{ file }}:
  file:
    - absent
    - require:
{% for filename in init_files %}
  {% set instance = filename.replace(prefix + 'carbon-cache-', '') %}
      - service: carbon-cache-{{ instance }}
  {% endfor %}
      - service: carbon-relay
{% endfor %}
