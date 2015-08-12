require 'spec_helper'
require 'shared_contexts'

describe 'percona::garbd' do
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
      #:peer_ip => "0.0.0.0",
      #:package_name => "percona-xtradb-cluster-galera-2.x",
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    is_expected.to contain_file('/etc/garbd').
             with({"ensure"=>"directory",
                   "mode"=>"0755"})
  end
  it do
    is_expected.to contain_file('/var/log/garbd').
             with({"ensure"=>"directory",
                   "mode"=>"0755"})
  end
  it do
    is_expected.to contain_file('/etc/logrotate.d/garbd').
             with({"ensure"=>"present",
                   "source"=>"puppet:///modules/percona/garbd-logrotate"})
  end
  it do
    is_expected.to contain_file('/etc/garbd/replication-key.pem').
             with({"ensure"=>"present",
                   "owner"=>"root",
                   "group"=>"root",
                   "mode"=>"0600",
                   "source"=>"puppet:///modules/percona/replication-key.pem",
                   "require"=>"File[/etc/garbd]"})
  end
  it do
    is_expected.to contain_file('/etc/garbd/replication-cert.pem').
             with({"ensure"=>"present",
                   "owner"=>"root",
                   "group"=>"root",
                   "mode"=>"0600",
                   "source"=>"puppet:///modules/percona/replication-cert.pem",
                   "require"=>"File[/etc/garbd/replication-key.pem]"})
  end
  it do
    is_expected.to contain_file('/etc/init.d/garbd').
             with({"ensure"=>"present",
                   "mode"=>"0755",
                   "source"=>"puppet:///modules/percona/garbd-init"})
  end
  it do
    is_expected.to contain_file('/etc/garbd/garbd.cfg').
             with({"ensure"=>"present",
                   "content"=>"template(percona/garbd.cfg.erb)",
                   "require"=>"File[/etc/garbd]"})
  end
  it do
    is_expected.to contain_service('garbd').
             with({"ensure"=>"running",
                   "enable"=>"true",
                   "require"=>"[Package[galera], File[/etc/garbd/garbd.cfg, /etc/init.d/garbd, /etc/garbd/replication-cert.pem]]",
                   "subscribe"=>"File[/etc/garbd/garbd.cfg]"})
  end
end
