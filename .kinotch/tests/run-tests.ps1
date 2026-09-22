$ErrorActionPreference = "Stop"

$TestDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $TestDir)
$FixtureRoot = Join-Path $RepoRoot ".kinotch/tests/fixtures"
$PowerShellExecutable = (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if ([string]::IsNullOrWhiteSpace($PowerShellExecutable)) {
    $PowerShellExecutable = (Get-Command powershell -ErrorAction Stop | Select-Object -First 1).Source
}
. (Join-Path $RepoRoot ".kinotch/scripts/update-base-index.ps1")
. (Join-Path $RepoRoot ".kinotch/scripts/knt-validation.ps1")
$Passed = 0
$Failed = 0

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) {
        throw "$Message expected=[$Expected] actual=[$Actual]"
    }
}

function Get-SchemaKeywordNames {
    param($Schema)

    $names = New-Object System.Collections.Generic.List[string]
    if ((Get-KntJsonType $Schema) -ne "object") { return @() }
    foreach ($property in $Schema.PSObject.Properties) {
        [void]$names.Add([string]$property.Name)
        switch ([string]$property.Name) {
            "properties" {
                foreach ($child in @($property.Value.PSObject.Properties)) {
                    foreach ($name in @(Get-SchemaKeywordNames $child.Value)) { [void]$names.Add($name) }
                }
            }
            "additionalProperties" {
                if ((Get-KntJsonType $property.Value) -eq "object") {
                    foreach ($name in @(Get-SchemaKeywordNames $property.Value)) { [void]$names.Add($name) }
                }
            }
            "oneOf" {
                foreach ($candidate in @($property.Value)) {
                    foreach ($name in @(Get-SchemaKeywordNames $candidate)) { [void]$names.Add($name) }
                }
            }
            "items" {
                foreach ($name in @(Get-SchemaKeywordNames $property.Value)) { [void]$names.Add($name) }
            }
        }
    }
    return @($names | Select-Object -Unique)
}

function Get-FixtureProtectedPaths([string]$Root) {
    $fixed = @(
        ".editorconfig",
        ".gitattributes",
        ".gitignore",
        ".github/workflows/verify.yml",
        "AGENTS.md",
        "knt.cmd"
    )
    $common = @(Get-ChildItem -LiteralPath (Join-Path $Root ".kinotch") -Recurse -File -Force | ForEach-Object {
        $relative = ConvertTo-BaseRelativePath -Root $Root -AbsolutePath $_.FullName
        if ($relative -ne ".kinotch/base-files.json") { $relative }
    })
    return @($fixed + $common | Sort-Object)
}

