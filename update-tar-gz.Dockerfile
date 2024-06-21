# syntax=docker/dockerfile:1.7-labs

############################################################
# Build Datadog.Trace.dll (one for each target .NET runtime)

FROM mcr.microsoft.com/dotnet/sdk:8.0 as builder

# Restore projects
COPY --exclude=**/*.cs . /project/
RUN dotnet restore /project/tracer/src/Datadog.Trace/Datadog.Trace.csproj

# Build Datdog.Trace, copy output, and build new tarball
COPY . /project/
RUN dotnet build -c release --no-restore /project/tracer/src/Datadog.Trace/Datadog.Trace.csproj && \
    mkdir -p /package && \
    mv /project/tracer/src/Datadog.Trace/bin/release/* /package/

##################################################
# Download tarball, update files, and repackage

FROM debian:bookworm-slim as packager
ARG TRACER_VERSION=2.53.2

# download
ADD https://github.com/DataDog/dd-trace-dotnet/releases/download/v$TRACER_VERSION/datadog-dotnet-apm-$TRACER_VERSION.tar.gz /package/

# extract
RUN tar -xzf /package/datadog-dotnet-apm-$TRACER_VERSION.tar.gz -C /package/ && \
    rm /package/datadog-dotnet-apm-$TRACER_VERSION.tar.gz

# replace files
COPY --from=builder /package/ /package/

# create new tarball
RUN mkdir -p /out && \
    tar -czf /out/datadog-dotnet-apm.tar.gz -C /package/ . && \
    rm -rf /package/

##################################################
# Export new tarball

FROM scratch as local-exporter
COPY --from=packager /out/* /
