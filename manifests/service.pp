class percona::service (
  $service_ensure,
  $service_enable,
) {

  service { 'mysql':
        name        => "mysql",
        ensure      => $service_ensure,
        enable      => $service_enable,
        hasrestart  => true,
	      hasstatus   => true,
  }

}
