# -*- coding: utf-8 -*-

'''
Perform a NRPE check
'''

import logging
import re

logger = logging.getLogger(__name__)


def _check_list(config_dir='/etc/nagios/nrpe.d'):
    '''
    List all available NRPE check
    :param config_dir: path where config files are
    :return: dict of command name and their command line
    '''
    output = []
    regex = re.compile('^command\[([^\]]+)\]=(.+)$')
    for filename in __salt__['file.find'](config_dir, type="f"):
        with open(filename, 'r') as input_fh:
            for line in input_fh:
                match = regex.match(line)
                if match:
                    output[match.group(1)] = match.group(2)
    return output

def run_check(check_name):
    '''
    Run a specific nagios check
    '''
    checks = _check_list()
    ret = {
        'name': 'run_check',
        'changes': {},
    }

    if check_name not in checks:
        ret['result'] = False
        ret['comment'] = "Can't find check '{0}'".format(check_name)
        return ret

    output = __salt__['cmd.run_all'](checks[check_name], runas='nagios')
    ret['content'] = "stdout: '{stdout}' stderr: '{stderr}'".format(output)
    ret['result'] = output['retcode'] == 0
    return ret
