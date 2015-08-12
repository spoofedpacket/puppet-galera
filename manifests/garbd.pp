# == Class: percona::garbd
#
# Installs Galera Arbitrator daemon and joins it to a specified cluster:
#
# * http://www.codership.com/wiki/doku.php?id=galera_arbitrator 
#
# === Examples
#
#   Assign class to node in foreman or add a node entry:
#
#   node garbd-node1 {
#     class {'percona::garbd':   
#            cluster_name => 'cluster_in_need_of_garbd',
#            peer_ip => 'ip.of.peer.node',
#     }
#   }
#
class percona::garbd ( 
    $cluster_name = 'my_cluster', 
    $peer_ip      = '0.0.0.0', 
    $package_name = 'percona-xtradb-cluster-galera-2.x',
) {

    # Enable percona repo to get more up to date versions.
    include apt
  
    # Chain percona apt source, apt-get update (notify) and 
    # percona package install (depends on apt-get update running first).
    apt::source { 'percona':
        location   => 'http://repo.percona.com/apt',
        release    => $::lsbdistcodename,
        repos      => 'main',
        key        => {
            'id'     => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
            'server' => 'pool.sks-keyservers.net',
        },
    } ~> # Tell apt to update when percona source is in place
    exec { 'update':
      command     => "/usr/bin/apt-get update",
      refreshonly => true,
    } -> # Wait until apt has updated before installing package
    package { $package_name:
         alias   => 'galera',
         ensure  => installed,
    }
    # End of chain.

    file { '/etc/garbd':
        ensure => directory,
        mode    => '0755',
    }

    file { '/var/log/garbd':
        ensure => directory,
        mode    => '0755',
    }

    file { '/etc/logrotate.d/garbd':
        ensure => present,
        source => 'puppet:///modules/percona/garbd-logrotate',
    }

    # SSL key+cert for authenticated replication
    file { '/etc/garbd/replication-key.pem':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        source => 'puppet:///modules/percona/replication-key.pem',
        require => File['/etc/garbd'],
    }

    file { '/etc/garbd/replication-cert.pem':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        source => 'puppet:///modules/percona/replication-cert.pem',
        require => File['/etc/garbd/replication-key.pem'],
    }

    file { '/etc/init.d/garbd':
        ensure => present,
        mode    => '0755',
        source => 'puppet:///modules/percona/garbd-init',
    }

    file { '/etc/garbd/garbd.cfg':
        ensure => present,
        content => template("percona/garbd.cfg.erb"),
        require => File['/etc/garbd'],
    }

    service { 'garbd' :
        ensure      => running,
        enable      => true,
        require     => [ 
            Package['galera'],
            File['/etc/garbd/garbd.cfg',
                 '/etc/init.d/garbd',
                 '/etc/garbd/replication-cert.pem']
        ],
        subscribe => File['/etc/garbd/garbd.cfg']
    }
}
