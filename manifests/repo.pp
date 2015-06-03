class percona::repo {

    include apt

    apt::source { 'percona':
        location   => 'http://repo.percona.com/apt',
        release    => $::lsbdistcodename,
        repos      => 'main',
        id         => '1C4CBDCDCD2EFD2A',
    }
}
