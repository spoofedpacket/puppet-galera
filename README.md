# Percona Module

Puppet class to manage a percona cluster along with HAproxy load balancers. 

Largely based on https://github.com/Jimdo/puppet-galera

Installs and configures a percona node and associated MySQL/Percona service. 
By default, this class configures a new cluster consisting of a single node.
Subsequent nodes can be joined to the cluster by setting the $joiner parameter
to true and nominating a donor via the $donor_ip parameter.

## Requirements
   * camptocamp/augeas
   * puppetlabs/apt
   * puppetlabs/stdlib
   * To use the dynamically generated haproxy configs on the client, a working PuppetDB with storeconfigs enabled, in order to use exported resources. This is optional, but highly recommended for production clusters.

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
 
### percona::node

####`cluster_name`

Type: String. Default: 'my_cluster'. Name of the cluster to create or join.

####`joiner`

Type: Bool. Default: 'false'. Is the node joining an existing cluster?

####`donor_ip` 

Type: String. Default: '0.0.0.0'. IP of pre-existing node to perform an
initial state transfer from when joining a cluster.

####`sst_method` 

Type: String. Default: 'xtrabackup-v2'. SST (state transfer method) to use when joining
a cluster. Other possibilities are 'xtrabackup', 'rsync' and 'mysqldump'. See percona docs for
further info.

####`sst_user`

Type: String. Default: 'wsrep_sst'. MySQL user that performs the SST. Only used for the 'mysqldump' SST method.

####`sst_password`

Type: String. Default: 'password'. Password for SST MySQL user.

####`root_password`

Type: String. Default: 'password'. Password for the MySQL root user.

####`maint_password`

Type: String. Default: 'maint'. Password for the debian_sys_maint MySQL user.

####`old_root_password`

Type: String. Default: ''.

####`enabled`

Type: Bool. Default: true. Enable or disable the MySQL/Percona service.

####`package_name`

Type: String. Default: 'percona-xtradb-cluster-server-5.6'. Name of the percona package to install.

####`repo_location`
Type: String. Default: 'http://repo.percona.com/apt'. Location of the apt repo to use.

####`percona_notify_from`
Type: String. Default: 'percona-noreply@example.com˙. From address for percona notifications.

####`percona_notify_to`
Type: String. Default: 'root@localhost'. Where to send percona notifications.

####`wsrep_node_address`
Type: String. Default: Undefined. Source IP address to use for xtrabackup etc.

####`ssl_replication`
Type: Bool. Default: False. Enable wsrep encryption with SSL. You *must* set the ssl_replication_cert 
and ssl_replication_key variables if this is enabled. This must be same across the cluster.

####`ssl_replication_cert`
Type: String. Default: Undefined. SSL certificate to use for replication. This must be same across the cluster.

####`ssl_replication_key`
Type: String. Default: Undefined. SSL key to use for replication. This must be same across the cluster.

### MySQL tuning

It is also possible to set a number of parameters via the $tune_ variables and the $tune_other_options
array. Consult the MySQL documentation for these. As these values are very machine-dependent they should
be set with hiera or something similar:

   database-server-with-loads-of-ram.yaml:

     ---
     percona::node:tune_innodb_buffer_pool_size: '40G'
     percona::node:tune_innodb_flush_method: 'O_DIRECT'

These variables are set to the defaults recommended by the MySQL documentation.
