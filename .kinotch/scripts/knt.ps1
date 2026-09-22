param(
    [string]$RootOverride,

    [Parameter(Position=0)]
    [string]$Command = "help",

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"

if ($RootOverride) {
    $Root = (Resolve-Path -LiteralPath $RootOverride).Path
    $BaseDir = Join-Path $Root ".kinotch"
}
else {
    $BaseDir = Split-Path -Parent $PSScriptRoot
    $Root = Split-Path -Parent $BaseDir
}

$ManifestPath = Join-Path $Root "project/project.json"
$BaseFilesPath = Join-Path $BaseDir "base-files.json"
$ValidationPath = Join-Path $BaseDir "scripts/knt-validation.ps1"
$BaseIndexScriptPath = Join-Path $BaseDir "scripts/update-base-index.ps1"

if (-not (Test-Path -LiteralPath $ValidationPath -PathType Leaf)) {
    throw "Validation script not found: $ValidationPath"
}
. $ValidationPath
if (-not (Test-Path -LiteralPath $BaseIndexScriptPath -PathType Leaf)) {
    throw "Base index script not found: $BaseIndexScriptPath"
}
. $BaseIndexScriptPath

function Write-Knt([string]$Message) {
    Write-Host "[knt] $Message"
}

function Get-Manifest {
    return Get-KntJson -Path $ManifestPath
}

function Test-BaseFiles {
    if (-not (Test-Path -LiteralPath $BaseFilesPath -PathType Leaf)) {
        Write-Knt "base-files.json is missing."
        return $false
    }
    $index = Get-KntJson -Path $BaseFilesPath
    $ok = $true
    $currentVersion = (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $BaseDir "BASE_VERSION")).Trim()
    if ([string]$index.base_version -ne $currentVersion) {
        Write-Host "[base-check] VERSION  index=$($index.base_version) current=$currentVersion" -ForegroundColor Yellow
        $ok = $false
    }
    $indexedPaths = @($index.files | ForEach-Object { [string]$_.path })
    foreach ($expectedPath in @(Get-BaseProtectedPaths -Root $Root)) {
        if ($expectedPath -notin $indexedPaths) {
            Write-Host "[base-check] UNINDEXED  $expectedPath" -ForegroundColor Yellow
            $ok = $false
        }
    }
    foreach ($indexedPath in $indexedPaths) {
        if ($indexedPath -notin @(Get-BaseProtectedPaths -Root $Root)) {
            Write-Host "[base-check] ORPHANED  $indexedPath" -ForegroundColor Yellow
            $ok = $false
        }
    }
    foreach ($entry in @($index.files)) {
        $path = Join-Path $Root $entry.path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Write-Host "[base-check] MISSING  $($entry.path)" -ForegroundColor Red
            $ok = $false
            continue
        }
        $hash = Get-BaseFileHash -Path $path
        if ($hash -ne $entry.sha256) {
            Write-Host "[base-check] CHANGED  $($entry.path)" -ForegroundColor Yellow
            $ok = $false
        }
    }
    if ($ok) { Write-Knt "Base files: OK" }
    return $ok
}

function Resolve-Command($Manifest, [string]$Name) {
    $prop = $Manifest.commands.PSObject.Properties[$Name]
    if (-not $prop) { return $null }
    $value = $prop.Value
    if ($value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($value)) { return $null }
        return [pscustomobject]@{ run = $value; cwd = "project" }
    }
    if (-not $value.run) { return $null }
    $cwd = if ($value.cwd) { [string]$value.cwd } else { "project" }
    return [pscustomobject]@{ run = [string]$value.run; cwd = $cwd }
}

function Get-ManifestPathValue($Manifest, [string]$Name, [string]$Default) {
    $value = Get-KntJsonProperty $Manifest.paths $Name
    if ([string]::IsNullOrWhiteSpace([string]$value)) { return $Default }
    return [string]$value
}

function Invoke-ProjectCommand($Manifest, [string]$Name) {
    $spec = Resolve-Command $Manifest $Name
    if (-not $spec) {
        Write-Knt "Command '$Name' is not configured for this project."
        return 0
    }
    $cwd = Join-Path $Root $spec.cwd
    if (-not (Test-Path -LiteralPath $cwd -PathType Container)) {
        Write-Host "[doctor] MISSING command cwd: $($spec.cwd)" -ForegroundColor Red
        return 1
    }
    $argText = if ($RemainingArgs) {
        " " + (($RemainingArgs | ForEach-Object { '"' + ($_ -replace '"','\"') + '"' }) -join ' ')
    }
    else { "" }
    Write-Knt "$Name -> $($spec.run)"
    Push-Location $cwd
    try {
        Invoke-Expression ($spec.run + $argText)
        if ($null -ne $LASTEXITCODE) { return $LASTEXITCODE }
        return 0
    }
    finally {
        Pop-Location
    }
}

