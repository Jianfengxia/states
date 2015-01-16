{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

-#}
libjs-underscore:
  pkgrepo:
    - absent
    - ppa: chris-lea/libjs-underscore
  pkg:
    - purged
  file:
    - absent
    - name: /etc/apt/sources.list.d/chris-lea-libjs-underscore-{{ grains['oscodename'] }}.list
    - require:
      - pkgrepo: libjs-underscore
