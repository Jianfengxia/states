{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - doc
  - ssh.client
  - ssh.client.nrpe

test:
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test_pillar
    - name: ssh.client
    - pillar_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