function Add-DoctorSchemaErrors {
    param([System.Collections.Generic.List[string]]$Errors, $Data, $Schema, [string]$Path)
    foreach ($errorText in @(Test-KntSchema -Data $Data -Schema $Schema -Path $Path)) {
        [void]$Errors.Add($errorText)
    }
}

function Invoke-Doctor($Manifest) {
    $ok = $true
    Write-Knt "Repository root: $Root"
    Write-Knt "Project: $($Manifest.project.name) [$($Manifest.project.type)]"
    Write-Knt "Profile: $($Manifest.profile)"
    $baseVersion = (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $BaseDir "BASE_VERSION")).Trim()
    Write-Knt "Base version: $baseVersion"

    if (-not $RootOverride -and -not (Test-BaseFiles)) { $ok = $false }

    $required = @(
        "project/docs/INDEX.md",
        "project/docs/CURRENT_STATE.md",
        "project/contracts/actions.json",
        "project/contracts/surfaces.json"
    )
    foreach ($requiredPath in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $requiredPath) -PathType Leaf)) {
            Write-Host "[doctor] MISSING $requiredPath" -ForegroundColor Red
            $ok = $false
        }
    }

    $schemaErrors = New-Object System.Collections.Generic.List[string]
    $manifestSchema = Get-KntJson -Path (Join-Path $BaseDir "schemas/project.schema.json")
    $actionSchema = Get-KntJson -Path (Join-Path $BaseDir "schemas/action.schema.json")
    $surfaceSchema = Get-KntJson -Path (Join-Path $BaseDir "schemas/surface.schema.json")
    Add-DoctorSchemaErrors $schemaErrors $Manifest $manifestSchema "project/project.json"

    $projectRoot = Join-Path $Root "project"
    $actionRelative = Get-ManifestPathValue $Manifest "actions" "contracts/actions.json"
    $surfaceRelative = Get-ManifestPathValue $Manifest "surfaces" "contracts/surfaces.json"
    $actionPath = Join-Path $projectRoot $actionRelative
    $surfacePath = Join-Path $projectRoot $surfaceRelative
    if (Test-Path -LiteralPath $actionPath -PathType Leaf) {
        Add-DoctorSchemaErrors $schemaErrors (Get-KntJson -Path $actionPath) $actionSchema $actionRelative
    }
    if (Test-Path -LiteralPath $surfacePath -PathType Leaf) {
        Add-DoctorSchemaErrors $schemaErrors (Get-KntJson -Path $surfacePath) $surfaceSchema $surfaceRelative
    }

    if ($schemaErrors.Count -gt 0) {
        Write-Host "[doctor] Schema validation failed" -ForegroundColor Red
        foreach ($errorText in $schemaErrors) {
            Write-Host "[doctor] $errorText" -ForegroundColor Red
        }
        $ok = $false
    }

    $profilePath = Join-Path $BaseDir ("profiles/" + [string]$Manifest.profile + ".json")
    $profile = $null
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        Write-Host "[doctor] MISSING profile: $($Manifest.profile)" -ForegroundColor Red
        $ok = $false
    }
    else {
        $profile = Get-KntJson -Path $profilePath
    }

    $modules = @($Manifest.runtime.modules)
    Write-Knt ("Runtime modules: " + ($(if ($modules.Count) { $modules -join ", " } else { "(none)" })))
    $enabled = @($Manifest.surfaces.PSObject.Properties | Where-Object { $_.Value -eq $true } | ForEach-Object { $_.Name })
    Write-Knt ("Surfaces: " + ($(if ($enabled.Count) { $enabled -join ", " } else { "(none)" })))

    if ($null -ne $profile) {
        $recommendedModules = @($profile.runtime_modules)
        $missingModules = @($recommendedModules | Where-Object { $_ -notin $modules })
        $extraModules = @($modules | Where-Object { $_ -notin $recommendedModules })
        if ($missingModules.Count -or $extraModules.Count) {
            Write-Host "[doctor] WARN profile runtime module recommendation differs from manifest." -ForegroundColor Yellow
        }

        $profileSurfaces = Get-KntJsonProperty $profile "surfaces"
        foreach ($profileSurface in @($profileSurfaces.PSObject.Properties | Where-Object { $_.Value -eq $true })) {
            $manifestValue = Get-KntJsonProperty $Manifest.surfaces $profileSurface.Name
            if ($manifestValue -ne $true) {
                Write-Host "[doctor] CONTRADICTION profile surface '$($profileSurface.Name)' is not enabled in manifest." -ForegroundColor Red
                $ok = $false
            }
        }
        foreach ($manifestSurface in @($Manifest.surfaces.PSObject.Properties | Where-Object { $_.Value -eq $true })) {
            $profileValue = Get-KntJsonProperty $profileSurfaces $manifestSurface.Name
            if ($profileValue -ne $true) {
                Write-Host "[doctor] WARN manifest surface '$($manifestSurface.Name)' is not recommended by profile." -ForegroundColor Yellow
            }
        }
    }

    foreach ($pathProperty in @($Manifest.paths.PSObject.Properties)) {
        if ([string]::IsNullOrWhiteSpace([string]$pathProperty.Value)) { continue }
        $candidate = Join-Path $projectRoot ([string]$pathProperty.Value)
        if (-not (Test-Path -LiteralPath $candidate)) {
            Write-Host "[doctor] MISSING path: $($pathProperty.Value) ($($pathProperty.Name))" -ForegroundColor Red
            $ok = $false
        }
    }

    foreach ($commandProperty in @($Manifest.commands.PSObject.Properties)) {
        $spec = Resolve-Command $Manifest $commandProperty.Name
        if ($spec -and -not (Test-Path -LiteralPath (Join-Path $Root $spec.cwd) -PathType Container)) {
            Write-Host "[doctor] MISSING command cwd: $($spec.cwd) ($($commandProperty.Name))" -ForegroundColor Red
            $ok = $false
        }
    }

    $configured = @($Manifest.commands.PSObject.Properties | Where-Object { $null -ne (Resolve-Command $Manifest $_.Name) } | ForEach-Object { $_.Name })
    Write-Knt ("Commands: " + ($(if ($configured.Count) { $configured -join ", " } else { "(none configured yet)" })))

    if ($ok) {
        Write-Host "[doctor] OK" -ForegroundColor Green
        return 0
    }
    Write-Host "[doctor] FAILED" -ForegroundColor Red
    return 1
}

