{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - diamond
  - cron.diamond
  - nginx.diamond

doc_publish_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[doc_publish]]
        exe = ^\/etc\/cron.hourly\/doc\-publish$
