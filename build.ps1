Param (
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [String]
    $TracerHome,

    [String]
    $TracerVersion,

    [String]
    $OutputPath = "$TracerHome/tracer/bin/artifacts/linux-x64"
)

$ErrorActionPreference = 'Stop'

$TracerHome = Resolve-Path $TracerHome
$OutputPath = Resolve-Path $OutputPath

if ($TracerVersion -eq "") {
    # Get the latest release tag from the github releases list
    Write-Output "Getting latest .NET SDK release version..."
    $TracerVersion = (Invoke-WebRequest https://api.github.com/repos/datadog/dd-trace-dotnet/releases/latest | ConvertFrom-Json).tag_name.SubString(1)
    Write-Output "Using .NET SDK v${TracerVersion}."
}

docker build --rm `
  --file "$PSScriptRoot/Dockerfile" `
  --output "$OutputPath" `
  --tag "update-tracer-tar-gz" `
  --build-arg TRACER_VERSION="$TracerVersion" `
  "$TracerHome"

  Write-Output "Artifact created in $OutputPath."