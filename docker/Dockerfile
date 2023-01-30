FROM mcr.microsoft.com/powershell:latest
MAINTAINER cb-developer-network@vmware.com

COPY . /app
WORKDIR /app

RUN powershell -Command ./Build-PSCarbonBlackCloud.ps1
RUN powershell -Command Import-Module ./src/PSCarbonBlackCloud.psd1
