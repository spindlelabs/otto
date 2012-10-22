Otto
====

Text goes here. It's easiest to understand Otto by trying it out...

Otto is tested with Ubuntu 12.04 LTS with Puppet 2.7.19.

Hello world
-----------

Otto includes an example application, `helloworld`. `helloworld` is a Java application that reads configuration, logs several messages, and then exits after 30 seconds (simulating an application crash.)

To deploy the application, Otto will:

1. Create an unprivileged user, `helloworld` (`examples/helloworld/modules/helloworld/manifests/init.pp`)
2. Install the Java 7 runtime, `openjdk-7-jre` (`examples/helloworld/modules/java/manifests/init.pp`)
2. Create the `/opt/otto` hierarchy (`modules/otto/manifests/init.pp`)
3. Install [daemontools](http://cr.yp.to/daemontools.html), a collection of tools for managing services
4. Ensure that the daemontools [service scanner](http://cr.yp.to/daemontools/svscan.html) is running
5. Download the `helloworld` build artifact from the (simulated, Jenkins-like) build server (`examples/helloworld/modules/otto_java_app_from_jenkins/manifests/init.pp`)
6. Deploy the `helloworld` configuration files (`examples/helloworld/files/conf`)
7. Run the application (`examples/helloworld/templates/run.erb`)
8. Ensure that the service is [started at boot and automatically restarted if it fails](http://cr.yp.to/daemontools/faq/create.html#why)

Running the example will make (reversible) changes to your system state, so you may wish to use a virtual machine. To run the example:

    sudo puppet apply --modulepath modules:examples/helloworld/modules --debug examples/helloworld/manifests/site.pp

`helloworld` will be installed into `/opt/otto` and started automatically. Run `svstat /etc/service/helloworld` to show the application's PID. Run `svc -t /etc/service/helloworld` to send SIGTERM to the application; it will automatically restart. `helloworld` stores logs in `/opt/otto/data/helloworld/log`.

TODO: try changing the build #, try changing run.erb, try adding more swap (dd if=/dev/zero of=/swapfile bs=1024 count=65536; mkswap /swapfile; swapon /swapfile)

Known issues
------------

Otto does not provide a mechanism for removing deployed applications, but it's [easy to do manually](http://cr.yp.to/daemontools/faq/create.html#remove).