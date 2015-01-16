{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - cron.nrpe
  - nginx.nrpe
  - pysc.nrpe
  - ssh.client.nrpe
{% if salt['pillar.get']('jenkins:ssl', False) %}
  - ssl.nrpe
{%- endif %}

{{ passive_check('jenkins', check_ssl_score=True) }}
