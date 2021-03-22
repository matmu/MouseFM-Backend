FROM maven:3-openjdk-11 as build

COPY ./ /mousefm
WORKDIR /mousefm
RUN ./sbt 'set test in Test := {}' clean assembly

FROM gcr.io/distroless/java-debian10:11
COPY --from=build /mousefm/target/scala-*/MouseFMServ*.jar /app/mousefmserv.jar
CMD ["/app/mousefmserv.jar"]
