FROM mcr.microsoft.com/windows/servercore:ltsc2019
MAINTAINER cb-developer-network@vmware.com

COPY . /app
WORKDIR /app

RUN ./Build-PSCarbonBlackCloud.ps1
RUN Import-Module ./src/PSCarbonBlackCloud.psd1
