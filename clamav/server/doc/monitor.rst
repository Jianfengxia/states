Monitor
=======

Mandatory
---------

.. _monitor-freshclam_procs:

freshclam_procs
~~~~~~~~~~~~~~~

:ref:`clamav-freshclam` :ref:`glossary-daemon` check.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-clamav_procs:

clamav_procs
~~~~~~~~~~~~

:doc:`index` :ref:`glossary-daemon` provides virus scanning service.

.. _monitor-clamav_last_update:

clamav_last_update
~~~~~~~~~~~~~~~~~~

:doc:`index` database was updated since ``1`` day ago or less.

Optional
--------

clamav_last_scan
~~~~~~~~~~~~~~~~

:doc:`index` full scan was run and no virus found since ``1``
day ago or less.
