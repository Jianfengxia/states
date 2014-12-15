#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2013, Bruno Clermont
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Common repository integration tests

These unittest run on the salt master because the SSH server get installed
and uninstall. The only daemon that isn't killed in the process is Salt Minion.

Check file docs/run_tests.rst for details.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'bruno@robotinfra.com'

import logging
import pwd
import tempfile
import collections
import subprocess
try:
    import unittest2 as unittest
except ImportError:
    import unittest
import socket
import sys
import os
try:
    import xmlrunner
except ImportError:
    xmlrunner = None

import yaml

# until https://github.com/saltstack/salt/issues/4994 is fixed, logger must
# be configured before importing salt.client
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG,
                    format="%(asctime)s %(name)s (%(module)s.%(funcName)s:"
                           "%(lineno)d) %(message)s")

import salt.client

# global variables
logger = logging.getLogger()
# salt client
caller = salt.client.Caller('/root/salt/states/test/minion')
caller.opts.update({'id': socket.gethostname()})
caller.sminion = salt.minion.SMinion(caller.opts)
client = caller.function
# is a cleanup required before next test
is_clean = False
# has previous cleanup failed
clean_up_failed = False
# list of process before tests ran
process_list = set()
# list of files before tests ran
files_list = set()
# groups list
groups_list = set()
# users list
users_list = set()

NO_TEST_STRING = '-*- ci-automatic-discovery: off -*-'

all_states = client('cp.list_states')
ran_states_cntr = collections.Counter()


def if_change(result):
    """
    Check if changed occured in :func:`test_clean`
    :param result: result from :func:`salt.client.LocalClient.cmd`
    :type result: dict
    :return: True if any change
    :rtype: bool
    """
    for key in result:
        try:
            if result[key]['changes'] != {}:
                return True
        except TypeError:
            raise ValueError(result)
    return False


def tearDownModule():
    global client
    global ran_states_cntr
    logger.debug("Running tearDownModule")
    logger.info('COUNTER: Ran totally: %d States', (sum(ran_states_cntr.values())))
    logger.info('COUNTER: By state declaration: %s', ran_states_cntr)
    client('state.sls', 'test.teardown')


def setUpModule():
    """
    Prepare minion for tests, this is executed only once time.
    """
    global client
    logger.debug("Running setUpModule")

    # force HOME to be root directory
    os.environ['HOME'] = pwd.getpwnam('root').pw_dir

    client('saltutil.sync_all')
    client('saltutil.refresh_modules')
    logger.info("Rendering all *.test SLS to quickly find malformed ones")
    for sls in all_states:
        if sls.endswith('.test'):
            try:
                ret = client('state.show_sls', sls)
            except Exception as err:
                logger.error("Catch error: %s", err, exc_info=True)
                raise
            if isinstance(ret, list):
                # if render is okay, it returns dict, else, it returns list
                # of msg error
                raise Exception(ret)

    try:
        if client('pkg_installed.exists'):
            logger.info(
                "pkg_installed snapshot was found, skip setUpModule(). If you "
                "want to repeat the cleanup process, run "
                "'pkg_installed.forget'")
            return
    except KeyError, err:
        logger.debug("Catch error: %s", err, exc_info=True)
        # salt.client.Caller don't refresh the list of available modules
        # after running saltutil.sync_all, exit after doing it.
        client('saltutil.sync_all')
        logger.warning("Please re-execute: '%s'", ' '.join(sys.argv))
        sys.exit(0)

    def check_error(changes):
        """
        Check if any state failed in setUpModule
        """
        if type(changes) != dict:
            raise ValueError(changes)
        try:
            for change in changes:
                if not changes[change]['result']:
                    raise ValueError(changes[change]['comment'])
        except Exception, err:
            logger.error("Catch error: %s", err, exc_info=True)
            raise ValueError("%s: %s" % (err, changes))

    logger.info("Run state equivalent of unittest setup class/function.")
    check_error(client('state.sls', 'test.setup'))

    logger.info("Uninstall more packages, with deborphan.")
    ret = client('state.sls', 'test.clean')
    check_error(ret)
    while if_change(ret):
        logger.info("Still more packages to uninstall.")
        ret = client('state.sls', 'test.clean')
        check_error(ret)

    logger.info("Uninstall deborphan.")
    check_error(client('state.sls', 'deborphan.absent'))

    logger.info("Save state of currently installed packages.")
    output = client('pkg_installed.snapshot')

    try:
        if not output['result']:
            raise ValueError(output['comment'])
    except KeyError, err:
        logger.error("Catch error: %s", err, exc_info=True)
        raise ValueError(output)


