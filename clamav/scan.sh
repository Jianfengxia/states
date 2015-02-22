#!/bin/bash
# Use of this is governed by a license that can be found in doc/license.rst.
# Run a full scan on / except some directories ( /sys, /dev, /proc, /run)

# limit resources usage
renice -n 19 -p $$ > /dev/null
ionice -c idle -p $$

# safe guard
set -o nounset
set -o errexit
set -o pipefail

readonly status_file=/var/lib/clamav/last-scan

# log start stop time to syslog
source /usr/local/share/salt_common.sh
# Ensure that only one instance of this script is running at a time
locking_script
log_start_script "$@"
trap "log_stop_script \$?" EXIT

exclude_list=('sys' 'dev' 'proc' 'run')

exclude_string=""
for exclude in "${exclude_list[@]}"; do
    exclude_string="$exclude_string""! -name $exclude "
done

scan_list=$(find / -maxdepth 1 -mindepth 1 $exclude_string | xargs)

retval=""
clamdscan --fdpass --quiet $scan_list | logger -t clamdscan -p local0.info; \
    retval="$?" || true

case "$retval" in
    0 )  # no virus found
        touch "$status_file"
        exit 0 ;;
    1 )  # virus(es) found
        echo 'Virus(es) found!' | logger -t clamdscan -p local0.error
        exit 1 ;;
    2 )  # an error occured
        echo 'An error occured!' | logger -t clamdscan -p local0.error
        exit 2 ;;
esac
