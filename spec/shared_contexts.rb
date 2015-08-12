# optional, this should be the path to where the hiera data config file is in this repo
# You must update this if your actual hiera data lives inside your module.
# I only assume you have a separate repository for hieradata and its include in your .fixtures
hiera_config_file = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures','modules','hieradata', 'hiera.yaml'))

# hiera_config and hiera_data are mutually exclusive contexts.

shared_content :global_hiera_data do
  let(:hiera_data) do
     {
       #"percona::garbd::cluster_name" => '',
       #"percona::garbd::package_name" => '',
       #"percona::garbd::peer_ip" => '',
       #"percona::haproxy::haproxy_failover" => '',
       #"percona::haproxy::haproxy_listener" => '',
       #"percona::haproxy::haproxy_primary" => '',
       #"percona::health_check::enabled" => '',
       #"percona::health_check::mysql_bin_dir" => '',
       #"percona::health_check::mysql_host" => '',
       #"percona::health_check::mysql_port" => '',
       #"percona::health_check::mysqlchk_password" => '',
       #"percona::health_check::mysqlchk_script_dir" => '',
       #"percona::health_check::mysqlchk_user" => '',
       #"percona::health_check::xinetd_dir" => '',
       #"percona::node::cluster_name" => '',
       #"percona::node::donor_ip" => '',
       #"percona::node::enabled" => '',
       #"percona::node::joiner" => '',
       #"percona::node::maint_password" => '',
       #"percona::node::old_root_password" => '',
       #"percona::node::package_name" => '',
       #"percona::node::percona_notify_from" => '',
       #"percona::node::percona_notify_to" => '',
       #"percona::node::repo_location" => '',
       #"percona::node::root_password" => '',
       #"percona::node::ssl_replication" => '',
       #"percona::node::ssl_replication_cert" => '',
       #"percona::node::ssl_replication_key" => '',
       #"percona::node::sst_method" => '',
       #"percona::node::sst_password" => '',
       #"percona::node::sst_user" => '',
       #"percona::node::tune_innodb_buffer_pool_size" => '',
       #"percona::node::tune_innodb_data_file_path" => '',
       #"percona::node::tune_innodb_file_per_table" => '',
       #"percona::node::tune_innodb_flush_method" => '',
       #"percona::node::tune_max_connections" => '',
       #"percona::node::tune_max_heap_table_size" => '',
       #"percona::node::tune_open_files_limit" => '',
       #"percona::node::tune_other_options" => '',
       #"percona::node::tune_query_cache_size" => '',
       #"percona::node::tune_query_cache_type" => '',
       #"percona::node::tune_table_definition_cache" => '',
       #"percona::node::tune_table_open_cache" => '',
       #"percona::node::tune_thread_cache_size" => '',
       #"percona::node::tune_tmp_table_size" => '',
       #"percona::node::tune_wait_timeout" => '',
       #"percona::node::wsrep_node_address" => '',
     
     }
  end
end

shared_context :hiera do
    # example only,
    let(:hiera_data) do
        {:some_key => "some_value" }
    end
end

shared_context :linux_hiera do
    # example only,
    let(:hiera_data) do
        {:some_key => "some_value" }
    end
end

# In case you want a more specific set of mocked hiera data for windows
shared_context :windows_hiera do
    # example only,
    let(:hiera_data) do
        {:some_key => "some_value" }
    end
end

# you cannot use this in addition to any of the hiera_data contexts above
shared_context :real_hiera_data do
    let(:hiera_config) do
       hiera_config_file
    end
end
