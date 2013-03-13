define otto::app($appName = $title, $appBuildID, $appUserName, $appBuildArtifactFetchCommand, $appBuildArtifactName, $appConfSource, $appRunContent, $appPrerunContent = "", $appRunService = true) {
  include otto

  $appBuildPath = "${otto::ottoBuildPath}/${appName}"
  $appConfPath = "${otto::ottoConfPath}/${appName}"
  $appRunPath = "${otto::ottoRunPath}/${appName}"
  $appDataPath = "${otto::ottoDataPath}/${appName}"
  $appServicePath = "${otto::ottoServicePath}/${appName}"

  $appCurrentBuildPath = "${appBuildPath}/${appBuildID}"
  $appCurrentBuildArtifactPath = "${appCurrentBuildPath}/${appBuildArtifactName}"

  $appServiceRunPath = "${appServicePath}/run"
  $appServiceDownPath = "${appServicePath}/down"

  $appInstalledServicePath = "${otto::daemontoolsServicePath}/${appName}"
  $appInstalledServiceTempPath = "${otto::daemontoolsServicePath}-temp-${appName}"

  file { $appBuildPath:
    ensure => "directory",
    owner => "root",
    group => $appUserName,
    mode => "0640",
    require => File[$otto::ottoBuildPath],
    notify => Service[$appName]
  }

  file { $appCurrentBuildPath:
    ensure => "directory",
    owner => "root",
    group => $appUserName,
    mode => "0640",
    require => File[$appBuildPath],
    notify => Service[$appName]
  }

  # Multiple applications could have the same appBuildArtifactFetchCommand
  $appBuildArtifactFetchCommandResource = "${appName} ${appBuildArtifactFetchCommand}"

  # Application note: $appBuildArtifactFetchCommand must atomically create $appCurrentBuildArtifactPath with
  # correct permissions, and $appCurrentBuildArtifactPath must never be modified. To change the build artifact,
  # deploy a new build.
  exec { $appBuildArtifactFetchCommandResource:
    command => $appBuildArtifactFetchCommand,
    cwd => $appCurrentBuildPath,
    creates => $appCurrentBuildArtifactPath,
    require => File[$appCurrentBuildPath],
    notify => Service[$appName]
  }

  file { $appDataPath:
    ensure => "directory",
    owner => "root",
    group => $appUserName,
    mode => "0660",
    require => File[$otto::ottoDataPath],
    notify => Service[$appName]
  }

  # Application note: Puppet 2.6.4 deploys individual files by writing to a temporary file and then using rename(2)
  # to atomically move them into place. The service will not be enabled until all initial configuration has been
  # deployed, but after that the service may restart at any time -- even while configuration files are being
  # (atomically) replaced. Therefore, it is possible that an application may start with a mix of old and new versions
  # of configuration files. If this presents a problem, one possible mitigation approach is to treat all configuration
  # files as immutable and then pick the latest complete set from within your application.
  file { $appConfPath:
    ensure => "directory",
    owner => "root",
    group => $appUserName,
    links => "follow",
    recurse => "true",
    purge => true,
    force => true,
    source => $appConfSource,
    # make everything executable in case the app has other scripts to run
    mode => "0750",
    # make sure all of the other app dependencies are in place before modifying configuration
    require => [File[$otto::ottoConfPath, $appDataPath], Exec[$appBuildArtifactFetchCommandResource]],
    notify => Service[$appName]
  }

  # Application note: the "run" script is deployed last since it may have dependencies in $appConfPath and
  # other directories. Puppet 2.6.4 deploys the new script by rename(2)ing it into place, which complies with
  # the guidance for upgrading a run script at http://cr.yp.to/daemontools/faq/create.html#upgrade
  file { $appRunPath:
    ensure => "present",
    owner => "root",
    group => $appUserName,
    content => $appRunContent,
    links => "follow",
    mode => "0750",
    # make sure the configuration (and, transitively, all other dependencies) are in place before modifying the "run" script
    require => File[$appConfPath],
    notify => Service[$appName]
  }

  # We keep this directory readable by the group because it's the current working directory for the application
  file { $appServicePath:
    ensure => "directory",
    owner => "root",
    group => $appUserName,
    mode => "0640",
    require => File[$otto::ottoServicePath],
    notify => Service[$appName]
  }

  file { $appServiceRunPath:
    ensure => "file",
    content => sprintf("#!/bin/sh\nexec 2>&1\n%s\nOTTO_APP_NAME=%s OTTO_APP_BUILD_ID=%s OTTO_APP_CURRENT_BUILD_ARTIFACT_PATH=%s OTTO_APP_CONF_PATH=%s OTTO_APP_DATA_PATH=%s exec setuidgid %s %s\n",
                       $appPrerunContent,
                       shellquote($appName),
                       shellquote($appBuildID),
                       shellquote($appCurrentBuildArtifactPath),
                       shellquote($appConfPath),
                       shellquote($appDataPath),
                       shellquote($appUserName),
                       shellquote($appRunPath)),
    owner => "root",
    group => "root",
    mode => "0700",
    require => File[$appRunPath, $appServicePath],
    notify => Service[$appName]
  }

  # svscan automatically supervises new services shortly after they're added to the service directory. We might want
  # to install a service but not bring it up immediately, though. supervise will not run the service if ./down exists
  # in the service directory, so we'll create ./down before adding the service and then let the service handler bring
  # the service up later if needed. Also, if we are bringing the service down, we will create ./down so that supervise
  # does not restart it if the machine is rebooted.
  #
  # References:
  #  http://cr.yp.to/daemontools/svscan.html
  #  http://cr.yp.to/daemontools/supervise.html

  # Changing the target of a symlink is not an atomic operation; see
  # http://blog.moertel.com/articles/2005/08/22/how-to-change-symlinks-atomically
  $installServiceCommand = sprintf("touch %s && ln -sTf %s %s && mv -Tf %s %s",
                                   shellquote($appServiceDownPath),
                                   shellquote($appServicePath),
                                   shellquote($appInstalledServiceTempPath),
                                   shellquote($appInstalledServiceTempPath),
                                   shellquote($appInstalledServicePath))
  $serviceNotInstalledCommand = sprintf("test ! \\( -h %s -a \"`readlink -n %s`\" = %s \\)",
                                        shellquote($appInstalledServicePath),
                                        shellquote($appInstalledServicePath),
                                        shellquote($appServicePath))

  exec { $installServiceCommand:
    require => File[$appServiceRunPath],
    onlyif => $serviceNotInstalledCommand,
    notify => Service[$appName]
  }

  # We can't use the daemontools provider in 2.6.4 because we need to control the daemon path
  service { $appName:
    ensure => $appRunService,
    provider => "base",
    hasrestart => true,
    # Since we want the service to come up, it's appropriate to remove the ./down file. ("rm -f s" succeeds even
    # if s does not exist.)
    start => sprintf("rm -f %s && svc -u %s",
                     shellquote($appServiceDownPath),
                     shellquote($appInstalledServicePath)),
    restart => sprintf("svc -t %s",
                       shellquote($appInstalledServicePath)),
    status => sprintf("svstat %s | grep ': up '",
                      shellquote($appInstalledServicePath)),
    stop => sprintf("touch %s && svc -d %s",
                    shellquote($appServiceDownPath),
                    shellquote($appInstalledServicePath)),
    require => Exec[$installServiceCommand]
  }
}