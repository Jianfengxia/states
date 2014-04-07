#!/usr/local/nagios/bin/python2
# -*- coding: utf-8 -*-

# Copyright (c) 2013, Hung Nguyen Viet
# All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

"""
NRPE script checks whether encoding of a database is same as expected.
"""

__author__ = 'Hung Nguyen Viet <hvnsweeting@gmail.com>'
__maintainer__ = 'Hung Nguyen Viet <hvnsweeting@gmail.com>'
__email__ = 'hvnsweeting@gmail.com'

import argparse
import logging
import subprocess
import nagiosplugin as nap

log = logging.getLogger('nagiosplugin')


class Encoding(nap.Resource):
    def __init__(self, dbname, encoding):
        self.dbname = dbname
        self.encoding = encoding

    def probe(self):
        '''
        A sample `psql -l` output

          Name    |  Owner   | Encoding  | Collate | Ctype |   Access privileges
        template0 | postgres | SQL_ASCII | C       | C     | =c/postgres          +
                  |          |           |         |       | postgres=CTc/postgres

        '''
        cmd = ['psql', '-l']
        log.info(cmd)
        output = subprocess.check_output(cmd).split('\n')
        log.debug(output)
        for line in output:
            cols = line.split(' | ')
            if (self.dbname == cols[0].strip() and
                self.encoding == cols[2].strip()):
                log.info(self.dbname)
                log.info('Expect: {0}, found {1}'.format(self.encoding,
                                                         cols[2].strip()))
                return [nap.Metric('encoding', 0, context='encoding')]
        return [nap.Metric('encoding', 1, context='encoding')]


@nap.guarded
def main():
    argp = argparse.ArgumentParser()
    argp.add_argument('--name', '-n', help='Database name', default='template0')
    argp.add_argument('--encoding', '-e', help='Encoding name', default='UTF8')
    argp.add_argument('-v', '--verbose', action='count', default=0)
    args = argp.parse_args()
    enc = Encoding(args.name, args.encoding)
    check = nap.Check(enc, nap.ScalarContext('encoding', '0:0', '0:0'))
    check.main(args.verbose)

if __name__ == "__main__":
    main()
