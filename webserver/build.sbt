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

assemblyMergeStrategy in assembly := {
  case manifest if manifest.contains("MANIFEST.MF") =>
    // We don't need manifest files since sbt-assembly will create
    // one with the given settings
    MergeStrategy.discard
  case referenceOverrides if referenceOverrides.contains("reference-overrides.conf") =>
    // Keep the content for all reference-overrides.conf files
    MergeStrategy.concat
  case x =>
    // For all the other files, use the default sbt-assembly merge strategy
    val oldStrategy = (assemblyMergeStrategy in assembly).value
    oldStrategy(x)
}
