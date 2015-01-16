{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
{%- set version = "1.3.0" -%}
{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('etherpad') }}

extend:
  etherpad:
    user:
      - absent
      - purge: True
      - require:
        - service: etherpad

/usr/local/etherpad-lite-{{ version }}:
  file:
    - absent
    - require:
      - service: etherpad

/etc/nginx/conf.d/etherpad.conf:
  file:
    - absent
    - require_in:
      - service: etherpad
