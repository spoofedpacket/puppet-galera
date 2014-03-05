# == Class: percona::haproxy
#
# === Examples
#
#   Assign class to node in foreman or add a node entry:
#
#   node percona-node1 {
#     class { 'percona::haproxy':   
#            haproxy_listener => 'pre_existing_listener_group',
#     }
#   }
#
#
#   By default, this class deploys an active-active haproxy load balancer.
#   If you want an active-backup (failover) load balancer, define as follows:
#
#   node percona-node1 {
#     class { 'percona::haproxy':   
#            haproxy_listener => 'pre_existing_listener_group',
#            haproxy_failover => true,
#            haproxy_primary  => true,
#     }
#   }
#
#   Note: Only one node can be haproxy_primary in this configuration. Define
#   the backup nodes without the haproxy_primary statement.
#
class percona::haproxy ( 
    $haproxy_listener = 'default_listener', 
    $haproxy_failover = false,
    $haproxy_primary = false, 
) {

  class { 'stdlib': }
  
  # Default options for HAproxy server statements in the listen block.
  $haproxy_default_options = [
       'check',
       'port', '9200',
       'inter', '2000',
       'rise', '2',
       'fall', '5',
  ]

  # Determine if we're running in active-active or active-backup mode and
  # set options accordingly.
  if $haproxy_failover and $haproxy_primary {
      $haproxy_options = $haproxy_default_options
  } 
  elsif $haproxy_failover {
      $haproxy_options = concat($haproxy_default_options,['backup'])
  }
  else {
      $haproxy_options = $haproxy_default_options
  }

  @@haproxy::balancermember { $fqdn:
    listening_service => $haproxy_listener,
    server_names      => $::hostname, 
    ipaddresses       => $::ipaddress,
    ports             => '3306',
    options           => $haproxy_options,
  }

}
