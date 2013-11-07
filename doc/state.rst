Salt State
==========

:copyrights: Copyright (c) 2013, Bruno Clermont

             All rights reserved.

             Redistribution and use in source and binary forms, with or without
             modification, are permitted provided that the following conditions
             are met:

             1. Redistributions of source code must retain the above copyright
             notice, this list of conditions and the following disclaimer.
             2. Redistributions in binary form must reproduce the above
             copyright notice, this list of conditions and the following
             disclaimer in the documentation and/or other materials provided
             with the distribution.

             THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
             "AS IS" AND ANY EXPRESS OR IMPLIED ARRANTIES, INCLUDING, BUT NOT
             LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
             FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
             COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
             INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES(INCLUDING,
             BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
             LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
             CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
             LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
             ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
             POSSIBILITY OF SUCH DAMAGE.
:authors: - Bruno Clermont

This document define the standard structure of the states.

As the states are applied automatically in various way, there is a requirements
to have specific standard regarding states structure.

Basic
-----

*Status: Mandatory*

A very simple state without any kind of integration can be a single ``.sls``
file in state Git repository, such as ``gcc.sls``.

But if there is any kind of integration, they need to be under the state name
directory, such as ``gcc/init.sls``.

Absent
------

*Status: Optional*

All states should have an ``$statename.absent`` (``$statename/absent.sls``) that
uninstall all the states specifics, remove non-shared users and data files.

This is not just used to uninstall an application, it's also used by testing
framework to removed previously installed states, so they install cleanly when
they're re-executed.

.. warning::

   Don't include any other state that aren't ``.absent`` themselves!
   Unless that you'll ends with conflicts as you might have the state included
   **and** it's ``.absent`` counterpart.

Monitoring Checks
-----------------

If the state deploy an application that is persistent into memory, such as
daemon or a reccurent task that leave persistant data on the file-system:

*Status: Mandatory*

If the deployed application is a library, or small requirements for others that
don't have persistence impact on the server:

*Status: Optional*

Monitoring checks are handled by ``$statename.nrpe`` (``$statename/nrpe.sls`` OR
``$statename/npre/init.sls`` if you're monitoring checks state requires
additional files such as check script or NRPE configuration template).

If you add new monitoring checks, you have to make them available to NRPE (see
``doc/monitoring.rst`` for more details on that) as a file in
``/etc/nagios/nrpe.d/$statename-$suffix.cfg``. Check other NRPE integration in
common states for examples.

.. warning::
   Your addition monitoring NRPE checks state must include ``nrpe`` state.
   It must require ``- pkg: nagios-nrpe-server`` and watch_in
   ``- service: nagios-nrpe-server``.

If you need to install files to fill your monitoring requirements, you **must**
have a ``$statename.nrpe.absent`` to uninstall them.

Analytics (Stats)
-----------------

If the state deploy an application that is persistent into memory, such as
daemon, or a job that run a long time frequently, such as backup script:

*Status: Mandatory*

If the deployed application is a library, or small requirements for others that
don't have persistence impact on the server:

*Status: Optional*

Diamond (``diamond`` state) is used to gather OS metrics and send it to Graphite
(``graphite`` state) stats server.

So it's integration in your state need to be in ``$statename.diamond``.

It support many collectors
https://github.com/BrightcoveOS/Diamond/tree/master/src/collectors
if any of these collectors are specific to deployed software, please turn it on.
Check in salt common states for many examples of that.

If you state deploy one or multiple daemon that run constantly, you have to add
it to the list of processes that the CPU and Memory usage stats are sent.
TODO: document this process.

If you turn on Diamond collector, you have to add a file to it's configuration
directory in ``/etc/diamond/collectors/$CollectorNameClass.conf``.

Check other diamond integration in common states for examples.

.. warning::
   Your addition monitoring NRPE checks state must include ``nrpe`` state.
   It must require ``- file: /etc/diamond/collectors`` and watch_in
   ``- service: diamond``.

If Diamond integration requires installation of additional files, you **must**
have a ``$statename.diamond.absent`` file.

Tests
-----

*Status: Optional*

Test are executed automatically and all available monitoring checks are
executed. For more details, check ``doc/tests.sls``.

But your state might need custom steps to setup the test, or just need to wait
few seconds to let the cluster initialize before running all the tests.
You might want to have additional tests, or handle failure in NRPE checks.

To overwrite default behavior of test and checks, you need to create a
``$statename.test`` (or ``$statename/test.sls`` file).

For more details on that file content, look at ``doc/tests.rst`` section
*Test Validation*.

Ordering
--------

*Status: Mandatory*

All services should have the ``order`` argument specified with value ``50``:
http://docs.saltstack.com/ref/states/ordering.html?highlight=order#the-order-option
such as::

  cron:
    pkg:
      - latest
    service:
      - running
      - enable: True
      - order: 50
      - watch:
        - pkg: cron

Ordering is only used for testing framework, this make sure that test are run
with order ``last`` while all services are started with an order that make sure
everything is deployed and running before test run.

Monitoring Auto-Discovery
-------------------------

If you have *Monitoring Checks* integration:

*Status: Mandatory*

If not:

*Status: Optional*

Monitoring checks need to declare to the monitoring server how to perform those
checks. Monitoring server will auto-discover in other ways which Minion perform
those checks and how to send alert.

The state must only declare the list of check in the YAML Jinja2 template file
``salt://$state/monitor.jinja2``.

It must match the checks you created into *Monitoring Checks* section.

Here is the file format with Jinja comment inline for explaination::

   check_name:
   {# ID of this check: allowed-characters: _-[a-z][A-Z][0-9].
      it's also used as the NRPE check name if ``check`` keyword isn't
      defined. #}

     check: check_something!argument
     {# Shinken command to perform, by default it's a NRPE check in the
        following format: check_nrpe!{{ check_name }}.
        Available shinken command:
          * check_nrpe!{{ check_name }}
          * check_ping
          * check_tcp!{{ port_number }} #}

     description: Check BigDaemon process
     {# Human readable description of this check. Must be very clear as it will
        be used in web interface and notification. #}

     {# Addition optional Shinken parameters.
        Frequently used  Shinken service options:
          * check_interval: how many seconds before each check
          * retry_interval: how long in seconds before retry a check after a
            failure.
          * notifications_enabled: if non OK status ends with notification
          * notification_options: which kind of error send notification for:
            ``c`` such as critical
        More information on this in
        http://www.shinken-monitoring.org/wiki/official/configuringshinken/configobjects/service
      #}

   {# follow by more check definition #}

Please check for all file with name ``monitor.jinja2`` for examples.
