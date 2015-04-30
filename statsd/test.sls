{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - statsd
  - statsd.diamond
  - statsd.nrpe

test:
  monitoring:
    - run_all_checks
    - order: last
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('statsd') }}
    - require:
      - sls: statsd
      - sls: statsd.diamond
  qa:
    - test
    - name: statsd
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
