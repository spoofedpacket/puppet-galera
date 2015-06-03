class percona::repo {
    apt::source { 'percona':
        location   => 'http://repo.percona.com/apt',
        release    => $::lsbdistcodename,
        repos      => 'main',
        key        => 'CD2EFD2A',
    }
}
