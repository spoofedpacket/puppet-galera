require 'spec_helper'
require 'shared_contexts'

describe 'percona::node' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera


  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end
  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #:cluster_name => "my_cluster",
      #:joiner => false,
      #:donor_ip => "0.0.0.0",
      #:sst_method => "xtrabackup-v2",
      #:sst_user => "wsrep_sst",
      #:sst_password => "password",
      #:root_password => "password",
      #:maint_password => "maint",
      #:old_root_password => "",
      #:enabled => true,
      #:package_name => "percona-xtradb-cluster-server-5.6",
      #:repo_location => "http://repo.percona.com/apt",
      #:percona_notify_from => "percona-noreply@example.com",
      #:percona_notify_to => "root@localhost",
      #:wsrep_node_address => undef,
      #:ssl_replication => false,
      #:ssl_replication_cert => undef,
      #:ssl_replication_key => undef,
      #:tune_innodb_buffer_pool_size => "134217728",
      #:tune_innodb_data_file_path => "ibdata1:12M:autoextend",
      #:tune_innodb_flush_method => "fsync",
      #:tune_innodb_file_per_table => "1",
      #:tune_table_open_cache => "2000",
      #:tune_max_connections => "151",
      #:tune_wait_timeout => "28800",
      #:tune_tmp_table_size => "16777216",
      #:tune_max_heap_table_size => "16777216",
      #:tune_thread_cache_size => "8",
      #:tune_open_files_limit => "5000",
      #:tune_table_definition_cache => "1400",
      #:tune_query_cache_size => "0",
      #:tune_query_cache_type => "0",
      #:tune_other_options => undef,
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    is_expected.to contain_user('mysql').
             with({"ensure"=>"present"})
  end
  it do
    is_expected.to contain_file('/etc/mysql').
             with({"ensure"=>"directory",
                   "mode"=>"0755"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/conf.d').
             with({"ensure"=>"directory",
                   "mode"=>"0755"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/my.cnf').
             with({"ensure"=>"present",
                   "source"=>"puppet:///modules/percona/my.cnf",
                   "require"=>"File[/etc/mysql]"})
  end
  it do
    is_expected.to contain_file('/usr/local/bin/perconanotify.py').
             with({"ensure"=>"present",
                   "content"=>"template(percona/perconanotify.py.erb)",
                   "mode"=>"0755"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/conf.d/wsrep.cnf').
             with({"ensure"=>"present",
                   "owner"=>"mysql",
                   "group"=>"mysql",
                   "mode"=>"0600",
                   "content"=>"template(percona/wsrep.cnf.erb)",
                   "require"=>"[File[/etc/mysql, /etc/mysql/conf.d, /usr/local/bin/perconanotify.py], User[mysql]]"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/conf.d/utf8.cnf').
             with({"ensure"=>"present",
                   "source"=>"puppet:///modules/percona/utf8.cnf",
                   "require"=>"File[/etc/mysql, /etc/mysql/conf.d]"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/conf.d/tuning.cnf').
             with({"ensure"=>"present",
                   "content"=>"template(percona/tuning.cnf.erb)",
                   "require"=>"File[/etc/mysql, /etc/mysql/conf.d]"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/debian.cnf').
             with({"ensure"=>"present",
                   "owner"=>"mysql",
                   "group"=>"mysql",
                   "mode"=>"0600",
                   "content"=>"template(percona/debian.cnf.erb)",
                   "require"=>"[Service[mysql], File[/etc/mysql, /etc/mysql/conf.d], User[mysql]]"})
  end
  it do
    is_expected.to contain_file('/etc/logrotate.d/percona').
             with({"ensure"=>"present",
                   "source"=>"puppet:///modules/percona/percona-logrotate"})
  end
  it do
    is_expected.to contain_file('/root/.my.cnf').
             with({"content"=>"template(percona/my.cnf.pass.erb)",
                   "mode"=>"0600",
                   "require"=>"Exec[set_mysql_rootpw]"})
  end
  it do
    is_expected.to contain_exec('mysqld-restart').
             with({"command"=>"service mysql restart",
                   "logoutput"=>"on_failure",
                   "refreshonly"=>"true",
                   "path"=>"/sbin/:/usr/sbin/:/usr/bin/:/bin/"})
  end
  it do
    is_expected.to contain_exec('set-mysql-password').
             with({"unless"=>"/usr/bin/mysql -uwsrep_sst -ppassword",
                   "command"=>"/usr/bin/mysql -uroot -ppassword -e \\set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to 'wsrep_sst'@'%' identified by 'password';flush privileges;\\",
                   "require"=>"Service[mysql]",
                   "subscribe"=>"Service[mysql]",
                   "refreshonly"=>"true"})
  end
  it do
    is_expected.to contain_percona__rights('debian-sys-maint user').
             with({"database"=>"*",
                   "user"=>"debian-sys-maint",
                   "password"=>"maint",
                   "priv"=>"SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER",
                   "grant_option"=>"true",
                   "require"=>"[Service[mysql], File[/root/.my.cnf]]"})
  end
  it do
    is_expected.to contain_service('mysql').
             with({"name"=>"mysql",
                   "ensure"=>"$service_ensure",
                   "enable"=>"true",
                   "require"=>"[Package[mysql-server], File[$mysql_config_files]]",
                   "hasrestart"=>"true",
                   "hasstatus"=>"true",
                   "subscribe"=>"File[$mysql_config_files]"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/replication-key.pem').
             with({"ensure"=>"present",
                   "owner"=>"mysql",
                   "group"=>"mysql",
                   "mode"=>"0600",
                   "content"=>"undef",
                   "require"=>"[File[/etc/mysql, /etc/mysql/conf.d], User[mysql]]"})
  end
  it do
    is_expected.to contain_file('/etc/mysql/replication-cert.pem').
             with({"ensure"=>"present",
                   "owner"=>"mysql",
                   "group"=>"mysql",
                   "mode"=>"0644",
                   "content"=>"undef",
                   "require"=>"File[/etc/mysql/replication-key.pem]"})
  end
  it do
    is_expected.to contain_exec('set_mysql_rootpw').
             with({"command"=>"mysqladmin -u root $old_pw password password",
                   "logoutput"=>"true",
                   "unless"=>"mysqladmin -u root -ppassword status > /dev/null",
                   "path"=>"/usr/local/sbin:/usr/bin:/usr/local/bin",
                   "notify"=>"Exec[mysqld-restart]",
                   "require"=>"[File[/etc/mysql/conf.d], Service[mysql]]"})
  end
  it do
    is_expected.to contain_exec('set-mysql-password-noroot').
             with({"unless"=>"/usr/bin/mysql -uwsrep_sst -ppassword",
                   "command"=>"/usr/bin/mysql -uroot -p -e \\set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to 'wsrep_sst'@'%' identified by 'password';flush privileges;\\",
                   "require"=>"Service[mysql]",
                   "subscribe"=>"Service[mysql]",
                   "refreshonly"=>"true"})
  end
end
