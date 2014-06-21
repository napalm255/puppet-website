class website (

  $wwwEnabled = true,
  $wwwDirectory = '/opt/www',
  $wwwOwner = 'nginx',
  $wwwGroup = 'nginx',
  $wwwMode = 755,

  $jailEnabled = true,
  $jailDirectory = '/opt/jail',
  $jailOwner = 'root',
  $jailGroup = 'root',
  $jailMode = 754,

  $ebsMountEnabled = false,
  $ebsMountDirectory = '/data',
  $ebsMountOwner = 'root',
  $ebsMountGroup = 'root',
  $ebsMountDevice = '/dev/xvdf1',
  $ebsMountFstype = 'ext4',
  $ebsMountOptions = 'defaults',
  $ebsMountAtboot = true,

) {

  # www directory for websites
  if $wwwEnabled == true {
    file { "www_directory" :
      name   => "www_directory",
      ensure => "directory",
      path   => $wwwDirectory,
      owner  => $wwwOwner,
      group  => $wwwGroup,
      mode   => $wwwMode,
    }
  }

  # jail directory for user home directories
  if $jailEnabled == true {
    file { "jail_directory" :
      name   => "jail_directory",
      ensure => "directory",
      path   => $jailDirectory,
      owner  => $jailOwner,
      group  => $jailGroup,
      mode   => $jailMode,
    }
  } 

  # ebs mount volume for aws ec2
  if $ebsMountEnabled == true {
    file { $ebsMountDirectory :
      ensure => "directory",
      owner  => $ebsMountOwner,
      group  => $ebsMountGroup,
    }

    mount { $ebsMountDirectory :
      ensure  => "mounted",
      device  => $ebsMountDevice,
      fstype  => $ebsMountFstype,
      options => $ebsMountOptions,
      atboot  => $ebsMountAtboot,
      require => File[$ebsMountDirectory],
    }
  }

}
