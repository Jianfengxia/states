Monitor
=======

Mandatory
---------

.. _monitor-dovecot_master_procs:

dovecot_master_procs
~~~~~~~~~~~~~~~~~~~~

``dovecot`` process is the Dovecot master process which keeps everything
running.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-dovecot_config_procs:

dovecot_config_procs
~~~~~~~~~~~~~~~~~~~~

``dovecot/config`` daemon parses the configuration file and sends the
configuration to other processes.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-dovecot_log_procs:

dovecot_log_procs
~~~~~~~~~~~~~~~~~

``dovecot/log`` writes to log files. All logging, except from master process,
goes through it.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-dovecot_anvil_procs:

dovecot_anvil_procs
~~~~~~~~~~~~~~~~~~~

``anvil`` keeps track of user connections

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-dovecot_imap:

dovecot_imap
~~~~~~~~~~~~

:doc:`/dovecot/doc/index` IMAP protocol is functional.

.. _monitor-dovecot_pop:

dovecot_pop
~~~~~~~~~~~

:doc:`/dovecot/doc/index` POP3 protocol is functional.

.. _monitor-dovecot_managesieve_port:

dovecot_managesieve_port
~~~~~~~~~~~~~~~~~~~~~~~~

`Dovecot Managesieve <http://wiki2.dovecot.org/Pigeonhole/ManageSieve>`__
port is listening and can be accessed locally.

dovecot_port_imap
~~~~~~~~~~~~~~~~~

Dovecot IMAP Port port is listening and can be accessed locally.


dovecot_port_pop3
~~~~~~~~~~~~~~~~~

Dovecot POP3 Port port is listening and can be accessed locally.

Optional
--------

.. _monitor-dovecot_spop:

dovecot_spop
~~~~~~~~~~~~

:doc:`/dovecot/doc/index` POP3 protocol over :doc:`/ssl/doc/index`
is functional.

.. _monitor-dovecot_simap:

dovecot_simap
~~~~~~~~~~~~~

:doc:`/dovecot/doc/index` IMAP protocol over :doc:`/ssl/doc/index`
is functional.

.. _monitor-dovecot_port_pop3s:

dovecot_port_pop3s
~~~~~~~~~~~~~~~~~~

Dovecot POP3S Port port is listening and can be accessed locally.

.. _monitor-dovecot_port_imaps:

dovecot_port_imaps
~~~~~~~~~~~~~~~~~~

Dovecot IMAPS port is listening and can be accessed locally.
