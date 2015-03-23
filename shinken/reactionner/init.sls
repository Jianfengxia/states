{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{% set ssl = salt['pillar.get']('shinken:ssl', False) %}
include:
  - pysc
  - rsyslog
  - salt.event
  - shinken
{% if ssl %}
  - ssl
{% endif %}

shinken-reactionner:
  file:
    - managed
    - name: /etc/init/shinken-reactionner.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://shinken/upstart.jinja2
    - context:
        shinken_component: reactionner
  service:
    - running
    - enable: True
    - order: 50
    - require:
      - file: /var/lib/shinken
      - file: /var/run/shinken
    - watch:
      - cmd: shinken
      - file: /etc/shinken/reactionner.conf
      - user: shinken
      - file: shinken-reactionner
{% if ssl %}
      - cmd: ssl_cert_and_key_for_{{ ssl }}
{% endif %}
{#- does not use PID, no need to manage #}

{{ manage_upstart_log('shinken-reactionner') }}

/etc/shinken/reactionner.conf:
  file:
    - managed
    - template: jinja
    - user: shinken
    - group: shinken
    - mode: 440
    - source: salt://shinken/config.jinja2
    - context:
        shinken_component: reactionner
    - require:
      - virtualenv: shinken
      - user: shinken
      - file: /etc/shinken

/etc/sudoers.d/salt_event_handler:
  file:
    - managed
    - template: jinja
    - source: salt://shinken/reactionner/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
      - user: shinken

/usr/local/shinken/bin/salt_event_handler:
  file:
    - managed
    - source: salt://shinken/reactionner/salt_event_handler.py
    - template: jinja
    - user: root
    - group: shinken
    - mode: 550
    - require:
      - virtualenv: shinken
      - file: /usr/local/bin/salt_fire_event.py
    - require_in:
      - service: shinken-reactionner

{%- set xmpp = salt["pillar.get"]("shinken:xmpp", False) %}
{%- if xmpp %}
/etc/shinken/notify-by-xmpp.yml:
  file:
    - managed
    - contents: |
        jid: {{ xmpp["jid"] }}
        password: {{ xmpp["password"] }}
        recipients: {{ xmpp["recipients"]|default([])|yaml }}
        rooms: {{ xmpp["rooms"]|default([])|yaml }}
    - user: shinken
    - group: shinken
    - mode: 440
    - require:
      - virtualenv: shinken
      - file: /etc/shinken
    - require_in:
      - service: shinken-reactionner

/usr/local/shinken/bin/notify-by-xmpp:
  file:
    - managed
    - source: salt://shinken/reactionner/notify-by-xmpp.py
    - template: jinja
    - user: root
    - group: shinken
    - mode: 550
    - require:
      - file: /etc/shinken/notify-by-xmpp.yml
      - module: shinken
    - require_in:
      - service: shinken-reactionner
{%- else %}
/etc/shinken/notify-by-xmpp.yml:
  file:
    - absent

/usr/local/shinken/bin/notify-by-xmpp:
  file:
    - absent
{%- endif %}
