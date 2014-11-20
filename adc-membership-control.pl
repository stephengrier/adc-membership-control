#!/usr/bin/perl -w
###############################################################################
# adc-membership-control.pl - manage members of Netscaler service groups.
#
# This script uses the Netscaler Nitro REST API to manage the membership of
# service group. It is possible to add and remove a server to a service group.
#
# Stephen Grier <s.grier at ucl.ac.uk>, Nov 2014.
###############################################################################

use Getopt::Long;
use Nitro;
use strict;
use Data::Dumper;

sub usage {
  die "Usage: $0 --nsip <netscaler ip> --sericegroup <servicegroup> --username <username> --password <pwd> [--list|--add|--remove]
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
";
}

my $session = undef;

my ($list, $add, $remove, $nsip, $memberip, $memberport, $username, $password, $servicegroup, $verbose);

GetOptions(
  'list|l' => \$list,
  'add|a' => \$add,
  'remove|r' => \$remove,
  'nsip=s' => \$nsip,
  'memberip|m=s' => \$memberip,
  'memberport|mp=s' => \$memberport,
  'servicegroup|s=s' => \$servicegroup,
  'username|u=s' => \$username,
  'password|p=s' => \$password,
  'verbose|v' => \$verbose
);

# Sanity.
if ((!$list && !$add && !$remove) ||
    ($list && $add) ||
    ($list && $remove) ||
    ($add && $remove) ||
    (($add || $remove) && !($memberip && $memberport)) ||
    !$nsip || !$servicegroup || !$username || !$password) {
  usage();
}

&main();

sub main() {
  login();

  if ($list) {
    getServiceGroupMembers($servicegroup);
  }
  elsif ($add) {
    bindServiceGroupMember($servicegroup, $memberip, $memberport);
  }
  elsif ($remove) {
    unbindServiceGroupMember($servicegroup, $memberip, $memberport);
  }
  logout();
}

#########
## Log in to Netscaler appliance.
##
## @returns undef
###
sub login() {
  $session = Nitro::_login($nsip, $username, $password);
  print "Login :\t$session->{message}\n";
  if ($session->{errorcode} != 0 || !($session->{sessionid})) {
    exit;
  }
}

#########
## Get all service group members.
##
## @param servicegroup The service group name
## @returns undef
###
sub getServiceGroupMembers() {
  my $_servicegroup = shift;
  my $servicegroupmembers = Nitro::_get($session, "servicegroup_servicegroupmember_binding", $_servicegroup);
  print "Members of servicegroup $servicegroup:\n";
  if ($servicegroupmembers->{errorcode} != 0) {
    print $servicegroupmembers->{message}."\n";
  } else {
    my $servicegroupmemberbinding = $servicegroupmembers->{"servicegroup_servicegroupmember_binding"};
    foreach my $binding (@{$servicegroupmemberbinding}) {
      print "\tname: $binding->{servername} \t ip: $binding->{ip} \t state: $binding->{state}\n";
    }
  }
}

#########
# Get a single service group member.
#
# @param servicegroup The service group name
# @param memberip The IP address of the member
# @returns A hashref containing values for the member.
##
sub getServiceGroupMember() {
  my ($_servicegroup, $_memberIP) = @_;
  my $member = Nitro::_get($session, "servicegroup_servicegroupmember_binding", $_servicegroup, "filter=ip:${_memberIP}");
  if ($member->{errorcode} != 0) {
    print $member->{message}."\n";
  } else {
  my $binding = $member->{"servicegroup_servicegroupmember_binding"}[0];
    return $binding;
  }
}

#########
## Unbind a member from a service group.
##
## @param servicegroup The service group name
## @param memberip The IP address of the member
## @param memberport The port of the member
## @returns A hashref containing the result
###
sub unbindServiceGroupMember() {
  my ($_servicegroup, $_serverIP, $_port) = @_;
  my $_binding = {};
  $_binding->{'servicegroupname'} = $_servicegroup;
  $_binding->{'ip'} = $_serverIP;
  $_binding->{'port'} = $_port;
  my $result = Nitro::_delete($session, "servicegroup_servicegroupmember_binding", $_binding);
  print "Unbind servicegroup member:\t$result->{message}\n";
  return $result;
}

#########
### Bind a member to a service group.
###
### @param servicegroup The service group name
### @param memberip The IP address of the member
### @param memberport The port of the member
### @returns A hashref containing the result
####
sub bindServiceGroupMember() {
  my ($_servicegroup, $_serverIP, $_port) = @_;
  my $_binding = {};
  $_binding->{'servicegroupname'} = $_servicegroup;
  $_binding->{'ip'} = $_serverIP;
  $_binding->{'port'} = $_port;
  my $result = Nitro::_post($session, "servicegroup_servicegroupmember_binding", $_binding, 'bind');
  print "Bind servicegroup member:\t$result->{message}\n";
}

#########
## Log out of Netscaler appliance.
##
## @returns undef
###
sub logout() {
  my $result = Nitro::_logout($session);
  print "Logout :\t$result->{message}\n";
}

