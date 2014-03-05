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
class percona::garbd ( $cluster_name = 'my_cluster', $peer_ip = '0.0.0.0' ) {

    # Add percona repository and key
    include percona::repo
   
    # Only basic galera package required for garbd
    $package_name = 'percona-xtradb-cluster-galera-2.x'
 
    package { $package_name:
         alias    => 'galera',
         require  => Apt::Source['percona'],
    }

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
