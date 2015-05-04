{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - firewall.diamond
  - rsyslog.diamond

fail2ban_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[fail2ban]]
        cmdline = ^\/usr\/bin\/python \/usr\/bin\/fail2ban-server

{%- from 'diamond/macro.jinja2' import fail2ban_count_ip with context %}
{{ fail2ban_count_ip('ssh') }}
