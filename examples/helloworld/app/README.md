This example uses [sbt-assembly](https://github.com/sbt/sbt-assembly) to create an single executable artifact. To create the deployment artifact (`helloworld-assembly-1.0.jar`), [install sbt](http://www.scala-sbt.org/release/docs/Getting-Started/Setup.html) and then run `sbt assembly`.

To test the application, run `java -jar target/helloworld-assembly-1.0.jar`.