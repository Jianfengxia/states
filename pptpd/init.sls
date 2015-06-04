{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - pppd
  - rsyslog
  - sysctl

{%- set instances = salt['pillar.get']('pppd:instances', {}) -%}
{%- set pptp = instances.get('pptpd', {}) -%}
{%- set encryption = pptp.get('encryption', {}) %}

pptpd:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
      - pkg: ppp
  file:
    - managed
    - name: /etc/pptpd.conf
    - source: salt://pptpd/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: pptpd
  service:
    - running
    - enable: True
    - sig: /usr/sbin/pptpd
    - watch:
      - pkg: pptpd
      - file: pptpd
      {#- requires specific pillar key, look in pptp/doc/pillar.rst #}
      - file: ppp-options-pptpd
    - require:
      - service: rsyslog
      {#- requires specific pillar key, look in pptp/doc/pillar.rst #}
      - sysctl: net.ipv4.ip_forward

{%- if 'mppe-128' in encryption.get('require', []) %}
ppp_mppe:
  kmod:
    - present
    - persist: True
    - require_in:
      - service: pptpd
{%- endif %}
