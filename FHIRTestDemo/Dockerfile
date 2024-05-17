#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env

WORKDIR /App
EXPOSE 5000 8080

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore

# Build and publish a release
RUN dotnet publish -c Release  -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /App
COPY --from=build-env /App/out .

# Set the ASPNETCORE_URLS environment variable
ENV ASPNETCORE_URLS=http://*:5000;http://*:8080

ENTRYPOINT ["dotnet", "FHIRTestDemo.dll"]