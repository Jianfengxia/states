Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/postgresql/doc/index` :doc:`/postgresql/doc/pillar`
- :doc:`/nginx/doc/index` :doc:`/nginx/doc/pillar`

Mandatory
---------

Example::

  mattermost:
    hostnames:
      - mm.example.com

mattermost:hostnames
~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

Optional
--------

Example::

  mattermost:
    ssl: example_com
    ssl_redirect: True

.. _pillar-mattermost-enable_team_creation:

mattermost:enable_team_creation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether to enable creating new team or not.

Default: enabled (``True``).

.. _pillar-mattermost-enable_user_creation:

mattermost:enable_user_creation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether to enable creating new user or not.

Default: enabled (``True``).

.. _pillar-mattermost-ssl:

mattermost:ssl
~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-mattermost-ssl_redirect:

mattermost:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

mattermost:db:password
~~~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/password.inc

mattermost:at_rest_encrypt_key
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Default: ``None``, randomly generated by Salt.

mattermost:public_link_salt
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Default: ``None``, randomly generated by Salt.

mattermost:invite_salt
~~~~~~~~~~~~~~~~~~~~~~

Default: ``None``, randomly generated by Salt.

mattermost:password_reset_salt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Default: ``None``, randomly generated by Salt.
