# == Class: percona::node
#
# Installs and configures a percona node and associated MySQL service. 
# By default, this class configures a new cluster consisting of a single node.
# Subsequent nodes can be joined to the cluster by setting the $joiner parameter
# to true and nominating a donor via the $donor_ip parameter.
#
# === Parameters
# 
#   [*cluster_name*]
#    Type: String. Default: 'my_cluster'. Name of the cluster to create or join.
#
#   [*joiner*]
#    Type: Bool. Default: 'false'. Is the node joining an existing cluster?
#
#   [*donor_ip*] 
#    Type: String. Default: '0.0.0.0'. IP of pre-existing node to perform an
#    initial state transfer from when joining a cluster.
#
#   [*sst_method*] 
#    Type: String. Default: 'xtrabackup-v2'. SST (state transfer method) to when joining
#    a cluster. Other possibilities are 'xtrabackup', 'rsync' and 'mysqldump'. See galera docs for
#    further info.
#
#   [*sst_user*]
#    Type: String. Default: 'wsrep_sst'. MySQL user that performs the SST. Only used for the 'mysqldump' SST method.
#
#   [*sst_password*]
#    Type: String. Default: 'password'. Password for SST MySQL user.
#
#   [*root_password*]
#    Type: String. Default: 'password'. Password for the MySQL root user.
#
#   [*maint_password*]
#    Type: String. Default: 'maint'. Password for the debian_sys_maint MySQL user.
#
#   [*old_root_password*]
#     Type: String. Default: ''.
#
#   [*enabled*]
#     Type: Bool. Default: true. Enable or disable the MySQL/Percona service.
#
#   [*package_name*]
#     Type: String. Default: 'percona-xtradb-cluster-server-5.6'. Name of the percona package to install.
#
#   [*repo_location*]
#     Type: String. Default: 'http://repo.percona.com/apt'. Location of the apt repo to use.
#
#   [*wsrep_node_address*]
#     Type: String. Default: Undefined. Source IP address to use for xtrabackup etc.
#
#   [*ssl_replication*]
#     Type: Bool. Default: False. Enable wsrep encryption with SSL. You *must* set the ssl_replication_cert and
#     ssl_replication_key variables if this is enabled. This must be same across the cluster.
#
#   [*ssl_replication_cert*]
#     Type: String. Default: Undefined. SSL certificate to use for replication. This must be same across the cluster.
#
#   [*ssl_replication_key*]
#     Type: String. Default: Undefined. SSL key to use for replication. This must be same across the cluster.
#
#   It is also possible to set a number of parameters via the $tune_ variables and the $tune_other_options
#   array. Consult the MySQL documentation for these. As these values are very machine-dependent they should
#   be set with hiera or something similar:
#
#   database-server-with-loads-of-ram.yaml:
# 
#     ---
#     percona::node:tune_innodb_buffer_pool_size: '40G'
#     percona::node:tune_innodb_flush_method: 'O_DIRECT'
#
#   These variables are set to the defaults recommended by the MySQL documentation.
#
# === Examples
#
#   To create a new cluster from scratch:
#
#   node percona-node1 {
#     class { 'percona::node':   
#            cluster_name => 'cluster',
#     }
#   }
#
#   Add more nodes to the cluster once the first node is up and running: 
# 
#   node percona-node2 {
#     class { 'percona::node':   
#            cluster_name => 'cluster',
#            joiner       => true,
#            donor_ip     => 'ip.of.first.node',
#     }
#   }
#
#   Percona recommend not to add a large number of nodes at once as this could overwhelm the initial node with state transfer events.
#
#   !! IMPORTANT !!: In order to avoid the cluster becoming partitioned, the initial node
#   *must* be redefined as a joiner with a donor IP (*not* it's own address) once the cluster
#   has been fully created.
#
class percona::node (
    $cluster_name	     = 'my_cluster', 
    $joiner 		       = false,
    $donor_ip          = '0.0.0.0',
    $sst_method        = 'xtrabackup-v2',
    $sst_user          = 'wsrep_sst',
    $sst_password      = 'password',
    $root_password     = 'password',
    $maint_password    = 'maint',
    $old_root_password = '',
    $enabled           = true,
    $package_name      = 'percona-xtradb-cluster-server-5.6',
    $repo_location     = 'http://repo.percona.com/apt',
    $wsrep_node_address           = undef,
    $ssl_replication              = false,
    $ssl_replication_cert         = undef,
    $ssl_replication_key          = undef,
    $tune_innodb_buffer_pool_size = '134217728',
    $tune_innodb_data_file_path   = 'ibdata1:12M:autoextend',
    $tune_innodb_flush_method     = 'fsync',
    $tune_innodb_file_per_table   = '1',
    $tune_table_open_cache        = '2000',
    $tune_max_connections         = '151',
    $tune_wait_timeout            = '28800',
    $tune_tmp_table_size          = '16777216',
    $tune_max_heap_table_size     = '16777216',
    $tune_thread_cache_size       = '8',
    $tune_open_files_limit        = '5000',
    $tune_table_definition_cache  = '1400',
    $tune_other_options           = undef,
) {

  if $enabled {
   $service_ensure = 'running'
  } else {
   $service_ensure = 'stopped'
  }

  # Config files to watch/depend on. Add SSL cert if SSL replication is enabled.
  $default_config_files = ['/etc/mysql/my.cnf', '/etc/mysql/conf.d/wsrep.cnf', '/etc/mysql/conf.d/utf8.cnf',
                         '/etc/mysql/conf.d/tuning.cnf']
  if $ssl_replication {
    $mysql_config_files = concat($default_config_files, '/etc/mysql/replication-cert.pem')
  }
  else {
    $mysql_config_files = $default_config_files
  }

  # Enable percona repo to get more up to date versions.
  include apt

  # Chain percona apt source, apt-get update (notify) and 
  # percona package install (depends on apt-get update running first).
  apt::source { 'percona':
      location   => $repo_location,
      release    => $::lsbdistcodename,
      repos      => 'main',
      key        => {
          'id'     => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
          'server' => 'pool.sks-keyservers.net',
      },
  } ~>
  exec { 'update':
    command     => "/usr/bin/apt-get update",
    refreshonly => true,
  } ->
  package { $package_name:
       alias   => 'mysql-server',
       ensure  => installed,
  }
  # End of chain.

  # Create mysql user. Required for setting file ownership.
  user { 'mysql':
       ensure => present,
  }

  file { '/etc/mysql':
       ensure => directory,
       mode   => '0755',
  }
  file { '/etc/mysql/conf.d':
       ensure => directory,
       mode   => '0755',
  }

  file { "/etc/mysql/my.cnf":
       ensure  => present,
       source  => 'puppet:///modules/percona/my.cnf',
       require => File['/etc/mysql'],
  }

  file { "/usr/local/bin/perconanotify.py":
       ensure => present,
       source => 'puppet:///modules/percona/perconanotify.py',
       mode   => '0755',
  }

  file { "/etc/mysql/conf.d/wsrep.cnf":
       ensure  => present,
       owner   => 'mysql',
       group   => 'mysql',
       mode    => '0600',
       content => template("percona/wsrep.cnf.erb"),
       require => [
             File['/etc/mysql', '/etc/mysql/conf.d', '/usr/local/bin/perconanotify.py'],
             User['mysql'],
       ],
  }

  file { "/etc/mysql/conf.d/utf8.cnf":
       ensure  => present,
       source => 'puppet:///modules/percona/utf8.cnf',
       require => File['/etc/mysql', '/etc/mysql/conf.d'],
  }

  file { "/etc/mysql/conf.d/tuning.cnf":
       ensure  => present,
       content => template('percona/tuning.cnf.erb'),
       require => File['/etc/mysql', '/etc/mysql/conf.d'],
  }

  file { '/etc/mysql/debian.cnf':
       ensure  => present,
       owner   => 'mysql',
       group   => 'mysql',
       mode    => '0600',
       content => template('percona/debian.cnf.erb'),
       require => [
             Service['mysql'], # I want this to change after a refresh
             File['/etc/mysql', '/etc/mysql/conf.d'],
             User['mysql'],
       ],
  }

  # If required, SSL key+cert for encrypted replication
  if $ssl_replication {
    file { '/etc/mysql/replication-key.pem':
         ensure  => present,
         owner   => 'mysql',
         group   => 'mysql',
         mode    => '0600',
         content => $ssl_replication_key,
         require => [
               File['/etc/mysql', '/etc/mysql/conf.d'],
               User['mysql'],
         ]
    }

    file { '/etc/mysql/replication-cert.pem':
         ensure  => present,
         owner   => 'mysql',
         group   => 'mysql',
         mode    => '0644',
         content  => $ssl_replication_cert,
         require => File['/etc/mysql/replication-key.pem'],
    }

    if !$ssl_replication_cert {
      fail("SSL replication enabled but cert not provided. Bailing out.")
    }

    if !$ssl_replication_key {
      fail("SSL replication enabled but key not provided. Bailing out.")
    }
  }

  file { '/etc/logrotate.d/percona':
       ensure  => present,
       source  => 'puppet:///modules/percona/percona-logrotate',
  }

  file { '/root/.my.cnf':
       content => template('percona/my.cnf.pass.erb'),
       mode    => '0600',
       require => Exec['set_mysql_rootpw'],
  }

  # This kind of sucks, that I have to specify a difference resource for
  # restart.  the reason is that I need the service to be started before mods
  # to the config file which can cause a refresh
  exec { 'mysqld-restart':
    command     => "service mysql restart",
    logoutput   => on_failure,
    refreshonly => true,
    path        => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
  }

  # manage root password if it is set
  if $root_password != 'UNSET' {
    case $old_root_password {
      '':      { $old_pw='' }
      default: { $old_pw="-p${old_root_password}" }
    }

    exec { 'set_mysql_rootpw':
      command   => "mysqladmin -u root ${old_pw} password ${root_password}",
      logoutput => true,
      unless    => "mysqladmin -u root -p${root_password} status > /dev/null",
      path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
      notify    => Exec['mysqld-restart'],
      require   => [File['/etc/mysql/conf.d'],Service['mysql']],
    }

     exec { "set-mysql-password-noroot":
        unless      => "/usr/bin/mysql -u${sst_user} -p${sst_password}",
        command     => "/usr/bin/mysql -uroot -p -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${sst_user}'@'%' identified by '${sst_password}';flush privileges;\"",
        require     => Service["mysql"],
        subscribe   => Service["mysql"],
        refreshonly => true,
    }
  }

    exec { "set-mysql-password":
        unless      => "/usr/bin/mysql -u${sst_user} -p${sst_password}",
        command     => "/usr/bin/mysql -uroot -p${root_password} -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${sst_user}'@'%' identified by '${sst_password}';flush privileges;\"",
        require     => Service["mysql"],
        subscribe   => Service["mysql"],
        refreshonly => true,
    }

  # The debian-sys-maint user needs to have identical credentials across the cluster
  percona::rights { 'debian-sys-maint user':
       database        => '*',
       user            => 'debian-sys-maint',
       password        => $maint_password,
       priv            => 'SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER',
       grant_option    => true,
       require         => [
          Service['mysql'],
          File['/root/.my.cnf']
      ],
  }

  service { 'mysql':
        name        => "mysql",
        ensure      => $service_ensure,
        enable      => $enabled,
        require     => [ 
            Package['mysql-server'],
            File[$mysql_config_files],
        ],
        hasrestart  => true,
	      hasstatus   => true,
        subscribe   => File[$mysql_config_files],
  }
}
