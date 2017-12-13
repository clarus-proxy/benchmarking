FROM ubuntu:latest

RUN apt update && apt install --assume-yes g++ openjdk-8-jdk maven  postgresql-common postgresql  postgresql-server-dev-9.5 libecpg-dev libkrb5-dev
RUN apt install --assume-yes curl
RUN curl -L -q -O https://github.com/tada/pljava/archive/V1_5_0.tar.gz && tar -xf V1_5_0.tar.gz && cd pljava-1_5_0 
RUN mvn clean install && java -jar pljava-packaging/target/pljva-pg9.5-amd64-Linux-gpp.jar 
