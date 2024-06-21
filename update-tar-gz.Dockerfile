############################################################
# Build Datadog.Trace.dll (one for each target .NET runtime)

FROM mcr.microsoft.com/dotnet/sdk:8.0 as builder

# Restore projects
COPY global.json /project/

COPY tracer/Directory.Build.* /project/tracer/
COPY tracer/src/Directory.Build.* /project/tracer/src/
COPY tracer/src/Datadog.Trace/Directory.Build.* /project/tracer/src/Datadog.Trace/
COPY tracer/src/Datadog.Trace.SourceGenerators/Directory.Build.* /project/tracer/src/Datadog.Trace.SourceGenerators/
COPY tracer/src/Datadog.Trace.Tools.Analyzers/Directory.Build.* /project/tracer/src/Datadog.Trace.Tools.Analyzers/

COPY tracer/src/Datadog.Trace/*.csproj /project/tracer/src/Datadog.Trace/
COPY tracer/src/Datadog.Trace.SourceGenerators/*.csproj /project/tracer/src/Datadog.Trace.SourceGenerators/
COPY tracer/src/Datadog.Trace.Tools.Analyzers/*.csproj /project/tracer/src/Datadog.Trace.Tools.Analyzers/

RUN dotnet restore /project/tracer/src/Datadog.Trace/Datadog.Trace.csproj

# Copy source code
COPY Datadog.Trace.snk /project/
COPY tracer/stylecop.json /project/tracer/
COPY tracer/GlobalSuppressions.cs /project/tracer/
COPY tracer/src/GlobalSuppressions.cs /project/tracer/src/
COPY tracer/src/Datadog.Trace.SourceGenerators/ /project/tracer/src/Datadog.Trace.SourceGenerators/
COPY tracer/src/Datadog.Trace.Tools.Analyzers/ /project/tracer/src/Datadog.Trace.Tools.Analyzers/
COPY tracer/src/Datadog.Trace/ /project/tracer/src/Datadog.Trace/

# Build Datdog.Trace and copy output
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
