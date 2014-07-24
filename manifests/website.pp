# website definition
define website::website (
  
  $userName,
  $groupName,
  $userUid,
  $groupGid,
  $domainName,

  $userGroups = [$groupName],
  $userHomeRoot = '/opt/jail',
  $userHome = "/opt/jail/${userName}",
  $userPassword = '!',
  $userPasswordMaxAge = '99999',
  $userPasswordMinAge = '0',
  $userShell = '/bin/bash',
  $userManageHome = true,
  $userEnsure = 'present',

  $domainDirRoot = '/opt/www',
  $domainDir = "/opt/www/${domainName}",
  $domainDirMode = 2770,
  $domainDirOwner = $userName,
  $domainDirGroup = $groupName,
  $domainDirSymlink = undef,

  $gitRepoUrl = undef,
  $gitRepoEnsure = 'latest',
  $content_site = '',

) {

  # create user and group
  user { "user_${userName}" :
    ensure           => $userEnsure,
    name             => $userName,
    gid              => $groupGid,
    groups           => ["${userName}"],
    home             => $userHome,
    password         => $userPassword,
    password_max_age => $userPasswordMaxAge,
    password_min_age => $userPasswordMinAge,
    shell            => $userShell,
    uid              => $userUid,
    managehome       => $userManageHome,
    require          => [ File["jail_directory"] ],
  }
  group { "group_${groupName}" :
    ensure  => $userEnsure,
    name    => $groupName,
    gid     => $groupGid,
    before  => User["user_${userName}"],
  }

  # create directory structure
  file { "domain_dir_root_${domainName}" :
    ensure  => 'directory',
    path    => $domainDir,
    owner   => $domainDirOwner,
    group   => $domainDirGroup,
    mode    => $domainDirMode,
    require => [ User["user_${userName}"] ],
  }

  # http
  if $domainDirSymlink == undef {
    file { "domain_dir_http_${domainName}" :
      ensure  => 'directory',
      path    => "${domainDir}/http",
      owner   => $domainDirOwner,
      group   => $domainDirGroup,
      mode    => $domainDirMode,
      require => [ User["user_${userName}"], File["domain_dir_root_${domainName}"] ],
    }
    exec { "setfacl-${domainName}-http":
      command => "/usr/bin/setfacl -m d:u::rwx -m d:g::rwx -m d:o::- ${domainDir}/http",
      onlyif  => "/usr/bin/getfacl -cdp ${domainDir}/http | /bin/awk '/user::rwx/{a=1}/group::rwx/{b=1}/other::---/{c=1} END {exit (a+b+c==3) }'",
      require => [ File["domain_dir_http_${domainName}"] ],
    }
  }
  else {
    file { "domain_dir_http_${domainName}" :
      ensure  => 'link',
      path    => "${domainDir}/http",
      target  => $domainDirSymlink,
      require => [ User["user_${userName}"], File["domain_dir_root_${domainName}"] ],
    }
  }

  # logs
  file { "domain_dir_logs_${domainName}" :
    ensure  => 'directory',
    path    => "${domainDir}/logs",
    owner   => 'nginx',
    group   => $groupName,
    mode    => $domainDirMode,
    require => [ User["user_${userName}"], File["domain_dir_root_${domainName}"] ],
  }

  exec { "setfacl-${domainName}-logs":
    command => "/usr/bin/setfacl -m d:u::rw -m d:g::rw -m d:o::- ${domainDir}/logs",
    onlyif  => "/usr/bin/getfacl -cdp ${domainDir}/logs | /bin/awk '/user::rw-/{a=1}/group::rw-/{b=1}/other::---/{c=1} END {exit (a+b+c==3) }'",
    require => [ File["domain_dir_logs_${domainName}"] ],
  }

  # stats
  file { "domain_dir_stats_${domainName}" :
    ensure  => 'directory',
    path    => "${domainDir}/stats",
    owner   => $userName,
    group   => $groupName,
    mode    => $domainDirMode,
    require => [ User["user_${userName}"], File["domain_dir_root_${domainName}"] ],
  }

  exec { "setfacl-${domainName}-stats":
    command => "/usr/bin/setfacl -m d:u::rw -m d:g::rw -m d:o::- ${domainDir}/stats",
    onlyif  => "/usr/bin/getfacl -cdp ${domainDir}/stats | /bin/awk '/user::rw-/{a=1}/group::rw-/{b=1}/other::---/{c=1} END {exit (a+b+c==3) }'",
    require => [ File["domain_dir_stats_${domainName}"] ],
  }

  # create nginx config file
  #file { "/etc/nginx/conf.d/${userName}.conf":
  #  ensure  => present,
  #  owner   => 'root',
  #  group   => 'root',
  #  mode    => 0644,
  #  content => template('website/nginx.erb'),
  #}

  # create php-fpm config file
  file { "/etc/php-fpm.d/${userName}.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => 0644,
    content => template('website/fpm.erb'),
  }

  # ensure fpm.sock is correct user/group of nginx
  file { "fpm.sock_${domainName}" :
    path    => "${domainDir}/fpm.sock",
    ensure  => present,
    owner   => 'nginx',
    group   => 'nginx',
    mode    => 0600,
    require => [ File["domain_dir_root_${domainName}"] ],
  }

  #if $gitRepoUrl != undef {
  #  vcsrepo { "${domainDir}/http":
  #    ensure   => $gitRepoEnsure,
  #    provider => 'git',
  #    source   => $gitRepoUrl,
  #    owner    => $userName,
  #    group    => $groupName,
  #    require  => Exec["setfacl-${domainName}-http"],
  #  }
  #}
}
