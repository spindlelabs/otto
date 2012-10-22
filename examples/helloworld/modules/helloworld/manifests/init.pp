class ottoexample1::app::helloworld($jenkinsProjectName, $jenkinsBuildID, $value2) {
  $appName = "helloworld"

  ottoexample1::otto_java_app_from_jenkins { $appName:
    jenkinsProjectName => $jenkinsProjectName,
    jenkinsBuildID => $jenkinsBuildID,
    appRunContent => template("ottoexample1/app/helloworld/run.erb")
  }
}