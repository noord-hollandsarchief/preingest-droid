# Temporary (cached) build image with Maven support. We could also rely on the project's mvnw
# wrapper, but that may need dos2unix when building on Windows if cloned with DOS line endings.
FROM        maven:3.6-openjdk-11 as build
WORKDIR     /workspace

# Optimize build image: download dependencies and cache results until pom.xml is changed
COPY        pom.xml .
RUN         mvn dependency:go-offline

COPY        src src
RUN         mvn package -DskipTests

# Final target image
FROM        openjdk:11
WORKDIR     /

# Boldly copy ALL the original DROID application contents, including its GUI
RUN         apt update
RUN         apt install unzip
RUN         apt install curl
RUN         curl -L --silent -o droid-binary-6.5.1-bin.zip https://cdn.nationalarchives.gov.uk/documents/droid-binary-6.5.1-bin.zip && \
            unzip -q droid-binary-6.5.1-bin.zip -d droid

COPY src/main/resources/template-linux.droid droid

# The build should have created a single JAR file, like droid-0.0.1-SNAPSHOT.jar
COPY --from=build /workspace/target/droid*.jar app.jar

ENTRYPOINT ["java","-jar","/app.jar"]

EXPOSE 8080
