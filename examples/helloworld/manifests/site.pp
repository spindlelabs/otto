# Normally, the node name would be specified:
# node "host1.example.com" {
# To make it easier to run the example, we'll use the default node:
node default {
  class { "helloworld":
    jenkinsProjectName => "helloworld-master-checkin",
    jenkinsBuildID => "1",
    value2 => "from machine manifest",
    appRunService => true
  }
}

Exec {
  path => "/usr/bin:/bin:/usr/sbin:/sbin"
}