def parent_process_id(pid):
    """
    Return the parent process id
    """
    status_file = '/proc/%d/status' % pid
    for line in open(status_file).readlines():
        if line.startswith('PPid'):
            return int(line.rstrip(os.linesep).split("\t")[1])
    raise OSError("can't get parent process id of %d" % pid)


def process_ancestors(pid):
    """
    Return the list of all process ancestor (pid).
    """
    output = []
    try:
        parent = parent_process_id(pid)
    except IOError, err:
        logger.debug("Process %d is already dead now", pid)
        raise err
    else:
        try:
            while parent != 0:
                output.append(parent)
                parent = parent_process_id(parent)
        except IOError, err:
            logger.debug("Ancestor %d is now dead", parent)
            raise err
    return output


def list_user_space_processes():
    """
    return all running processes on minion
    """
    global client
    result = client('status.procs')
    output = {}

    for pid in result:
        name = result[pid]['cmd']
        # kernel process are like this: [xfs], ignore them
        if name.startswith('['):
            continue
        output[int(pid)] = name
    return output


def list_non_minion_processes(cmd_name='/usr/bin/python /usr/bin/salt-minion'):
    """
    Return the command name of all processes that aren't executed
    by a minion
    """
    procs = list_user_space_processes()
    output = set()
    minion_pids = []

    # list all minions process
    for pid in procs:
        if procs[pid] == cmd_name:
            logger.debug("Found minion pid %d", pid)
            minion_pids.append(pid)
    logger.debug("Found total of %d minions", len(minion_pids))

    for pid in procs:
        try:
            ancestors = process_ancestors(pid)
        except IOError:
            pass
        else:
            run_through_minion = False
            for minion_pid in minion_pids:
                if minion_pid in ancestors:
                    logger.debug("Ignore %d proc %s as it's run by minion %d",
                                 pid, procs[pid], minion_pid)
                    run_through_minion = True
                    break

            if not run_through_minion:
                logger.debug("Running non-minion process %s[%d]", procs[pid],
                             pid)
                output.add(procs[pid])
    logger.debug("Running processes: %s", os.linesep.join(output))
    return output


def get_groups():
    """
    return a set of groups
    """
    global client
    return set(group['name'] for group in client('group.getent', True))


def get_users():
    global client
    return set(user['name'] for user in client('user.getent'))


def list_system_files(dirs=("/bin", "/etc", "/usr", "/lib", "/sbin", "/var"),
                      ignored=('/var/lib/ucf/',
                               '/var/lib/apt/lists/',
                               '/var/lib/libuuid/',
                               '/var/lib/dpkg/',
                               '/var/cache/apt/',
                               '/var/backups/',
                               '/var/log/upstart/network-interface-',
                               '/var/cache/salt/minion/extrn_files',
                               '/var/cache/salt/minion/doc')):
    """
    Returns a set of the files present in each of the directories listed.

    Most of the time it will only make sense to be called with absolute paths
    """
    ret = set()
    for directory in dirs:
        if os.path.isdir(directory):

            for filename in subprocess.check_output(["find",
                                                     directory]).split(
                    os.linesep):
                is_ignored = False
                for path in ignored:
                    if filename.startswith(path):
                        is_ignored = True
                        break
                if not is_ignored:
                    ret.add(filename)
    return ret


def render_state_template(state):
    """
    Return de-serialized data of specified state name
    """
    tmp = tempfile.NamedTemporaryFile(delete=False)
    tmp.close()
    state_path = state.replace('.', '/')
    for path_template in ('salt://{0}.sls', 'salt://{0}/init.sls'):
        source = path_template.format(state_path)
        client('cp.get_template', source, tmp.name)
        with open(tmp.name) as yaml_fh:
            try:
                data = yaml.safe_load(yaml_fh)
                if data:
                    logger.debug("Found state %s, return dict size %d",
                                 source, len(data))
                    os.unlink(tmp.name)
                    return data
                logger.debug("%s don't seem to exists", source)
            except Exception:
                logger.error("Can't parse YAML %s", source, exc_info=True)
    logger.error("Couldn't get content of %s", state)
    os.unlink(tmp.name)
    return {}


def run_salt_module(module_name, *args, **kwargs):
    try:
        output = client(module_name, *args, **kwargs)
    except Exception as err:
        logger.error("Catch error: %s", err, exc_info=True)
        raise Exception('Module:{0} error: {1}'.format(module_name, err))
    return output


