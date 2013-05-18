{#
 Uninstall a RabbtiMQ server
 #}

rabbitmq-server:
  pkg:
{% if pillar['destructive_absent']|default(False) %}
    - purged
{% else %}
    - removed
{% endif %}
    - require:
      - service: rabbitmq-server
  service:
    - dead
    - enable: False

/etc/rabbitmq:
  file:
    - absent
{# until https://github.com/saltstack/salt/issues/5027 is fixed, this is required #}
    - sig: beam{% if grains['num_cpus'] > 1 %}.smp{% endif %}
    - require:
      - pkg: rabbitmq-server

rabbitmq:
  user:
    - absent
    - require:
      - service: rabbitmq-server
      - file: /etc/rabbitmq
