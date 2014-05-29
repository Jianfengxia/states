:Copyrights: Copyright (c) 2013, Hung Nguyen Viet

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
:Authors: - Bruno Clermont
          - Hung Nguyen Viet

====================
Jenkins Installation
====================

Follow the generic logic of pillar, apply formula and run checks, then perform
the followings.

First go in one of the hostname you specified at ``jenkins:web:hostnames``.

Things you **should** do
------------------------

- Restrict project naming.
- Set admin e-mail address.
- Create a user AND switch to Matrix based security to prevent anonymous user to
  have read-only access to Jenkins.
- Install https://wiki.jenkins-ci.org/display/JENKINS/Timestamper and turn it
  on to all jobs.
- Set ``[a-zA-Z0-9\-]*`` as regular expression for job name. As job name are
  used to create VM hostname, this need to be a valid hostname.

Things you **must** do
----------------------

- Raise number of executor to large value such as ``20``.
- Set Jenkins URL to first value of ``jenkins:web:hostnames``.
- Configure SMTP to send email for build status change.
- Install https://wiki.jenkins-ci.org/display/JENKINS/Multiple+SCMs+Plugin
- Upgrade SSH Credential Plugin to 1.6+, so you can configure SSH private key
  for user ``jenkins`` throught Jenkins Web UI. (Dashboard => Credential
  => Add credential => Kind: SSH username with private key)
- If you use git for SCM, install Git Plugin and upgrade it to  version 2.0 or
  above. It will allow you to choose credential when add a git SCM repo.
  Note that after upgrading, this plugin changes its name to
  "Jenkins GIT plugin". This is link to its page:
  https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin

Jobs
----

A testing job must be created with the following:

**Execute concurrent builds if necessary** turned on.

Select ``Multi SCM`` as **Source Code Management**. You need 3 repositories:

- Common states
- Non-common states
- Pillars repo

In each instance of Multi SCM, click 2nd ``Advanced...`` button and set the
**Local subdirectory for repo (optional)** to ``common``, ``non-common`` or
``pillar``.

Specify the tested branch, never put ``**`` or a single click on **build**
can trigger 200 builds.

In Build section, add a build step by choosing
``Add build step`` > ``Execute shell``::

    $WORKSPACE/common/test/jenkins/build.sh vim

which will run build script from path
``$WORKSPACE/common/test/jenkins/build.sh`` with one argument ``vim``,
this make build job run all test against ``vim`` formula.
To add more tests, just pass them as arguments to this script (separate
by space). To run all test, provide no argument.