class TestStateMeta(type):
    """
    Metaclass that create all the test_ methods based on
    state files auto-discovery.
    """

    nrpe_test_all_state = 'test.nrpe'

    @classmethod
    def func_name(mcs, state_name):
        return 'test_%s' % state_name.replace('.', '_')

    @classmethod
    def wrap_test_func(mcs, attrs, test_func_name, new_func_name, doc,
                       *args, **kwargs):
        """
        Wrap function ``self.test_func_name`` and put in into ``attrs`` dict
        """
        def output_func(self):
            func = getattr(self, test_func_name)
            logger.debug("Run unit %s", test_func_name)
            func(*args, **kwargs)
        output_func.__name__ = new_func_name
        output_func.__doc__ = doc
        logger.debug("Add method %s that run self.%s(...)", new_func_name,
                     test_func_name)
        attrs[new_func_name] = output_func

    @classmethod
    def add_test_integration(mcs, attrs, state):
        """
        add test for integration
        """
        state_test, state_diamond, state_nrpe = ('.'.join((state, s)) for s in
                                                 ('test', 'diamond', 'nrpe'))
        states = [state]

        def _add_include_check(state_integration, itype):
            '''
            Check whether a state has diamond and/or NRPE integration,
            If yes, add checks for missing `include` statement in these
            integration.
            '''
            if state_integration in attrs['all_states']:
                logger.debug("State {0} got {1} integration, add check "
                             "for include".format(state, itype))
                doc = ('Check includes for {0} integration for {1}'
                       '').format(itype, state)
                mcs.wrap_test_func(attrs,
                                   'check_integration_include',
                                   mcs.func_name(state_integration +
                                                 '_include'),
                                   doc,
                                   state,
                                   state_integration)
                states.append(state_integration)

        _add_include_check(state_diamond, 'Diamond')
        _add_include_check(state_nrpe, 'NRPE')

        if len(states) > 1:
            logger.debug("State %s got diamond/NRPE integration", state)
            if state_test in attrs['all_states']:
                logger.debug("State %s do have a custom test state, "
                             "don't create automatically one", state)
                mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                  'Test state %s' % state, [state])
            else:
                logger.debug("State %s don't have custom test state", state)
                doc = 'Test states %s and run all NRPE checks after' % \
                      ', '.join(states)
                states.append(mcs.nrpe_test_all_state)
                # add test for the .sls file
                mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                  'Test state %s' % state, [state])
                # and test for SLS file, and all corresponding integrations
                mcs.wrap_test_func(attrs, 'top',
                                  mcs.func_name(state) + '_with_checks',
                                  doc, states)
        else:
            logger.debug("No diamond/NRPE integration for state %s", state)
            mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                              'Test state %s' % state, [state])

    def __new__(mcs, name, bases, attrs):
        '''
        Return a class which consist of all needed test state functions
        '''
        global client
        global all_states
        # Get all SLSes to test
        attrs['all_states'] = all_states
        # don't play with salt.minion
        salt_minion_states = []
        for state in attrs['all_states']:
            if state.startswith('salt.minion'):
                salt_minion_states.append(state)
        # but still test its diamond and nrpe
        salt_minion_states.remove('salt.minion.nrpe')
        salt_minion_states.remove('salt.minion.diamond')
        logger.debug("Don't run tests for salt minion, as it can interfer: %s",
                     ','.join(salt_minion_states))
        attrs['all_states'] = list(set(attrs['all_states']) -
                                   set(salt_minion_states))

        attrs['absent'] = []

        # map SLSes to test methods then add to this class
        for state in attrs['all_states']:
            if state.startswith('test.') or state in ('top', 'overstate'):
                logger.debug("Ignore state %s", state)
            else:
                # skip SLS contains string that indicate NO-TEST
                spath = state.replace('.', '/')
                try:
                    logger.debug(('Trying to get content '
                                  'of salt://{0}.sls').format(spath))
                    content = run_salt_module(
                        'cp.get_file_str',
                        'salt://{0}.sls'.format(spath))
                    # NOTICE if above module running raises an exception,
                    # Salt will log it out. Therefore, no need to worry
                    # about that exception output.
                except Exception as err:
                    logger.debug(('salt://{0}.sls does not exist. '
                                  'Try salt://{0}/init.sls').format(spath))
                    try:
                        content = run_salt_module(
                                    'cp.get_file_str',
                                    'salt://{0}/init.sls'.format(spath))
                        logger.debug(('Got content of '
                                      'salt://{0}/init.sls').format(spath))
                    except Exception:
                        raise err
                if NO_TEST_STRING in content:
                    logger.debug('Explicit ignore state %s', state)
                    continue

                # add all other states
                if state.endswith('.absent'):
                    logger.debug("Add test for absent state %s", state)
                    # build a list of all absent states
                    attrs['absent'].append(state)
                    doc = 'Run absent state for %s' % state.replace('.absent',
                                                                    '')
                    # create test_$(SLS_name)_absent
                    mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                      doc, [state])
                else:
                    logger.debug("%s is not an absent state", state)

                    if state.endswith('.nrpe') or state.endswith('.diamond') \
                       or state.endswith('.test'):
                        logger.debug("Add single test for %s", state)
                        mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                          'Run test %s' % state, [state])
                    else:
                        # all remaining SLSes
                        mcs.add_test_integration(attrs, state)

        attrs['absent'].sort()
        return super(TestStateMeta, mcs).__new__(mcs, name, bases, attrs)


