{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

#}
{%- for key in salt['pillar.get']('sysctl', {}) %}

{{ key|replace(':','.') }}:
  sysctl:
    - present
    - value: {{ salt['pillar.get']('sysctl:' ~ key, False) }}
{%- endfor %}
