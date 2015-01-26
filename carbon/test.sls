{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
{%- from 'cron/test.jinja2' import test_cron with context %}
{%- from 'logrotate/macro.jinja2' import test_logrotate with context %}
include:
  - doc
  - carbon
  - carbon.backup
  - carbon.backup.diamond
  - carbon.backup.nrpe
  - carbon.nrpe
  - logrotate

{{ test_logrotate('/etc/logrotate.d/carbon') }}

{%- call test_cron() %}
- sls: carbon
- sls: carbon.backup
- sls: carbon.backup.diamond
- sls: carbon.backup.nrpe
- sls: carbon.nrpe
{%- endcall %}

carbon_relay_pid_check:
  file:
    - exists
    - name: /var/run/carbon-relay-a.pid
    - require:
      - sls: carbon

test:
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  qa:
    - test
    - name: carbon
    - additional:
      - carbon.backup
    - pillar_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
