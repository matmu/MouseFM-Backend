// The Play plugin
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.7.2")

// Defines scaffolding (found under .g8 folder)
// http://www.foundweekends.org/giter8/scaffolding.html
// sbt "g8Scaffold form"
addSbtPlugin("org.foundweekends.giter8" % "sbt-giter8-scaffold" % "0.11.0")

// Eclipse
addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "5.2.2")

// Ebean
addSbtPlugin("com.typesafe.sbt" % "sbt-play-ebean" % "5.0.1")
//addSbtPlugin("com.typesafe.sbt" % "sbt-play-ebean" % "4.1.0")

// Assembly
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.15.0")
