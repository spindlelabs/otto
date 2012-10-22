class helloworld($jenkinsProjectName, $jenkinsBuildID, $value2) {
  user { "helloworld":
    ensure => "present",
    uid => "4000",
    shell => "/bin/bash",
    password => "!*",
    comment => "helloworld",
    managehome => true
  }

  otto_java_app_from_jenkins { "helloworld":
    jenkinsProjectName => $jenkinsProjectName,
    jenkinsBuildID => $jenkinsBuildID,
    appUserGroupName => "helloworld",
    appRunContent => template("helloworld/run.erb"),
    appConfSource => "puppet:///modules/helloworld/conf",
    require => User["helloworld"]
  }
}