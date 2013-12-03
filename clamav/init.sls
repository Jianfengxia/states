{#-
Copyright (c) 2013, Hung Nguyen Viet
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

Clamav: A virus scanner.
-#}
include:
  - apt

clamav-freshclam:
  pkg:
    - latest
    - require:
      - cmd: apt_sources
  module:
    - wait
    - name: service.stop
    - m_name: clamav-freshclam
    - watch:
      - pkg: clamav-freshclam
  cmd:
    - wait
    - name: freshclam --stdout -v
    - require:
      - file: clamav-freshclam
      - module: clamav-freshclam
    - watch:
      - pkg: clamav-freshclam
  file:
    - managed
    - name: /etc/clamav/freshclam.conf
    - source: salt://clamav/freshclam.jinja2
    - template: jinja
    - mode: 400
    - user: clamav
    - group: clamav
    - require:
      - pkg: clamav-freshclam
  service:
    - running
    - order: 50
    - require:
      - cmd: clamav-freshclam
    - watch:
      - file: clamav-freshclam
      - pkg: clamav-freshclam

clamav-daemon:
  pkg:
    - latest
    - require:
      - cmd: apt_sources
      - pkg: clamav-freshclam
  service:
    - running
    - order: 50
    - require:
      - service: clamav-freshclam
    - watch:
      - pkg: clamav-daemon