function Set-FixtureBaseIndex([string]$Root) {
    $entries = @(Get-FixtureProtectedPaths $Root | ForEach-Object {
        [pscustomobject]@{
            path = $_
            sha256 = Get-BaseFileHash -Path (Join-Path $Root $_)
        }
    })
    $index = [pscustomobject]@{
        schema_version = 1
        base_version = (Get-Content -Raw -LiteralPath (Join-Path $Root ".kinotch/BASE_VERSION")).Trim()
        files = $entries
    }
    $json = ConvertTo-Json $index -Depth 10
    [IO.File]::WriteAllText((Join-Path $Root ".kinotch/base-files.json"), $json + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
}

function Set-FixtureAsBase([string]$Root) {
    $manifestPath = Join-Path $Root "project/project.json"
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $manifest.project.type = "repository-base"
    [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json $manifest -Depth 20) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-KntFixture {
    param(
        [string]$Name,
        [string]$Command,
        [int]$ExpectedExit = 0,
        [scriptblock]$AssertOutput,
        [scriptblock]$Prepare
    )
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("kinotch-base-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    try {
        Get-ChildItem -Force $RepoRoot | Where-Object {
            $_.Name -notin @(".git", ".superpowers")
        } | Copy-Item -Destination $tempRoot -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $tempRoot "project") -Recurse -Force
        Copy-Item -LiteralPath (Join-Path $FixtureRoot $Name) -Destination (Join-Path $tempRoot "project") -Recurse -Force
        if ($Prepare) { & $Prepare $tempRoot }
        $router = Join-Path $tempRoot ".kinotch/scripts/knt.ps1"
        $outputLines = @(& $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $router -RootOverride $tempRoot $Command 2>&1)
        $exitCode = $LASTEXITCODE
        $output = $outputLines -join [Environment]::NewLine
        Assert-Equal $ExpectedExit $exitCode "$Name $Command exit code"
        if ($AssertOutput) { & $AssertOutput $tempRoot $output }
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-TestCase([string]$Name, [scriptblock]$Body) {
    try {
        & $Body
        $script:Passed++
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    catch {
        $script:Failed++
        Write-Host "[FAIL] $Name :: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Invoke-TestCase "Windows-style repository path is canonicalized" {
    $actual = ConvertTo-BaseRelativePath -Root "C:\repo" -AbsolutePath "C:\repo\.kinotch\README_BASE.md"
    Assert-Equal ".kinotch/README_BASE.md" $actual "Windows-style relative path"
}

Invoke-TestCase "Unix-style repository path is canonicalized" {
    $actual = ConvertTo-BaseRelativePath -Root "/home/user/repo" -AbsolutePath "/home/user/repo/.kinotch/README_BASE.md"
    Assert-Equal ".kinotch/README_BASE.md" $actual "Unix-style relative path"
}

Invoke-TestCase "Protected paths never begin with a separator" {
    $paths = @(Get-BaseProtectedPaths -Root $RepoRoot)
    Assert-True (@($paths | Where-Object { $_ -match "^[\\/]" }).Count -eq 0) "protected path has a leading separator"
}

Invoke-TestCase "Protected paths include hidden Base files" {
    $paths = @(Get-BaseProtectedPaths -Root $RepoRoot)
    Assert-True ($paths -contains ".kinotch/templates/project/.gitignore") "hidden template file is not protected"
}

Invoke-TestCase "Base file hash is line-ending stable" {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("kinotch-hash-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        $crlfPath = Join-Path $tempRoot "crlf.txt"
        $lfPath = Join-Path $tempRoot "lf.txt"
        [IO.File]::WriteAllText($crlfPath, "alpha`r`nbeta`r`n", $utf8)
        [IO.File]::WriteAllText($lfPath, "alpha`nbeta`n", $utf8)
        Assert-Equal (Get-BaseFileHash $lfPath) (Get-BaseFileHash $crlfPath) "line-ending stable Base hash"
    }
    finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Invoke-TestCase "Protected paths and Base index use canonical separators" {
    $paths = @(Get-BaseProtectedPaths -Root $RepoRoot)
    Assert-True (@($paths | Where-Object { $_ -match "\\" }).Count -eq 0) "protected path contains a Windows separator"
    $index = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot ".kinotch/base-files.json") | ConvertFrom-Json
    $indexedPaths = @($index.files | ForEach-Object { [string]$_.path })
    Assert-True (@($indexedPaths | Where-Object { $_ -match "^[\\/]" }).Count -eq 0) "index path has a leading separator"
    Assert-True (@($indexedPaths | Where-Object { $_ -match "\\" }).Count -eq 0) "index path contains a Windows separator"
}

Invoke-TestCase "valid minimal project passes doctor" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 0
}
Invoke-TestCase "valid command string remains accepted" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 0
}
Invoke-TestCase "valid command object remains accepted" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 0 -Prepare {
        param($root)
        $manifestPath = Join-Path $root "project/project.json"
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
        $manifest.commands.test = [pscustomobject]@{ run = "Write-Output valid"; cwd = "." }
        [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json $manifest -Depth 20) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    }
}
Invoke-TestCase "schema-valued additional command property is validated" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 1 -Prepare {
        param($root)
        $manifestPath = Join-Path $root "project/project.json"
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
        $manifest.commands.test = 123
        [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json $manifest -Depth 20) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    } -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "project/project.json.commands.test") "command schema path was not reported"
        Assert-True ($output -match "commands.test has type integer") "command type error was not reported"
    }
}
Invoke-TestCase "schema-valued additional path property is validated" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 1 -Prepare {
        param($root)
        $manifestPath = Join-Path $root "project/project.json"
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
        $manifest.paths.docs = 123
        [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json $manifest -Depth 20) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    } -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "project/project.json.paths.docs") "path schema path was not reported"
    }
}
Invoke-TestCase "oneOf requires exactly one matching schema" {
    $schema = [pscustomobject]@{
        oneOf = @(
            [pscustomobject]@{ type = "string" },
            [pscustomobject]@{ type = "string"; minLength = 1 }
        )
    }
    $multipleMatches = @(Test-KntSchema -Data "abc" -Schema $schema -Path "fixture.value")
    Assert-Equal 1 $multipleMatches.Count "overlapping oneOf schema count"
    Assert-True ($multipleMatches[0] -match "exactly one.*matched 2") "multiple oneOf matches were not rejected"

    $zeroMatches = @(Test-KntSchema -Data 123 -Schema $schema -Path "fixture.value")
    Assert-Equal 1 $zeroMatches.Count "zero-match oneOf schema count"
    Assert-True ($zeroMatches[0] -match "exactly one.*matched 0") "zero oneOf matches were not rejected"
}
Invoke-TestCase "Base schemas use the declared validator keyword subset" {
    $supported = @(
        "type", "required", "properties", "additionalProperties", "items", "oneOf",
        "enum", "const", "pattern", "minLength", "uniqueItems", '$schema', '$id', "title"
    )
    $explicitlyExcluded = @('$ref')
    $unsupported = New-Object System.Collections.Generic.List[string]
    foreach ($schemaFile in Get-ChildItem (Join-Path $RepoRoot ".kinotch/schemas") -Filter "*.json" -File) {
        $schema = Get-Content -Raw -Encoding UTF8 $schemaFile.FullName | ConvertFrom-Json
        foreach ($keyword in @(Get-SchemaKeywordNames $schema)) {
            if ($keyword -notin $supported -and $keyword -notin $explicitlyExcluded) {
                [void]$unsupported.Add("$($schemaFile.Name):$keyword")
            }
        }
    }
    Assert-Equal 0 $unsupported.Count ("unsupported schema keywords: " + ($unsupported -join ", "))
}
Invoke-TestCase "invalid manifest is rejected by schema" {
    Invoke-KntFixture -Name "invalid-manifest" -Command "doctor" -ExpectedExit 1 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "Schema validation failed") "schema error was not reported"
    }
}
Invoke-TestCase "invalid action registry is rejected by schema" {
    Invoke-KntFixture -Name "invalid-actions" -Command "doctor" -ExpectedExit 1 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "Schema validation failed") "action schema heading was not reported"
        Assert-True ($output -match "actions") "action schema path was not reported"
    }
}
Invoke-TestCase "invalid surface registry is rejected by schema" {
    Invoke-KntFixture -Name "invalid-surfaces" -Command "doctor" -ExpectedExit 1 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "Schema validation failed") "surface schema heading was not reported"
        Assert-True ($output -match "surfaces") "surface schema path was not reported"
    }
}
Invoke-TestCase "invalid JSON returns parse exit code" {
    Invoke-KntFixture -Name "invalid-json" -Command "doctor" -ExpectedExit 2 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "JSON parse error") "JSON parse error was not reported"
    }
}
Invoke-TestCase "missing required path is rejected" {
    Invoke-KntFixture -Name "missing-files" -Command "doctor" -ExpectedExit 1 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "MISSING path.*docs|docs.*MISSING path") "missing path was not reported"
    }
}
Invoke-TestCase "unknown command returns two" {
    Invoke-KntFixture -Name "valid-minimal" -Command "unknown-command" -ExpectedExit 2 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "Unknown command") "unknown command was not reported"
    }
}
Invoke-TestCase "project command exit code propagates" {
    Invoke-KntFixture -Name "command-failure" -Command "test" -ExpectedExit 7
}
Invoke-TestCase "verify fallback runs test then build" {
    Invoke-KntFixture -Name "verify-fallback" -Command "verify" -ExpectedExit 0 -AssertOutput {
        param($root, $output)
        $marker = Join-Path $root "project/command-order.txt"
        Assert-True (Test-Path $marker) "verify marker was not created"
        Assert-Equal ("test" + [Environment]::NewLine + "build") ((Get-Content -Raw $marker).Trim()) "verify order"
    }
}
Invoke-TestCase "command runs in declared cwd" {
    Invoke-KntFixture -Name "command-cwd" -Command "test" -ExpectedExit 0 -AssertOutput {
        param($root, $output)
        $marker = Join-Path $root "project/command-cwd.marker"
        Assert-True (Test-Path $marker) "cwd marker was not created"
        $actual = (Get-Content -Raw $marker).Trim()
        $expected = (Resolve-Path (Join-Path $root "project")).Path
        Assert-Equal $expected $actual "command cwd"
    }
}

