class percona::repo {

    include apt

    apt::source { 'percona':
        location   => 'http://repo.percona.com/apt',
        release    => $::lsbdistcodename,
        repos      => 'main',
        key        => {
          'id'     => '430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A',
          'server' => 'subkeys.pgp.net',
        },
    }
}
