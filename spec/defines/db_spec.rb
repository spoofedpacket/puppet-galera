require 'spec_helper'
require 'shared_contexts'

describe 'percona::db' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  let(:title) { 'XXreplace_meXX' }

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
      :user => 'place_value_here',
      :password => 'place_value_here',
      #:charset => "utf8",
      #:host => "localhost",
      #:grant => "all",
      #:sql => "",
      #:enforce_sql => false,
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  it do
    is_expected.to contain_mysql_database('XXreplace_meXX').
             with({"ensure"=>"present",
                   "charset"=>"utf8",
                   "require"=>"Class[percona::node]"})
  end
  it do
    is_expected.to contain_mysql_user('@localhost').
             with({"ensure"=>"present",
                   "password_hash"=>"mysql_password($password)",
                   "require"=>"Mysql_database[$name]"})
  end
  it do
    is_expected.to contain_mysql_grant('@localhost/XXreplace_meXX.*').
             with({"privileges"=>"all",
                   "table"=>"XXreplace_meXX.*",
                   "user"=>"@localhost",
                   "require"=>"Mysql_user[$user@$host]"})
  end
  it do
    is_expected.to contain_exec('XXreplace_meXX-import').
             with({"command"=>"/usr/bin/mysql XXreplace_meXX < ",
                   "logoutput"=>"true",
                   "refreshonly"=>"#<Puppet::Parser::AST::Not:0x0000000202d6c0>",
                   "require"=>"Mysql_grant[$user@$host/$name.*]",
                   "subscribe"=>"Mysql_database[$name]"})
  end
end
