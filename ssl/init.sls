{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt

ssl-cert:
  pkg:
    - latest
    - require:
      - cmd: apt_sources

{% for name in salt['pillar.get']('ssl:certs', {}) -%}
/etc/ssl/{{ name }}:
  file:
    - absent

{%- set server_key = salt['pillar.get']('ssl:certs:' + name + ':server_key') | indent(8) -%}
{%- set server_crt = salt['pillar.get']('ssl:certs:' + name + ':server_crt') | indent(8) -%}
{%- set ca_crt = salt['pillar.get']('ssl:certs:' + name + ':ca_crt') | indent(8) %}

/etc/ssl/private/{{ name }}.key:
  file:
    - managed
    - contents: |
        {{ server_key }}
    - user: root
    - group: ssl-cert
    - mode: 440
    - require:
      - pkg: ssl-cert

/etc/ssl/certs/{{ name }}.crt:
  file:
    - managed
    - contents: |
        {{ server_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
    - require:
      - pkg: ssl-cert

/etc/ssl/certs/{{ name }}_ca.crt:
  file:
    - managed
    - contents: |
        {{ ca_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
    - require:
      - pkg: ssl-cert

{#-
Create from server private key and certificate a PEM used by most daemon
that support SSL.
#}
/etc/ssl/private/{{ name }}.pem:
  file:
    - managed
    - contents: |
        {{ server_crt }}
        {{ server_key }}
    - user: root
    - group: ssl-cert
    - mode: 440
    - require:
      - pkg: ssl-cert

{#- This is for ejabberd #}
/etc/ssl/private/{{ name }}_bundle.pem:
  file:
    - managed
    - contents: |
        {{ server_crt }}
        {{ server_key }}
        {{ ca_crt }}
    - user: root
    - group: ssl-cert
    - mode: 440
    - require:
      - pkg: ssl-cert

{#-
Some browsers may complain about a certificate signed by a well-known
certificate authority, while other browsers may accept the certificate without
issues. This occurs because the issuing authority has signed the server
certificate using an intermediate certificate that is not present in the
certificate base of well-known trusted certificate authorities which is
distributed with a particular browser. In this case the authority provides a
bundle of chained certificates which should be concatenated to the signed server
certificate. The server certificate must appear before the chained certificates
in the combined file:
#}
/etc/ssl/certs/{{ name }}_chained.crt:
  file:
    - managed
    - contents: |
        {{ server_crt }}
        {{ ca_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
    - require:
      - pkg: ssl-cert

{#- OpenSSL expects to find each certificate in a file named by the certificate
    subject's hashed name, plus a number extension that starts with 0.

    That means you can't just drop My_Awesome_CA_Cert.pem in the directory and
    expect it to be picked up automatically. However, OpenSSL ships with
    a utility called c_rehash which you can invoke on a directory
    to have all certificates indexed with appropriately named symlinks.

    http://mislav.uniqpath.com/2013/07/ruby-openssl/#SSL_CERT_DIR #}
ssl_create_symlink_by_hash_for_{{ name }}:
  cmd:
    - wait
    - name: c_rehash /etc/ssl/certs > /dev/null
    - watch:
      - file: /etc/ssl/certs/{{ name }}.crt
      - file: /etc/ssl/certs/{{ name }}_ca.crt
      - file: /etc/ssl/certs/{{ name }}_chained.crt

{#- as service need to watch all cert files, use this cmd as trigger that
    service restart everywhen cert files changed #}
ssl_cert_and_key_for_{{ name }}:
  cmd:
    - wait
    - name: echo managed ssl cert for {{ name }}
    - watch:
      - file: /etc/ssl/private/{{ name }}.key
      - file: /etc/ssl/certs/{{ name }}.crt
      - file: /etc/ssl/certs/{{ name }}_ca.crt
      - file: /etc/ssl/private/{{ name }}.pem
      - file: /etc/ssl/certs/{{ name }}_chained.crt
      - file: /etc/ssl/private/{{ name }}_bundle.pem
    - require:
      - cmd: ssl_create_symlink_by_hash_for_{{ name }}
{% endfor -%}