class States(unittest.TestCase):
    """
    Common logic to all Integration test class
    """

    __metaclass__ = TestStateMeta

    def _check_same_status(self, original, function, messages):
        """
        Checks that a set of things is invariant between runs. If `original`
        is None, `function` gets called and its return value saved in
        `original`. If not, `function` is called and its result value is
        compared against `original`. If they differ, the test fails.

        :params original: a set or None
        :params function: a function that returns a set
        :params messages: a list of 3 strings used for logging.
            - the first element must take an integer and is used when the set
              is first filled in (original is None)
            - the second element must take an integer and is used when the
              current value of `function` is compared to `original`
            - the third value must take a string, and it's used for the failure
              message
        """
        global clean_up_failed
        # check processes
        if not original:
            original.update(function())
            logger.debug(messages[0], len(original))
        else:
            current = function()
            logger.debug(messages[1], len(current))
            unclean = current - original

            if unclean:
                clean_up_failed = True
                return messages[2] % os.linesep.join(unclean)
        return ""

    def setUp(self):
        """
        Clean up the minion before each test.
        """
        global is_clean, clean_up_failed, process_list
        global files_list, users_list, groups_list

        if clean_up_failed:
            self.skipTest("Previous cleanup failed")
        else:
            logger.debug("Go ahead, cleanup never failed before")

        if is_clean:
            logger.debug("Don't cleanup, it's already done")
            return

        try:
            self.sls(self.absent)
        except AssertionError, err:
            clean_up_failed = True
            logger.error("Can't run all .absent: %s", err)
            self.fail(err)

        # Go back on the same installed packages as after :func:`setUpClass`
        logger.info("Unfreeze installed packages")
        try:
            output = client('pkg_installed.revert', True)
        except Exception, err:
            clean_up_failed = True
            logger.error("Catch error: %s", err, exc_info=True)
            self.fail(err)
        else:
            try:
                if not output['result']:
                    clean_up_failed = True
                    self.fail(repr(output))
            except TypeError, err:
                clean_up_failed = True
                logger.error("Catch error: %s", err, exc_info=True)
                self.fail(output)

        clean_up_errors = []
        clean_up_errors.append(
            self._check_same_status(process_list, list_non_minion_processes, [
                "First cleanup, keep list of %d process",
                "Check %d proccess",
                "Process that still run after cleanup: %s"]))
        clean_up_errors.append(
            self._check_same_status(files_list, list_system_files, [
                "First cleanup, keep list of %d files",
                "Check %d files",
                "Newly created files after cleanup: %s"]))
        clean_up_errors.append(
            self._check_same_status(groups_list, get_groups, [
                "First cleanup, keep list of %d groups",
                "Check %d groups",
                "Newly created groups after cleanup: %s"]))
        clean_up_errors.append(
            self._check_same_status(users_list, get_users, [
                "First cleanup, keep list of %d users",
                "Check %d users",
                "Newly created users after cleanup: %s"]))

        clean_up_errors_msg = os.linesep.join([e for e in clean_up_errors if e])
        if clean_up_errors_msg:
            logger.error(clean_up_errors)
            clean_up_failed = True
            self.fail(clean_up_errors_msg)

        is_clean = True

    def sls(self, states):
        """
        Apply specified list of states.
        """
        logger.debug("Run states: %s", ', '.join(states))
        try:
            output = client('state.sls', ','.join(states))
        except Exception, err:
            logger.error("Catch error: %s", err, exc_info=True)
            self.fail('states: %s. error: %s' % ('.'.join(states), err))
        # if it's not a dict, it's an error
        self.assertEqual(type(output), dict, output)

        # check that all state had been executed properly.
        # build a list of comment of all failed state.
        str_errors = ""

        # A sample output:
        #   pkg_|-vim_|-vim_|-latest:
        #     __run_num__: 5
        #     changes: {}
        #     comment: Package vim is already up-to-date.
        #     name: vim
        #     result: true
        global ran_states_cntr
        ran_states_cntr.update(sid.split('|')[0] for sid in output)
        for state in output:
            if not output[state]['result']:
                # remove not useful keys
                for key in ('result', '__run_num__'):
                    try:
                        del output[state][key]
                    except KeyError:
                        pass
                for key in ('comment', 'name'):
                    if key not in output[state]:
                        output[state][key] = \
                            "WARNING: no '%s' in result of '%s'" % (key, state)
                    logger.warning("Missing key '%s' in output[%s]: %s", key,
                                   state, output[state])
                str_errors += os.linesep.join((
                    output[state]['name'],
                    '=' * len(output[state]['name']),
                    output[state]['comment'],
                    ''
                ))

        if str_errors:
            self.fail("Failure to apply states '%s': %s%s" %
                      (','.join(states), os.linesep, str_errors))
        return output

    def top(self, states):
        """
        Somekind of top.sls
        Mostly, just a wrapper around :func:`sls` to specify that the state is
        not clean.

        If all states are .absent, no need to run a cleanup process between
        test units execution.
        """
        global is_clean
        is_clean = True
        for state in states:
            if state not in self.absent:
                logger.debug("state '%s' isn't an absent, mark unclean", state)
                is_clean = False
        if is_clean:
            logger.debug("All %d states (%s) are absent, don't mark unclean",
                         len(states), ','.join(states))
        logger.info("Run top: %s", ', '.join(states))
        self.sls(states)

    def check_integration_include(self, state, integration):
        """
        Check that Integration state (abc.nrpe) include the integration state
        of all state (abc) includes, such as def.nrpe.
        """
        integration_type = integration.split('.')[-1]
        logger.debug("Check integration include for %s (%s)", state,
                     integration_type)

        # list state include
        try:
            state_include = render_state_template(state)['include']
            logger.debug("State %s got %d include(s)", state,
                         len(state_include))
        except KeyError:
            logger.warn("State %s got no include", state)
            state_include = []

        # list integration include
        try:
            integration_include = render_state_template(integration)['include']
            logger.debug("Integration state %s got %d include(s)", integration,
                         len(integration_include))
        except KeyError:
            logger.warn("Integration state %s got no include", integration)
            integration_include = []

        # convert list of ['abc.nrpe, 'def.nrpe'] into ['abc', 'def']
        integration_state_include = []
        integration_suffix = '.' + integration_type
        for include in integration_include:
            integration_state_include.append(
                include.replace(integration_suffix, ''))
        logger.debug("Non-integration include in %s is %s", integration,
                     ','.join(integration_state_include))

        missing = []
        for potential_missing_include_state in set(state_include) - \
                set(integration_state_include):
            state_integration_include = '.'.join((
                potential_missing_include_state, integration_type))
            if state_integration_include in self.all_states:
                missing.append(state_integration_include)
                logger.error("State %s include %s while %s don't include %s",
                             state, potential_missing_include_state,
                             integration, state_integration_include)
            else:
                logger.debug("State %s include %s, but %s don't exists. OK.",
                             state, potential_missing_include_state,
                             state_integration_include)

        if missing:
            self.fail("Integration state %s of %s miss %d include: %s" % (
                      state, integration, len(missing), ','.join(missing)))

    def test_absent(self):
        """
        Just an empty run to test the absent states
        """
        pass

    @classmethod
    def list_tests(cls):
        """
        Display all available tests and what they do.
        """
        for item in dir(cls):
            if item.startswith('test_'):
                func = getattr(cls, item)
                print '%s.%s: %s ' % (cls.__name__, item,
                                      func.__doc__.strip())

if __name__ == '__main__':
    if '--list' in sys.argv:
        States.list_tests()
    else:
        if xmlrunner is not None:
            unittest.main(testRunner=xmlrunner.XMLTestRunner(
                output='/root/salt', outsuffix='salt'))
        else:
            unittest.main()
