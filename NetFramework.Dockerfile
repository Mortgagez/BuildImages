# escape=`

# Installer image
FROM microsoft/windowsservercore:1803 AS installer-env

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Retrieve node and git
ENV NODE_VERSION 6.13.0
ENV NODE_DOWNLOAD_SHA 3d3d72c5c93a50d5a19f65f0de196b5237792a99b89fac2b61e62da4f566c842

RUN Invoke-WebRequest -UseBasicParsing https://nodejs.org/dist/v${env:NODE_VERSION}/node-v${env:NODE_VERSION}-win-x64.zip -outfile node.zip; `
    if ((Get-FileHash node.zip -Algorithm sha256).Hash -ne $env:NODE_DOWNLOAD_SHA) { `
        Write-Host 'NODEJS CHECKSUM VERIFICATION FAILED!'; `
        exit 1; `
    }; `
    `
    Expand-Archive node.zip -DestinationPath nodejs-tmp; `
    Move-Item nodejs-tmp/node-v${env:NODE_VERSION}-win-x64 nodejs; `
    Remove-Item -Force node.zip; `
    Remove-Item -Force nodejs-tmp; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -UseBasicParsing https://github.com/git-for-windows/git/releases/download/v2.16.2.windows.1/MinGit-2.16.2-64-bit.zip -outfile git.zip; `
    Expand-Archive git.zip -DestinationPath git; `
    Remove-Item -Force git.zip

FROM microsoft/dotnet-framework-build as build

# Set up environment
ENV ASPNETCORE_URLS http://+:80
ENV ASPNETCORE_PKG_VERSION 2.0.9

# Install node, bower, and git
COPY --from=installer-env ["nodejs", "C:\\Program Files\\nodejs"]
RUN ""C:\Program Files\nodejs\npm"" install -g gulp bower
COPY --from=installer-env ["git", "C:\\Program Files\\git"]
RUN setx PATH "%PATH%;C:\Program Files\nodejs;C:\Program Files\git\cmd"

# Install MSBuild
ADD https://aka.ms/vs/15/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache --installPath c:\BuildTools 
RUN setx PATH "c:\BuildTools\MSBuild\15.0\Bin\;%PATH%";

# Install Nuget
RUN npm install -g --prefix c:\tools\nuget nuget && `
	setx PATH "c:\tools\nuget\node_modules\nuget\bin;%PATH%"

# Install dontet core sdk
RUN npm install -g --prefix c:\tools\dotnetcore-sdk dotnet-sdk-2.1-win-x64 && `
	setx PATH "c:\tools\dotnetcore-sdk;%PATH%"

# Add the Geeks.MS nuget source
RUN nuget sources add -Name "GeeksMS" -Source "http://nuget.geeksms.uat.co/nuge"