function Show-Help {
    @"
KiNoTch. repository command router

Usage:
  knt.cmd <command>
  .kinotch/scripts/knt.ps1 <command>

Common commands:
  doctor      Base/project structure and schema diagnostics
  base-check  Detect modifications in common Base files
  base-refresh Regenerate Base file hashes (repository-base only)
  setup       Project setup command
  dev         Project development command
  test        Project tests
  build       Project build
  verify      Project verify command; falls back to test + build
  smoke       Project smoke / real-entry check
  help        This help
"@ | Write-Host
}

try {
    if ($Command -eq "help" -or $Command -eq "--help" -or $Command -eq "-h") {
        Show-Help
        exit 0
    }
    if ($Command -eq "base-check") {
        if (Test-BaseFiles) { exit 0 } else { exit 1 }
    }
    if ($Command -eq "base-refresh") {
        $refreshManifest = Get-Manifest
        if ($refreshManifest.project.type -ne "repository-base") {
            throw "base-refresh is only available for project.type repository-base"
        }
        Update-BaseIndex -Root $Root
        Write-Knt "Base index refreshed"
        exit 0
    }

    $manifest = Get-Manifest
    if ($Command -eq "doctor") { exit (Invoke-Doctor $manifest) }

    if ($Command -eq "verify") {
        $direct = Resolve-Command $manifest "verify"
        if ($direct) { exit (Invoke-ProjectCommand $manifest "verify") }
        foreach ($fallback in @("test", "build")) {
            if (Resolve-Command $manifest $fallback) {
                $code = Invoke-ProjectCommand $manifest $fallback
                if ($code -ne 0) { exit $code }
            }
        }
        exit 0
    }

    if ($Command -in @("setup","dev","test","build","smoke","deploy")) {
        exit (Invoke-ProjectCommand $manifest $Command)
    }

    Write-Host "Unknown command: $Command" -ForegroundColor Red
    Show-Help
    exit 2
}
catch {
    Write-Host "[knt] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}
