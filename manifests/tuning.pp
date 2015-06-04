# == Class: percona::tuning
#
# Machine/application-dependant tuning for MySQL. Sets quite
# a number of standard options (set to defaults initially), others
# may be added to the other_options array if required. 
#
# === Parameters
#
# === Examples
#
#   node percona-node1 {
#     class { 'percona::node':   
#            cluster_name => 'cluster',
#     }
#     class { 'percona::tuning' 
#            innodb_buffer_pool_size = '10G', 
#     }
#   }
#
#   You can also assign the class to a node/group 
#   and set the parameters with hiera, like so:
#
#   Contents of tuned-percona-node.yaml:
#
#     ---
#     percona::tuning:innodb_buffer_pool_size: '10G'
#     percona::tuning:innodb_flush_method: 'O_DIRECT'
#
class percona::tuning (
    $innodb_buffer_pool_size = '8388608',
    $innodb_data_file_path   = 'ibdata1:10M:autoextend', 
    $innodb_flush_method     = 'async_unbuffered',
    $innodb_file_per_table   = '0',
    $table_open_cache        = '64',
    $max_connections         = '151',
    $wait_timeout            = '28800',
    $tmp_table_size          = '16777216',
    $max_heap_table_size     = '16777216',
    $thread_cache_size       = '0',
    $open_files_limit        = '0',
    $table_definition_cache  = '256',
    $other_options           = undef,
) {

  file { "/etc/mysql/conf.d/tuning.cnf":
       ensure  => present,
       content => template('percona/tuning.cnf.erb'),
  }

}

