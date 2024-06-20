Param (
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [String]
    $TracerHome
)

$ErrorActionPreference = 'Stop'

$TracerHome = Resolve-Path $TracerHome
docker build --file "$PSScriptRoot/Dockerfile" --tag "update-tracer-tar-gz" -o $TracerHome/tracer/bin/artifacts/linux-x64 $TracerHome
