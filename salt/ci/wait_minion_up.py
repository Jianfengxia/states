#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2013, <HUNG NGUYEN VIET>
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
'''
__author__ = 'Hung Nguyen Viet'
__maintainer__ = 'Bruno Clermont, Hung Nguyen viet'
__email__ = 'patate@fastmail.cn, hvnsweeting@gmail.com'

import sys
import logging
import datetime

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG,
                    format="%(asctime)s %(message)s")

import salt.client

client = salt.client.LocalClient()
logger = logging.getLogger(__name__)


def wait_minion_up(minion_id, max_wait):
    output = {}
    start = datetime.datetime.now()
    while minion_id not in output:
        output = client.cmd_full_return(minion_id, 'test.ping', timeout=2)
        delta = datetime.datetime.now() - start
        if not output:
            logger.info("Minion %s is still not up after %d seconds", minion_id,
                        delta.seconds)
            if delta.seconds > max_wait:
                print "Timeout of %d seconds reached to connect minion %s" % (
                    max_wait, minion_id
                )
                sys.exit(1)
        else:
            logger.info("Minion %s is finally up after %d seconds", minion_id,
                        delta.seconds)

if __name__ == '__main__':
    wait_minion_up(sys.argv[1], 300)
