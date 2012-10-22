class otto() {
  $ottoRootPath = "/mnt/otto"

  $ottoBuildPath = "${ottoRootPath}/build"
  $ottoConfPath = "${ottoRootPath}/conf"
  $ottoRunPath = "${ottoRootPath}/run"
  $ottoDataPath = "${ottoRootPath}/data"
  $ottoServicePath = "${ottoRootPath}/service"
  $ottoLockPath = "${ottoRootPath}/lock"

  $daemontoolsServicePath = "/etc/service"

  package { "daemontools-run":
    ensure => "latest"
  }

  service { "svscan":
    ensure => "running",
    # svscan starts with upstart (/etc/init.d/svscan.conf),
    # so "provider" should be set to "upstart", but 2.6.4
    # doesn't support upstart, so we'll invoke "service"
    # see also http://projects.puppetlabs.com/issues/12773
    provider => "base",
    start => "service svscan start",
    status => "service svscan status | grep ' start/running'",
    stop => "service svscan stop",
    require => Package["daemontools-run"]
  }

  file { $ottoRootPath:
    ensure => "directory",
    owner => "root",
    group => "root",
    mode => "0644"
  }

  file { [$ottoBuildPath,
          $ottoConfPath,
          $ottoRunPath,
          $ottoDataPath,
          $ottoServicePath,
          $ottoLockPath]:
    ensure => "directory",
    owner => "root",
    group => "root",
    mode => "0644",
    require => File[$ottoRootPath]
  }
}