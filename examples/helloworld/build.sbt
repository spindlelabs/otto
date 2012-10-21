import AssemblyKeys._

name := "helloworld"

version := "1.0"

scalaVersion := "2.9.2"

libraryDependencies += "org.slf4j" % "slf4j-api" % "1.7.2"

libraryDependencies += "ch.qos.logback" % "logback-classic" % "1.0.7"

libraryDependencies += "com.typesafe" % "config" % "1.0.0"

assemblySettings

// Since we have no Scala sources, omit the Scala library and version details

autoScalaLibrary := false

crossPaths := false