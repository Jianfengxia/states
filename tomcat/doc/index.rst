..
   Author: Viet Hung Nguyen <hvn@robotinfra.com>
   Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>

Tomcat
======

Introduction
------------

Apache Tomcat_ is an open source software implementation of the
:doc:`/java/doc/index` Servlet and
JavaServer Pages technologies. The :doc:`/java/doc/index` Servlet and
JavaServer Pages specifications are developed under the :doc:`/java/doc/index`
Community Process.

Tomcat6 or Tomcat7
------------------

Users should choose the version which they used for developing
:doc:`/java/doc/index` application.
Consults `this page for more information
<http://tomcat.apache.org/whichversion.html>`_.

- Apache Tomcat_ 6.x builds upon the improvements made in Tomcat_ 5.5.x and
  implements the Servlet 2.5 and JSP 2.1 specifications. In addition to that,
  it includes the following improvements::

    Memory usage optimizations
    Advanced IO capabilities
    Refactored clustering

- Apache Tomcat_ 7.x builds upon the improvements made in Tomcat_ 6.0.x and
  implements the Servlet 3.0, JSP 2.2, EL 2.2 and Web Socket 1.1
  specifications. In addition to that, it includes the following improvements::

    Web application memory leak detection and prevention
    Improved security for the Manager and Host Manager applications
    Generic CSRF protection
    Support for including external content directly in a web application
    Refactoring (connectors, lifecycle) and lots of internal code clean-up

.. warning::

   Tomcat_ 6.x and Tomcat_ 7.x can't both be installed in a machine.

Links
-----

* `Apache Tomcat page <http://tomcat.apache.org/>`_
* `Wikipedia <http://en.wikipedia.org/wiki/Apache_Tomcat>`_

Related Formula
---------------

* :doc:`/apt/doc/index`

Content
-------

.. toctree::
    :glob:

    *

.. _Tomcat: http://tomcat.apache.org

