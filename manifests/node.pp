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
#    Type: String. Default: 'xtrabackup'. SST (state transfer method) to when joining
#    a cluster. Other possibilities are 'rsync' and 'mysqldump'. See galera docs for
#    further info.
#   [*sst_user*]          = 'wsrep_sst',
#   [*sst_password*]      = 'password',
#   [*root_password*]     = 'password',
#   [*maint_password*]    = 'maint',
#   [*old_root_password*] = '',
#   [*enabled*]           = true,
#
# === Examples
#
#   Assign class to node in foreman or add a node entry:
#
#   To create a new cluster from scratch:
#
#   node percona-node1 {
#     class { 'percona::node':   
#            cluster_name => 'cluster',
#     }
#   }
#
#   !! IMPORTANT !!: In order to avoid the cluster becoming partitioned, the initial node
#   *must* be redefined as a joiner with a donor IP (*not* it's own address) once the cluster
#   has been fully created:
#
#   node percona-node1 {
#     class { 'percona::node':   
#            cluster_name => 'cluster',
#            joiner       => true,
#            donor_ip     => 'ip.of.donor',
#     }
#   }
#
class percona::node (
    $cluster_name	     = 'my_cluster', 
    $joiner 		       = false,
    $donor_ip          = '0.0.0.0',
    $sst_method        = 'xtrabackup',
    $sst_user          = 'wsrep_sst',
    $sst_password      = 'password',
    $root_password     = 'password',
    $maint_password    = 'maint',
    $old_root_password = '',
    $enabled           = true,
) {

  include percona::repo
   
  $package_name = 'percona-xtradb-cluster-server-5.5'
 
  if $enabled {
   $service_ensure = 'running'
  } else {
   $service_ensure = 'stopped'
  }

  package { $package_name:
       alias   => 'mysql-server',
       require => Apt::Source['percona'],
  }

  file { "/etc/mysql/my.cnf":
       ensure  => present,
       content => template("percona/my.cnf.erb"),
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
             Package['mysql-server'],
             File['/usr/local/bin/perconanotify.py'],
       ]
  }

  # Very machine-dependant. Should make this into a template
  # with values sourced from heira or $somewhere_else.
  file { "/etc/mysql/conf.d/tuning.cnf":
       ensure  => present,
       source => 'puppet:///modules/percona/tuning.cnf',
  }

  file { "/etc/mysql/conf.d/utf8.cnf":
       ensure  => present,
       source => 'puppet:///modules/percona/utf8.cnf',
  }

  file { '/etc/mysql/debian.cnf':
       ensure  => present,
       owner   => 'mysql',
       group   => 'mysql',
       mode    => '0600',
       content => template('percona/debian.cnf.erb'),
       require => [
             Package['mysql-server'],
             Service['mysql'], # I want this to change after a refresh
         ],
  }

  # SSL key+cert for authenticated replication
  file { '/etc/mysql/replication-key.pem':
       ensure  => present,
       owner   => 'mysql',
       group   => 'mysql',
       mode    => '0600',
       source  => 'puppet:///modules/percona/replication-key.pem',
  }

  file { '/etc/mysql/replication-cert.pem':
       ensure  => present,
       owner   => 'mysql',
       group   => 'mysql',
       mode    => '0644',
       source  => 'puppet:///modules/percona/replication-cert.pem',
       require => File['/etc/mysql/replication-key.pem']
  }

  file { '/root/.my.cnf':
       content => template('mysql/my.cnf.pass.erb'),
       mode    => '0600',
       require => Exec['set_mysql_rootpw'],
  }

  file { '/etc/mysql':
     ensure => directory,
     mode   => '0755',
  }
  file { '/etc/mysql/conf.d':
     ensure => directory,
     mode   => '0755',
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
            File['/etc/mysql/my.cnf',
                 '/etc/mysql/conf.d/wsrep.cnf',
                 '/etc/mysql/replication-cert.pem']
        ],
        hasrestart  => true,
	      hasstatus   => true,
        subscribe => File['/etc/mysql/my.cnf',
                          '/etc/mysql/conf.d/wsrep.cnf',
                          '/etc/mysql/conf.d/tuning.cnf',
                          '/etc/mysql/conf.d/utf8.cnf'],
    }
}
