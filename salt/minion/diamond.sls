{#
 Diamond statistics for Salt-Minion
#}
include:
  - diamond
  - rsyslog.diamond

salt_minion_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[salt.minion]]
        cmdline = ^\/usr\/bin\/python \/usr\/bin\/salt\-minion$
