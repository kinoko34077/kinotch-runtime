[CmdletBinding()]
param()

function Test-McpToolName {
    param([Parameter(Mandatory=$true)][string]$Name)
    return $Name -match '^[a-z][a-z0-9_.-]*$'
}

function Invoke-McpInputValidator {
    param(
        [Parameter(Mandatory=$true)]$InputObject,
        [scriptblock]$Validator
    )

    if ($null -eq $Validator) { return $InputObject }
    return (& $Validator $InputObject)
}

function Resolve-McpProjectPath {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectRoot,
        [Parameter(Mandatory=$true)][string]$RelativePath
    )

    if ([IO.Path]::IsPathRooted($RelativePath) -or $RelativePath -match '^(?:[A-Za-z]:)?[\\/]') {
        throw "MCP Project path must be relative: $RelativePath"
    }
    $repositoryRoot = Split-Path -Parent $ProjectRoot
    $containmentPath = Join-Path $repositoryRoot ".kinotch/scripts/path-containment.ps1"
    if (-not (Get-Command Test-KntProjectPathContained -ErrorAction SilentlyContinue)) {
        if (-not (Test-Path -LiteralPath $containmentPath -PathType Leaf)) {
            throw "KiNoTch path containment helper is missing"
        }
        . $containmentPath
    }
    $candidate = [IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not (Test-KntProjectPathContained -Root $ProjectRoot -Candidate $candidate -AllowRoot)) {
        throw "MCP Project path escapes the Project boundary: $RelativePath"
    }
    return $candidate
}

function New-McpDiagnostic {
    param(
        [string]$Level = "info",
        [Parameter(Mandatory=$true)][string]$Message,
        $Data = @{}
    )

    return [pscustomobject]@{
        kind = "mcp-diagnostic"
        level = $Level
        message = $Message
        data = $Data
    }
}

function New-McpErrorEnvelope {
    param(
        [Parameter(Mandatory=$true)][string]$Code,
        [Parameter(Mandatory=$true)][string]$Message,
        $Details = $null
    )

    $envelope = [ordered]@{
        error = $Code
        message = $Message
    }
    if ($PSBoundParameters.ContainsKey("Details")) { $envelope.details = $Details }
    return [pscustomobject]$envelope
}

function New-McpCapabilities {
    param(
        [string]$Version = "",
        [string[]]$Capabilities = @()
    )

    return [pscustomobject]@{
        version = $Version
        capabilities = @($Capabilities)
    }
}
