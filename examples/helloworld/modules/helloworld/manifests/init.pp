class helloworld($jenkinsProjectName, $jenkinsBuildID, $value2) {
  ottoexample1::otto_java_app_from_jenkins { "helloworld":
    jenkinsProjectName => $jenkinsProjectName,
    jenkinsBuildID => $jenkinsBuildID,
    appRunContent => template("helloworld/run.erb"),
    appConfSource => "puppet:///modules/helloworld/conf"
  }
}