Invoke-TestCase "changed Base file fails base-check" {
    Invoke-KntFixture -Name "valid-minimal" -Command "base-check" -ExpectedExit 1 -Prepare {
        param($root)
        Set-FixtureBaseIndex $root
        Add-Content -LiteralPath (Join-Path $root ".kinotch/README_BASE.md") -Value "changed for test"
    }
}

Invoke-TestCase "base-refresh indexes new common file" {
    Invoke-KntFixture -Name "valid-minimal" -Command "base-refresh" -ExpectedExit 0 -Prepare {
        param($root)
        Set-FixtureAsBase $root
        Set-FixtureBaseIndex $root
        Set-Content -LiteralPath (Join-Path $root ".kinotch/new-common.txt") -Value "new common file" -NoNewline
        $router = Join-Path $root ".kinotch/scripts/knt.ps1"
        $before = @(& $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $router -RootOverride $root base-check 2>&1)
        if ($LASTEXITCODE -eq 0) { throw "unindexed Base file was not rejected: $($before -join ' ')" }
    } -AssertOutput {
        param($root, $output)
        $router = Join-Path $root ".kinotch/scripts/knt.ps1"
        @(& $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $router -RootOverride $root base-check 2>&1) | Out-Null
        Assert-Equal 0 $LASTEXITCODE "base-check after refresh"
    }
}

