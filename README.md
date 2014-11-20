adc-membership-control
======================

Manage members of Netscaler service groups.

This script uses the Netscaler Nitro REST API to manage the membership of
service group. It is possible to add and remove a server from a service group.

The script requires the Nitro perl module, which can usually be downloaded 
from a Netscaler appliance from the Downloads tab in the web UI. You will 
also need the JSON perl module.

Usage:

./adc-membership-control.pl --nsip <netscaler ip> --sericegroup <servicegroup> --username <username> --password <pwd> [--list|--add|--remove]
  --list         -l   - List members of service group
  --add          -a   - add server to service group
  --remove       -r   - Remove server from service group
  --nsip              - Netscaler IP address
  --servicegroup -s   - Netscaler service group
  --memberip     -m   - IP address of server to add/remove
  --memberport   -mp  - Port of server to add/remove
  --username     -u   - Auth username
  --password     -p   - Auth password
  --verbose      -v   - Verbose

