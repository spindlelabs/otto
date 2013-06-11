Otto: unifying deployment, application management, and platform management
===

At Spindle, our local search results are powered by a low-latency content fetching pipeline, a real-time query service, and a scalable content notification engine. We’re constantly making changes to these backend applications, so we built a system to automate the tedious deployment work for us. Today, we’re releasing that project, Otto, under the open-source Apache 2.0 license. We’ve published Otto along with a full tutorial at https://github.com/spindlelabs/otto.

Fixing deployment
---

Before we started building Otto, we thought carefully about the properties of our ideal deployment system. That ideal deployment system must offer:

* *Simplicity, transparency, and predictability.* It should be easy for an engineer to understand how the system works, what actions it will take, and how those actions will be performed.
* *Painless application version changes.* Our most common deployment operation is bumping the version of an application. Because we do this so often, it needs to be easy and fast in both development and in production environments.
* *Easy deployment to new servers.* We frequently add and replace servers. Deploying an application to a new server should be as easy and as reliable as deploying a change to an existing server.
* *Fault tolerance.* Our application runs on many servers across several datacenters. Network links and individual servers occasionally fail; the system should retry failed deployments as necessary.
* *Technology independence.* Our own applications are written in Scala, Python, or Bash, and we also need to deploy third-party applications like [elasticsearch](http://www.elasticsearch.org/) and [Jenkins](http://jenkins-ci.org/). The system should not require special application-level support.
* *Artifact repository independence.* The deployment system should be able to download artifacts from a build server such as Jenkins or from an external repository like [Amazon S3](https://wiki.jenkins-ci.org/display/JENKINS/S3+Plugin").
* *Change notification and history tracking.* Because we make changes so often, understanding the history of our environment can be critical for troubleshooting a problem or finding the cause of a performance regression.
* *Partial application deployment.* It should be possible to deploy a new version of an application to a subset of eligible servers. Consider an experimental performance hotfix: with a partial deployment, engineers can monitor metrics like request latency and error rate before deciding whether to roll out the change to all servers.
* *Rolling application deployment.* Deploying a new version of an application shouldn’t upgrade all servers simultaneously; changes should be rolled out gradually to maintain service availability.
* *Safe rollback.* If a deployment is aborted, servers that have not yet taken the change should remain unaffected, and servers that have taken the change should be restored to their previous state.
* *Scheduled deployment.* The deployment system should support scheduled deployments such as automatically deploying the latest successful daily build to the QA environment every day at 3am.

From deployment to application management
---

Traditionally, “deployment” has meant one-off, single-shot attempts to put the correct set of bits on the correct set of servers. But we’ve found that our needs are broader: we need application management, not just deployment. Our ideal application management system must offer:

* *Separation of privilege.* Our applications should run as unprivileged users to reduce the impact of a compromised application.
* *Configuration drift prevention.* An engineer may manually make a one-off change to an individual server’s configuration to address a problem; if the server is replaced, that change will be lost and the problem will reoccur. The system should prevent configuration drift by making it easy for an engineer to record these configuration changes properly and by ensuring that the effective configuration always matches the recorded configuration across all servers.
* *Application runtime management.* Startup scripts are [notoriously difficult to write](http://cr.yp.to/daemontools/faq/create.html#why), and few startup scripts restart the application after a crash. The system should make it easy to write correct, safe startup scripts, and the system should automatically restart the application if it fails.
* *Easy configuration changes.* Often, we’ll need to make a small configuration change such as changing a timeout or a resource limit; we shouldn’t have to deploy a new build of the application to make these changes.

From application management to platform management
---

As we mentioned, some of these requirements are completely out of scope for the traditional single-shot application deployment tool. But there’s another problem: deploying some of our applications requires updating the server configuration. For example, our front-end application requires the Java virtual machine, [nginx](http://nginx.org), and our SSL certificates; our search server requires software RAID. Our applications can’t run correctly without these changes.

More generally, our applications have platform dependencies: they depend on the correct configuration of software we didn’t write. We’ve shown that we care about application management, not just deployment. But these platform dependencies mean that we’ll need to manage the platform in order to deploy and manage the application. This presents a difficult question: where does the platform management end and application management begin? After all, [you don’t know what you do until you know what you don’t do](https://blogs.msdn.com/b/oldnewthing/archive/2007/03/21/1922203.aspx).

At Spindle, we found that we could solve all three problems with the same approach. We built Otto: Otto unifies deployment, application management and platform management (in 250 lines of code!)

Puppet: solid platform management
---

It turns out that many of our requirements we described above have already been addressed at the platform layer by [Puppet](https://puppetlabs.com/puppet/what-is-puppet/). Otto extends Puppet to better support the application layer.

Puppet provides solid platform management. With Puppet, administrators move from scripting sequences of imperative operations to simply declaring the desired system state and letting Puppet handle the details. Consider, for example, configuring nginx to support our front-end web application. A traditional script would copy our SSL certificates, invoke the package manager to install nginx 1.2.4, and then restart the service. With Puppet, the administrator instead models the desired state of the system by specifying resources (“the Debian package named nginx”), attributes (“version 1.2.4”, “is installed”), and dependencies (“ensure the SSL certificates are present before installing nginx”, “restart nginx if the certificates have changed”). Then Puppet brings the server into compliance with the administrator’s model. If the certificates change, Puppet will notice that the system is out of compliance, replace the files, and then restart nginx; it’s not necessary to write a one-off imperative script to log into every server, change the certificates, and then restart nginx manually.

Puppet has comprehensive support for managing platform resources such as files, mount points, packages, and cron jobs. Puppet offers a straightforward domain-specific language for crafting models, and the DSL hides OS-specific implementation details like the underlying package manager. Puppet is popular, powerful, and well-documented, and [several](https://puppetlabs.com/services/support-plans/) [companies](http://bitfieldconsulting.com/) [offer]("https://puppetlabs.com/services/partners/partner-finder/) commercial support.

Here’s an [example](http://docs.puppetlabs.com/learning/ral.html) of a simple Puppet model:

<pre>
 user { 'dave':
  ensure     =&gt; present,
  uid        =&gt; '507',
  gid        =&gt; 'admin',
  shell      =&gt; '/bin/zsh',
  home       =&gt; '/home/dave',
  managehome =&gt; true,
 }
</pre>

This model specifies, among other things, that the user “dave” should exist and his shell should be zsh. When the model is applied to a new server, Puppet will create the user:

<pre>
 # puppet apply dave.pp
 notice: /User[dave]/ensure: created
</pre>

If this model is immediately reapplied, Puppet will make no changes: it will interrogate the system and find it in compliance with the model, so no changes will be necessary. If the administrator changes dave’s shell to bash and then reapplies the model, Puppet will change dave’s shell to bring the system into compliance with the model.

Puppet for applications
---

Out of the box, Puppet offers unparalleled platform management. Otto extends Puppet with application deployment and management support. In particular, Otto adds application models; these application models include support for deployment (retrieving the application artifact), runtime management (starting, stopping, and restarting the application), and configuration. With Otto, we can model our applications the same way we modeled users:

<pre>
 class { 'spindle::frontend':
  jenkinsProjectName =&gt; 'master-checkin',
  jenkinsBuildID =&gt; '104'
 }
</pre>
  
When this model is applied to a new machine, Puppet will download build 104 of our frontend application from the master-checkin project on our Jenkins server. It will install and configure all dependencies including nginx and the Java virtual machine. If a different build of the application was already installed, it is updated to build 104 and any other configuration differences are resolved.

Within the definition of `spindle::frontend`, we define our static assets, nginx configuration, SSL certificates, and the Scala application that handles dynamic requests. (For a concrete example, see the [sample application definition](https://github.com/spindlelabs/otto/blob/master/examples/helloworld/modules/helloworld/manifests/init.pp) included with the Otto source code.) The Scala application definition includes a definition for the Java virtual machine and details of how to retrieve the artifact from our build server. We also include a script to start the frontend application; after all dependencies have been satisfied, Otto starts the application and ensures that it continues running.

To deploy the next build of the frontend, we just change `104` to `105`. The most straightforward way to make this change is to edit the model file directly, but we could also find the build number by querying a database or calling out to external code (using [extlookup()](http://docs.puppetlabs.com/references/latest/function.html#extlookup), [generate()](http://docs.puppetlabs.com/references/latest/function.html#generate), or an [external node classifier](http://docs.puppetlabs.com/guides/external_nodes.html). With these features, you could implement partial deployment (“only 1 in 4 servers should run the experimental hotfix”), continuous deployment (“always run the latest successful build”), triggered deployment (“deploy the new build when traffic is less than 10 QPS over the last 15 minutes”), and automatic rollback (“revert the latest change if the error rate increases by 50%”). These external lookup features are provided by Puppet, not Otto; by building on Puppet’s solid platform management, Otto creates a powerful application deployment and management system.

Similarly, to deploy a configuration change, we just make the change in the Puppet model. Puppet detects the change, atomically updates the configuration file, and then notifies the application of the change by restarting it. Otto takes advantage of Puppet’s existing support for file management and change notification to eliminate application configuration drift.

If Puppet notices that a server is not running the correct build of the application, it will download the new build and install it. If that download fails, it will log an error and abort the change; it will make no further modifications to the server. Therefore, the existing version of the application will continue to run. The next time Puppet runs (by default, once every 30 minutes), it will again notice the conflict and attempt to resolve it. Because Otto is built on Puppet, it can handle the failure automatically.

Puppet has a full model of the system’s desired state. Therefore, it can install a new application just as easily as it can modify an existing application. So no special support is required for Otto to deploy an application on a freshly-installed server.

Otto in practice
---

We have been using Otto in production for close to a full year. We deploy new code and configuration with Otto several times a day.

We store our Puppet configuration in git. Because Puppet is configured with flat text files, we can use the standard Git toolkit to view the history of our configuration and to send notifications whenever a developer makes a change. Git also makes it easy for us to roll back a change by reverting the appropriate commit.

We use a [masterless](http://bitfieldconsulting.com/scaling-puppet-with-distributed-version-control) Puppet configuration: each server is responsible for applying its own configuration, so we don’t have to maintain a dedicated Puppet master. We use Ubuntu [cloud-init](https://help.ubuntu.com/community/CloudInit) to bootstrap our servers with Puppet as soon as they are provisioned.

Otto has preserved our sanity in an environment with more backend applications than backend engineers. Today, we’re releasing Otto under the open-source Apache 2.0 license. We’ve published the source code at https://github.com/spindlelabs/otto. We’ve included a sample application as well as a tutorial for deploying and managing it. We hope you find Otto as useful as we have!

— [Alex Lambert](https://twitter.com/alambert)

***

[originally published 2013-05-17 on the Spindle blog](http://blog.spindle.com/post/50658200302/hello-otto)