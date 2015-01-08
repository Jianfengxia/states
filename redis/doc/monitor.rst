Monitor
=======

Mandatory
---------

.. |deployment| replace:: redis

.. _monitor-redis_procs:

redis_procs
~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Expected status: there are 1 or 2 processes with command line name
``redis-server`` running by user ``redis``

.. _monitor-redis_port:

redis_port
~~~~~~~~~~

Monitor :doc:`/redis/doc/index` local port :ref:`glossary-TCP` ``6379``.

.. _monitor-redis_remote_port:

redis_remote_port
~~~~~~~~~~~~~~~~~

Monitor :doc:`/redis/doc/index` remote port :ref:`glossary-TCP` ``6379``.

.. include:: /backup/doc/monitor.inc

.. include:: /backup/doc/monitor_procs.inc
