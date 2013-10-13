{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Bruno Clermont patate@fastmail.cn
 -#}
include:
  - apt
  - php.dev
  - uwsgi

{%- if grains['osrelease']|float == 12.04 %}
symlink-libphp5.so:
  file:
    - symlink
    {%- if grains['cpuarch'] == 'i686' %}
    - name: /usr/lib/i386-linux-gnu/libphp5.so
    {%- else %}
    - name: /usr/lib/x86_64-linux-gnu/libphp5.so
    {%- endif %}
    - target: /usr/lib/php5/libphp5.so
    - require:
      - pkg: php-dev
  cmd:
    - wait
    - name: /sbin/ldconfig
    - watch:
      - file: symlink-libphp5.so
{%- endif %}

extend:
  uwsgi_build:
    file:
      - require:
        - pkg: php-dev
{% if grains['osrelease']|float == 12.04 %}
    cmd:
      - watch:
        - cmd: symlink-libphp5.so
{% endif %}