Invoke-TestCase "Base documentation and profile status are finalized" {
    $spec = Get-Content -Raw (Join-Path $RepoRoot "project/docs/SPEC.md")
    $state = Get-Content -Raw (Join-Path $RepoRoot "project/docs/CURRENT_STATE.md")
    $runtime = Get-Content -Raw (Join-Path $RepoRoot ".kinotch/RUNTIME_INTEGRATION.md")
    $surfaceRegistry = Get-Content -Raw (Join-Path $RepoRoot "project/contracts/surfaces.json") | ConvertFrom-Json
    $baseVersion = (Get-Content -Raw (Join-Path $RepoRoot ".kinotch/BASE_VERSION")).Trim()
    Assert-True (([regex]::Matches($spec, "(?m)^\d+\. ")).Count -ge 10) "SPEC acceptance criteria are incomplete"
    Assert-True ($state -notmatch "Project-specific definition has not been filled") "CURRENT_STATE still contains a template placeholder"
    Assert-True ($state -match "Project Manifest / Action Registry / Surface Registry runtime schema validation") "CURRENT_STATE runtime validation wording is stale"
    Assert-True ($state -match "Error / Result / Progress / Resource / Artifact schema definitions") "CURRENT_STATE schema-definition wording is missing"
    Assert-True ($runtime -match "Action Result") "Runtime defined-contract content is missing"
    Assert-True ($runtime -match "ActionRequest") "Runtime candidate-contract content is missing"
    Assert-Equal 0 @($surfaceRegistry.surfaces.PSObject.Properties).Count "Base Surface Registry should be empty"
    Assert-Equal "0.2.1" $baseVersion "Base version"
    foreach ($profileFile in Get-ChildItem (Join-Path $RepoRoot ".kinotch/profiles") -File) {
        $profile = Get-Content -Raw -Encoding UTF8 $profileFile.FullName | ConvertFrom-Json
        Assert-Equal "planned" $profile.status "$($profileFile.Name) profile status"
    }
}

Invoke-TestCase "profile surface contradiction fails doctor" {
    Invoke-KntFixture -Name "valid-minimal" -Command "doctor" -ExpectedExit 1 -Prepare {
        param($root)
        $manifestPath = Join-Path $root "project/project.json"
        $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
        $manifest.profile = "cli"
        [IO.File]::WriteAllText($manifestPath, (ConvertTo-Json $manifest -Depth 20) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    } -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "CONTRADICTION") "profile surface contradiction was not reported"
    }
}

Invoke-TestCase "base-refresh is restricted to repository-base" {
    Invoke-KntFixture -Name "valid-minimal" -Command "base-refresh" -ExpectedExit 2 -AssertOutput {
        param($root, $output)
        Assert-True ($output -match "only available.*repository-base") "base-refresh restriction was not reported"
    }
}

Write-Host "Self-test summary: passed=$Passed failed=$Failed"
if ($Failed -gt 0) { exit 1 }
exit 0
