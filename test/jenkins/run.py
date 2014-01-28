#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Wrapper around integration.py that allow to, optionally, run only a
specific set of test that match the argument in command line.

Argument can be either a string or a chunk such as "2/4" that mean from all
tests, it will be splitted into 4 groups and the second chunk will added to the
list.
You can mix argument such as: run.py diamond 1/3 nrpe 5/6
in a single line.

Copyright (c) 2013, Bruno Clermont
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
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'patate@fastmail.cn'

import sys
import subprocess
import os
from UserList import UserList

TEST_SCRIPT = "/root/salt/states/test/integration.py"


# http://stackoverflow.com/questions/2130016/
def chunks(l, n):
    """ Yield n successive chunks from l.
    """
    newn = int(1.0 * len(l) / n + 0.5)
    for i in xrange(0, n-1):
        yield l[i*newn:i*newn+newn]
    yield l[n*newn-newn:]


class Tests(UserList):
    def __init__(self, prefix='States.'):
        self._prefix = prefix
        self.__all_tests = None
        UserList.__init__(self)

    @property
    def all_tests(self):
        if not self.__all_tests:
            self.__all_tests = self._list_tests()
        return self.__all_tests

    def _list_tests(self):
        """
        :return: build list of all available tests
        """
        lines = subprocess.check_output((TEST_SCRIPT, '--list')).split(
            os.linesep)
        lines.reverse()
        # remove empty line
        del lines[0]
        output = []
        for line in lines:
            if line.startswith(self._prefix):
                output.append(line.split(':')[0])
            else:
                # first line that don't starts with prefix mean list is done
                output.sort()
        return output

    def add_chunk(self, slice_index, size):
        for test in list(chunks(self.all_tests, size))[slice_index - 1]:
            if test not in self.data:
                self.data.append(test)

    def add_filtered(self, keywords):
        """
        :param keywords: list of string to look in test name
        """
        for test in self.all_tests:
            for arg in keywords:
                if arg in test and test not in self.data:
                    self.data.append(test)


def main():
    suffix = '> /root/salt/stdout.log 2> /root/salt/stderr.log'
    if len(sys.argv) > 1:
        tests = Tests()
        args = sys.argv[1:]
        for arg in args:
            if '/' in args:
                str_index, str_size = arg.split('/')
                args.remove(arg)
                tests.add_chunk(int(str_index), int(str_size))
        tests.add_filtered(args)
        command = ' '.join((
            TEST_SCRIPT,
            ' '.join(tests),
            suffix
        ))
    else:
        command = ' '.join((TEST_SCRIPT, suffix))
    os.system(command)

if __name__ == '__main__':
    main()
