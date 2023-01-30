from ubuntu:22.04
MAINTAINER cb-developer-network@vmware.com

COPY . /app
WORKDIR /app

RUN apt-get update
RUN apt-get install -y powershell
RUN powershell -noexit "& ""./Build-PSCarbonBlackCloud.ps1"""
