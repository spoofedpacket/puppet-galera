# Percona Module

Puppet class to manage a percona cluster along with HAproxy load balancers. 

Largely based on https://github.com/Jimdo/puppet-galera

Installs and configures a percona node and associated MySQL/Percona service. 
By default, this class configures a new cluster consisting of a single node.
Subsequent nodes can be joined to the cluster by setting the $joiner parameter
to true and nominating a donor via the $donor_ip parameter.

## Requirements

   * puppetlabs/stdlib
   * haproxy
   * Working PuppetDB with storeconfigs enabled, in order to use exported resources.

## Usage

   Assign class percona::node via your favourite ENC or simply add a node entry.

### Create a new cluster from scratch

  ```puppet
  node percona-node1 {
     class { 'percona::node':   
            cluster_name => 'cluster',
     }
   }
  ```

   !! IMPORTANT !!: In order to avoid the cluster becoming partitioned, the initial node
   *must* be redefined as a joiner with a donor IP (*not* it's own address) once the cluster
   has been fully created:

  ```puppet
   node percona-node1 {
     class { 'percona::node':   
            cluster_name => 'cluster',
            joiner       => true,
            donor_ip     => 'ip.of.donor',
     }
   }
  ```
### Load balancing/failover

#### Servers

   This node definition will add the node to a HAproxy listener group that's declared
   on the clients (see Clients section below). 

   ```puppet
   node percona-node1 {
     class { 'percona::haproxy':   
            haproxy_listener => 'loadbalanced_mysql',
     }
   }
   ```

   By default, this class deploys an active-active haproxy load balancer.
   If you want an active-backup (failover) load balancer, define as follows:

   ```puppet
   node percona-node1 {
     class { 'percona::haproxy':   
            haproxy_listener => 'loadbalanced_mysql',
            haproxy_failover => true,
            haproxy_primary  => true,
     }
   }
   ```
   Note: Only one node can be haproxy_primary in this configuration. Define
   the backup nodes without the haproxy_primary statement.

#### Load balancer(s)

  Define a HAproxy load balancer consisting of the servers defined above.

  ```puppet
  haproxy::listen { $haproxy_listener:
    ipaddress  => '127.0.0.1',
    ports      => '3306',
    options    => {
     'option'  => [
       'tcpka',
       'httpchk',
        'tcplog',
     ],
     'balance' => 'leastconn',
    },
  }
  ```
## Parameters
 
###`cluster_name`

Type: String. Default: 'my_cluster'. Name of the cluster to create or join.

###`joiner`

Type: Bool. Default: 'false'. Is the node joining an existing cluster?

###`donor_ip` 

Type: String. Default: '0.0.0.0'. IP of pre-existing node to perform an
initial state transfer from when joining a cluster.

###`sst_method` 

Type: String. Default: 'xtrabackup'. SST (state transfer method) to when joining
a cluster. Other possibilities are 'rsync' and 'mysqldump'. See percona docs for
further info.

###`sst_user`

Type: String. Default: 'wsrep_sst'. MySQL user that performs the SST. Only used for the 'mysqldump' SST method.

###`sst_password`

Type: String. Default: 'password'. Password for SST MySQL user.

###`root_password`

Type: String. Default: 'password'. Password for the MySQL root user.

###`maint_password`

Type: String. Default: 'maint'. Password for the debian_sys_maint MySQL user.

###`old_root_password`

Type: String. Default: ''.

###`enabled`

Type: Bool. Default: true. Enable or disable the MySQL/Percona service.

## Author

Robert Gallagher <rob@spoofedpacket.net>
