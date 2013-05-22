# -*- coding: utf-8 -*-
"""
Get some grains information that is only available in Amazon AWS

Author: Erik Günther
https://github.com/saltstack/salt/issues/1825

"""
import ast
import logging
import httplib
import socket
import datetime

# Set up logging
LOG = logging.getLogger(__name__)


def _call_aws(url):
    """
    Call AWS via httplib. require correct path to data will
    Host: 169.254.169.254

    """

    conn = httplib.HTTPConnection("169.254.169.254", 80, timeout=1)
    conn.request('GET', url)
    response = conn.getresponse()
    if response.status != 200:
        return ""

    data = response.read()
    return data


def _get_ec2_hostinfo():
    """
    Will return grain information about this host that is EC2 specific

    "kernelId" : "aki-12345678",
    "ramdiskId" : None,
    "instanceId" : "i-12345678",
    "instanceType" : "c1.medium",
    "billingProducts" : None,
    "architecture" : "i386",
    "version" : "2010-08-31",
    "accountId" : "123456789012",
    "imageId" : "ami-12345678",
    "availabilityZone" : "eu-west-1a",
    "pendingTime" : "2012-07-10T03:54:24Z",
    "devpayProductCodes" : None,
    "privateIp" : "10.XX.YY.ZZ",
    "region" : "eu-west-1",
    "local-ipv4" : "10.XX.YY.ZZ",
    "local-hostname" : "ip-10-XX-YY-ZZ.eu-west-1.compute.internal",
    "public-ipv4" : "AA.BB.CC.DD",
    "public-hostname" : "ec2-AA-BB-CC-DD.eu-west-1.compute.amazonaws.com"
    """

    grains = {}
    #Read the buffert, and convert it to a dict
    data = _call_aws("/latest/dynamic/instance-identity/document")
    #null isn't None so translate on the fly
    grains = ast.literal_eval(data.replace('null', 'None'))

    #Add some more default data
    grains['local-ipv4'] = _call_aws("/latest/meta-data/local-ipv4")
    grains['local-hostname'] = _call_aws("/latest/meta-data/local-hostname")

    grains['public-ipv4'] = _call_aws("/latest/meta-data/public-ipv4")
    grains['public-hostname'] = _call_aws("/latest/meta-data/public-hostname")

    return grains


def _ec2_info():
    """
    Collect some extra host information
    """
    empty = {'is_on_ec2': False}
    try:
        #First do a quick check if AWS magic URL work. If so we guessing that
        # we are running in AWS and will try to get more data.
        _call_aws('/')
    except:
        return empty

    try:
        grains = _get_ec2_hostinfo()
        if not grains:
            return empty
        return grains
    except socket.timeout, serr:
        LOG.info("Could not read EC2 data: %s" % (serr))
        return empty

def boot_datetime(proc_filename='/proc/uptime'):
    """
    When this host booted
    :return: exact time with microseconds precision when this host had booted
    :rtype: :class:`datetime.datetime`
    """
    uptime_file_handler = open(proc_filename, 'r')
    now = datetime.datetime.now()
    uptime_seconds = float(uptime_file_handler.readline().split()[0])
    delta = datetime.timedelta(seconds=uptime_seconds)
    return now - delta

def _cache_ec2_info(key_name):
    data = {
        'grains': _ec2_info(),
        'timestamp': boot_datetime()
    }
    __salt__['data.update'](key_name, data)
    return data['grains']

def ec2_info():
    key_name = 'ec2_info'
    try:
        data = __salt__['data.getval'](key_name)
    except KeyError:
        return _cache_ec2_info(key_name)
    if data['timestamp'] < boot_datetime():
        return _cache_ec2_info(key_name)
    return data['grains']

if __name__ == "__main__":
    print _ec2_info()
