{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
include:
  - shinken.broker
  - shinken.broker.diamond
  - shinken.broker.nrpe

{%- set check_list = [('shinken_broker_http_port', 'Connection refused'),
                    ('shinken_broker_http', 'Connection refused'),
                    ('shinken.broker_nginx_http', 'Invalid HTTP response')] %}

{%- if salt['pillar.get']('shinken:ssl', False) %}
    {%- set check_list = check_list + [('shinken.broker_nginx_https', 'Invalid HTTP response')] %}
{%- endif %}

{%- call test_cron() %}
- sls: shinken.broker
- sls: shinken.broker.diamond
- sls: shinken.broker.nrpe
{%- endcall %}

{% for name, failure in check_list %}
{{ name }}:
  monitoring:
    - run_check
    - accepted_failure: {{ failure }}
    - require:
      - sls: shinken.broker.nrpe
{%- endfor %}

test:
  monitoring:
    - run_all_checks
    - order: last
    - exclude:
{%- for name, _ in check_list %}
      - {{ name }}
{%- endfor %}
    - require:
      - cmd: test_crons
{%- for name, _ in check_list %}
      - monitoring: {{ name }}
{%- endfor %}
