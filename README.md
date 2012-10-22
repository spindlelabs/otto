Otto
====

Text goes here...link to blog post with introduction. It's easiest to understand Otto by trying it out...

Otto is tested with Puppet 2.7.19 on Ubuntu 12.04 LTS.

Getting started: deploying `helloworld`
---------------------------------------

`helloworld` is a simple Java application that reads its configuration, logs several messages, and then exits after 30 seconds (simulating an application crash.) We'll demonstrate deploying `helloworld` from a build server using Otto.

To deploy `helloworld`, Otto will:

1. Create an unprivileged user, `helloworld` (`examples/helloworld/modules/helloworld/manifests/init.pp`)
2. Install the Java 7 runtime package, `openjdk-7-jre` (`examples/helloworld/modules/java/manifests/init.pp`)
2. Create the `/opt/otto` hierarchy (`modules/otto/manifests/init.pp`)
3. Install [daemontools](http://cr.yp.to/daemontools.html), a collection of tools for managing services
4. Ensure that the daemontools [service scanner](http://cr.yp.to/daemontools/svscan.html) is running
5. Download the `helloworld` build artifact from the (simulated, Jenkins-like) build server into `/opt/otto/build/helloworld/helloworld-master-checkin@1` (`examples/helloworld/modules/otto_java_app_from_jenkins/manifests/init.pp`)
6. Deploy the `helloworld` configuration files into `/opt/otto/conf/helloworld` (`examples/helloworld/files/conf`)
7. Run the application using `/opt/otto/run/helloworld` (`examples/helloworld/templates/run.erb`)
8. Ensure that the service is [started at boot and automatically restarted if it fails](http://cr.yp.to/daemontools/faq/create.html#why)

To deploy `helloworld` on Ubuntu 12.04 LTS, run:

    sudo apt-get install puppet
    git clone https://github.com/spindlelabs/otto.git
    cd otto

    # This command will make (reversible) changes to your system state; consider using a virtual machine
    sudo puppet apply --modulepath modules:examples/helloworld/modules --debug examples/helloworld/manifests/site.pp

`helloworld` will be installed into `/opt/otto` and started automatically.

Try a few experiments to understand Otto:

* Run `svstat /etc/service/helloworld` to show the application's PID and uptime
* Run `pstree -paul` to show the process hierarchy; observe that `java` is running as the unprivileged `helloworld` user
* Run `svc -t /etc/service/helloworld` to send `SIGTERM` to the application; it will automatically restart
* Restart the machine; `helloworld` will automatically start
* View the application logs in `/opt/otto/data/helloworld/log`. Observe the logged configuration values and environment variables.
* Examine `/opt/otto/service/helloworld/run` and `/opt/otto/run/helloworld` to understand how Otto invokes `helloworld`. Note that the logging configuration in `/opt/otto/conf/helloworld/logback.xml` uses an environment variable supplied by Otto to locate the application data directory without hard-coding path names.
* Note the permissions for `/opt/otto/build/helloworld/helloworld-master-checkin@1`, `/opt/otto/conf/helloworld`, and `/opt/otto/data/helloworld`: an application may modify its data directory but cannot modify its build artifact or its configuration

Next, try changing the application configuration. After making each change, rerun the `puppet apply` command above; Otto will restart the application with its new configuration.

* Deploy a different build (`1`, `2` or `3`) by changing `jenkinsBuildID` in `examples/helloworld/manifests/site.pp`. Otto will download the new build, stop the existing build, and then start the new build. Try rolling back to a previous build; Otto will avoid redownloading a build it has already retrieved.
* Change the log level in `examples/helloworld/modules/helloworld/files/conf/logback.xml` or a configuration value in `examples/helloworld/modules/files/conf/application.conf`
* Change the configuration value `value2` in `examples/helloworld/manifests/site.pp`
* Change the configuration value `value3` in `examples/helloworld/modules/templates/run.erb` by changing the amount of swap space on the machine (`dd if=/dev/zero of=/swapfile bs=1024 count=65536; mkswap /swapfile; swapon /swapfile`)
* As `root`, modify `/opt/otto/conf/helloworld/logback.xml`. Otto will revert the change to prevent configuration drift.

Next steps
----------

Now that you've seen a working example, try deploying your own application with Otto. If you're not familiar with Puppet, read the [Puppet introduction](http://docs.puppetlabs.com/guides/introduction.html). Copy `modules/otto` into your Puppet modules directory, and modify the examples to fit your environment. Be sure to follow the application notes in `modules/otto/manifests/{app,init}.pp`.

Known issues
------------

Otto does not provide a mechanism for removing deployed applications, but it's [easy to do manually](http://cr.yp.to/daemontools/faq/create.html#remove).