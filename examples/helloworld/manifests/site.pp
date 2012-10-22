# Normally, the node name would be specified:
# node "host1.example.com" {
# To make it easier to run the example, we'll use the default node:
node default {
  class { "helloworld":
    jenkinsProjectName => "helloworld-master-checkin",
    # You could specify the build in the node manifest:
    jenkinsBuildID => "1",
    # Or, you could could use generate(), extlookup(), or an external node
    # classifier to determine the build to run. You can use this to
    # implement continuous deployment or automatic rollback.
    value2 => "from machine manifest"
  }
}