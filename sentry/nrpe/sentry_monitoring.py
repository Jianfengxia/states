#!/usr/local/sentry/bin/python

"""
Create organization/team/user for sentry monitoring
"""

__author__ = 'Diep Pham'
__maintainer__ = 'Diep Pham'
__email__ = 'favadi@robotinfra.com'

import os
import logging

import pysc

# Bootstrap the Sentry environment
from sentry.utils.runner import configure
configure('/etc/sentry.conf.py')

from sentry.models import Team, Project, ProjectKey, User, Organization

logger = logging.getLogger(__name__)


class SentryMonitoring(pysc.Application):
    def get_argument_parser(self):
        argp = super(SentryMonitoring, self).get_argument_parser()
        argp.add_argument(
            "--password", help="sentry_user_password", required=True)
        argp.add_argument(
            "--dsn-file", help="path to write monitoring sentry dsn",
            required=True)
        argp.add_argument(
            "--test", help="run in test mode", action="store_true")

        return argp

    def main(self):
        password = self.config["password"]
        dsn_file = self.config["dsn_file"]
        test_mode = self.config["test"]

        # create user
        user = User()
        user.username = "monitoring"
        user.is_superuser = False
        user.set_password(password)
        user.save()
        logger.debug("Sentry user monitoring is created")

        organization = Organization()
        organization.name = "Monitoring"
        organization.owner = user
        organization.save()
        logger.debug("Sentry organization Monitoring is created")

        team = Team()
        team.name = 'Monitoring'
        team.organization = organization
        team.owner = user
        team.save()
        logger.debug("Sentry team Monitoring is created")

        project = Project()
        project.team = team
        project.name = 'Monitoring'
        project.organization = organization
        project.save()
        logger.debug("Sentry project Monitoring is created")

        key = ProjectKey.objects.filter(project=project)[0]
        dsn = key.get_dsn()
        # disable verify_ssl in test mode
        if test_mode:
            dsn += "?verify_ssl=0"

        with open(dsn_file, "w") as f:
            f.write(dsn)

        os.chmod(dsn_file, 0440)

if __name__ == '__main__':
    SentryMonitoring().run()
