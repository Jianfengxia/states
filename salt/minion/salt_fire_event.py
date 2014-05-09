#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2013, Quan Tong Anh
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
A script to fire events as non-root user
"""

__author__ = 'Quan Tong Anh'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'tonganhquan.net@gmail.com'

import os
import sys
import salt.syspaths as syspaths
import salt.config
import salt.client
import json
import argparse
import logging


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-p', '--payload', help="The event payload", type=json.loads, required=True)
    parser.add_argument('-t', '--tag', help="The event tag", type=str, required=True)

    if len(sys.argv[1:]) == 0:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()

    payload = args.payload
    tag = args.tag

    try:
        caller = salt.client.Caller(os.path.join(syspaths.CONFIG_DIR, 'minion'))
    except IOError as e:
        print('{0}. You need root permissions to run this script'.format(e))
        sys.exit(1)

    caller.sminion.functions['event.fire_master'](data=payload, tag=tag)

    logger = logging.getLogger(sys.argv[0])
    handler = logging.FileHandler(filename=os.path.join(syspaths.LOGS_DIR, 'event'))
    formatter = logging.Formatter('%(asctime)s [%(name)s] [%(levelname)s] %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.debug("An event has been fired as '%s': data=%s, tag=%s", os.getenv("SUDO_USER"), payload, tag)


if __name__ == '__main__':
    main()
