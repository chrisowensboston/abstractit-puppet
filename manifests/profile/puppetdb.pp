# Class puppet::profile::puppetdb
#
# The puppet::master::puppetdb class is responsible for configuring PuppetDB
# It will only setup PuppetDB, if you want to setup PuppetDB on the node your puppet master run on
# please use the puppet::profile::master class
# This and the puppet::profile::master class are mutually exclusive and will not work on the same node.
#
# Puppetdb defaults to using a database served by a database server on the local host, but
# can be configured to use a remote database. See the database, database_host, database_port,
# database_username, database_password, database_name, and jdbc_ssl properties
#
# @puppet::profile::puppetdb when declaring the puppet::profile::puppetdb class
#   include puppet::profile::puppetdb
#
# @param puppetdb_version [String] Default: 'installed'
#   The version of puppetdb to install.
# @param puppetdb_manage_dbserver [Boolean] Default: true
#   Whether to tell PuppetDB to also manage the Postgresql server.
#   Set this to false if you are independently configuring a
#   Postgresql server, e.g., because you are using it for other
#   databases in addition to pupept.
# @param node_purge_ttl [String] Default: 0s
#   The length of time a node can be deactivated before it's deleted from the database. (a value of '0' disables purging).
# @param node_ttl [String] Default: '0s'
#   The length of time a node can go without receiving any new data before it's automatically deactivated. (defaults to '0', which disables auto-deactivation).
# @param puppetdb_listen_address [String] Default: 127.0.0.1
#   The address that the web server should bind to for HTTP requests. Set to '0.0.0.0' to listen on all addresses.
# @param puppetdb_ssl_listen_address [String] Default: 127.0.0.1
#   The address that the web server should bind to for HTTPS requests. Set to '0.0.0.0' to listen on all addresses.
# @param report_ttl [String] Default: '14d'
#   The length of time reports should be stored before being deleted. (defaults to 14 days).
# @param use_ssl [Boolean] Defaults: true
#   A toggle to enable or disable ssl on puppetdb connections.
# @param listen_port [String] Defaults: '8080'
#   Non ssl Port to use for puppetdb
# @param ssl_listen_port [String] Defaults: '8081'
#   Ssl Port to use for puppetdb
# @param database [String] Defaults: undef
#   What database to use. Default allows puppetdb module to determine
# @param database_host [String] Defaults: undef
#   The host serving the database. Default allows puppetdb module to decide
# @param database_port [Integer] Defaults: undef
#   The port serving the database. Default allows puppetdb module to decide
# @param database_username [String] Defaults: undef
#   The username to connect to the database. Default allows puppetdb module to decide
# @param database_password [String] Defaults: undef
#   The password (unencrypted) used to connect to the database. Default allows puppetdb module to decide
# @param database_name [String] Defaults: undef
#   The name of the database used by puppetdb. Default allows puppetdb module to decide
# @param jdbc_ssl_properties [String] Defaults: undef.
#   SSL properties for the database. If you want to use ssl, use "?ssl=true". Default lets puppetdb module decide

class puppet::profile::puppetdb (
  String $puppetdb_version                            = 'installed',
  String $node_purge_ttl                              = '0s',
  String $node_ttl                                    = '0s',
  IP::Address::NoSubnet $puppetdb_listen_address      = '127.0.0.1',
  Variant[String, Undef] $puppetdb_server             = undef,
  Boolean $puppetdb_manage_dbserver                   = true,
  IP::Address::NoSubnet $puppetdb_ssl_listen_address  = '0.0.0.0',
  String $report_ttl                                  = '14d',
  $reports                                            = undef,
  Boolean $use_ssl                                    = true,
  Integer $listen_port                                = 8080,
  Integer $ssl_listen_port                            = 8081,
  Variant[String, Undef] $puppet_server_type          = undef,
  Variant[String, Undef] $database                    = undef,
  Variant[String, Undef] $database_host               = undef,
  Variant[Integer,Undef] $database_port               = undef,
  Variant[String, Undef] $database_username           = undef,
  Variant[String, Undef] $database_password           = undef,
  Variant[String, Undef] $database_name               = undef,
  Variant[String, Undef] $jdbc_ssl_properties         = undef,
) {

  # manage_dbserver is inconsistent with a remote database
  if $puppetdb_manage_dbserver and (($database_host != undef) and ($database_host != 'localhost')) {
    fail ('specifying a database_host other than localhost is inconsistent with puppetdb_manage_dbserver')
  }

  # add deprecation warnings
  if $puppetdb_server != undef {
    notify { 'Deprecation notice: puppet::profile::puppetdb::puppetdb_server is deprecated, use puppet::profile::master to setup PuppetDB on your puppetmaster': }
  }
  if $reports != undef {
    notify { 'Deprecation notice: puppet::profile::puppetdb::reports is deprecated, use puppet::profile::master to setup PuppetDB on your puppetmaster': }
  }
  if $puppet_server_type != undef {
    notify { 'Deprecation notice: puppet::profile::puppetdb::puppet_server_type is deprecated, use puppet::profile::master to setup PuppetDB on your puppetmaster': }
  }

  case $use_ssl {
    default : {
      $puppetdb_port = $ssl_listen_port
      $disable_ssl = false
      $ssl_deploy_certs = true
    }
    false   : {
      $puppetdb_port = $listen_port
      $disable_ssl = true
      $ssl_deploy_certs = false
    }
  }

  # add pg_trgm to the puppetdb database
  # remove this once the puppetdb module supports it
  # need postgresql::server::contrib class to make pg_trgm work
  # class { '::postgresql::server::contrib':
  # }
  # postgresql::server::extension{ 'pg_trgm':
  #   database => 'puppetdb',
  # }

  # version is now managed with the puppetdb::globals class
  class { '::puppetdb::globals':
    version  => $puppetdb_version,
    database => $database,
  }

  # setup puppetdb
  class { '::puppetdb':
    listen_port         => $listen_port,
    ssl_listen_port     => $ssl_listen_port,
    ssl_deploy_certs    => $ssl_deploy_certs,
    disable_ssl         => $disable_ssl,
    listen_address      => $puppetdb_listen_address,
    ssl_listen_address  => $puppetdb_ssl_listen_address,
    manage_dbserver     => $puppetdb_manage_dbserver,
    node_ttl            => $node_ttl,
    node_purge_ttl      => $node_purge_ttl,
    report_ttl          => $report_ttl,
    database            => $database,
    database_host       => $database_host,
    database_port       => $database_port,
    database_username   => $database_username,
    database_password   => $database_password,
    database_name       => $database_name,
    jdbc_ssl_properties => $jdbc_ssl_properties,
  }

}
