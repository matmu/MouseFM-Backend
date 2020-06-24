name := """MouseFMServ"""
organization := "com.mousefmserv"

version := "1.0-SNAPSHOT"

lazy val root = (project in file(".")).enablePlugins(PlayJava, PlayEbean)

scalaVersion := "2.12.8"


libraryDependencies += guice
libraryDependencies += ehcache
libraryDependencies += "mysql" % "mysql-connector-java" % "5.1.36"
libraryDependencies += jdbc
libraryDependencies += "org.apache.commons" % "commons-lang3" % "3.8.1"

// Default Port
PlayKeys.playDefaultPort := 9005


javacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-parameters",
  "-Xlint:unchecked",
  "-Xlint:deprecation",
  "-Werror"
)

