require 'spec_helper'
require 'shared_contexts'

describe 'percona::health_check' do
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
      #:mysql_host => "127.0.0.1",
      #:mysql_port => "3306",
      #:mysql_bin_dir => "/usr/bin/mysql",
      #:mysqlchk_script_dir => "/usr/local/bin",
      #:xinetd_dir => "/etc/xinetd.d",
      #:mysqlchk_user => "mysqlchk_user",
      #:mysqlchk_password => "mysqlchk_password",
      #:enabled => true,
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    is_expected.to contain_service('xinetd').
             with({"ensure"=>"$service_ensure",
                   "enable"=>"true",
                   "require"=>"[Package[xinetd], File[$xinetd_dir/mysqlchk]]",
                   "subscribe"=>"File[$xinetd_dir/mysqlchk]"})
  end
  it do
    is_expected.to contain_package('xinetd').
             with({"ensure"=>"present"})
  end
  it do
    is_expected.to contain_file('/usr/local/bin').
             with({"ensure"=>"directory",
                   "mode"=>"0755",
                   "require"=>"Package[xinetd]",
                   "owner"=>"root",
                   "group"=>"root"})
  end
  it do
    is_expected.to contain_file('/etc/xinetd.d').
             with({"ensure"=>"directory",
                   "mode"=>"0755",
                   "require"=>"Package[xinetd]",
                   "owner"=>"root",
                   "group"=>"root"})
  end
  it do
    is_expected.to contain_file('/usr/local/bin/percona_chk').
             with({"mode"=>"0755",
                   "require"=>"File[$mysqlchk_script_dir]",
                   "content"=>"template(percona/percona_chk)",
                   "owner"=>"root",
                   "group"=>"root"})
  end
  it do
    is_expected.to contain_file('/etc/xinetd.d/mysqlchk').
             with({"mode"=>"0644",
                   "require"=>"File[$xinetd_dir]",
                   "content"=>"template(percona/mysqlchk)",
                   "owner"=>"root",
                   "group"=>"root"})
  end
  it do
    is_expected.to contain_augeas('mysqlchk').
             with({"require"=>"File[$xinetd_dir/mysqlchk]",
                   "context"=>"/files/etc/services",
                   "changes"=>"[ins service-name after service-name[last()], set service-name[last()] mysqlchk, set service-name[. = 'mysqlchk']/port 9200, set service-name[. = 'mysqlchk']/protocol tcp]",
                   "onlyif"=>"match service-name[port = '9200'] size == 0"})
  end
  it do
    is_expected.to contain_percona__db('mysql').
             with({"user"=>"mysqlchk_user",
                   "password"=>"mysqlchk_password",
                   "host"=>"127.0.0.1",
                   "grant"=>"[all]"})
  end
end
