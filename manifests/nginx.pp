class website::nginx () {

  package { 'nginx':
    ensure => latest,
  }

  service { 'nginx':
    ensure => running,
    enable => true,
    require => Package['nginx'],
  }

  # create nginx config file
  file { "/etc/nginx/nginx.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    content => template('website/nginx.conf.erb'),
    notify  => [ Service['nginx'] ],
    require => Package['nginx'],
  }

}
