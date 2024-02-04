# Copyright 2020-Present Couchbase, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$VerbosePreference = 'Continue'

Get-Volume | Select-Object DriveLetter, FileSystemLabel, SizeRemaining, Size | Format-Table -AutoSize

Write-Host "--- PowerShell Version: $($PSVersionTable.PSVersion)"

# Workaround for "Filename too long" errors during git clone
git config --global core.longpaths true

$projectRoot = Resolve-Path -Path "$PSScriptRoot\.."
Write-Host "--- Project root: ${projectRoot}"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls

$cmakeRoot = "$env:LOCALAPPDATA\CMake"
$cmakeBinaryPath = "${cmakeRoot}\bin\cmake.exe"
Write-Host "--- Using CMake (${cmakeBinaryPath}):" (& "${cmakeBinaryPath}" --version)

$rubyRoot = "C:\Ruby33-x64"
$rubyBinaryPath = "${rubyRoot}\bin\ruby.exe"
Write-Host "--- Using Ruby (${rubyBinaryPath}):" (& "${rubyBinaryPath}" --version)

$vcvarsallCandidates = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
)
$vcvarsallPath = ""
$arch = "x64"
foreach ($candidate in $vcvarsallCandidates) {
    if (Test-Path $candidate) {
        $vcvarsallPath = $candidate
        break
    }
}
if (-not $vcvarsallPath) {
    Write-Host "--- Unable to locate script to load Visual Studio environment. Expected locations:\n${vcvarsallCandidates}"
    exit 1
}
Write-Host "--- Loading Visual Studio variables from: ${vcvarsallPath}"
& cmd.exe /c "`"${vcvarsallPath}`" ${arch} > nul 2>&1 && set" | . { process {
    if ($_ -match '^([^=]+)=(.*)') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], [System.EnvironmentVariableTarget]::Process)
    }
}}

Write-Host "--- Using MSVC:" (cl.exe 2>&1 | Select-String "Version").Line.Trim()

$originalPath = $env:PATH

$phpVersions = "8.3.2", "8.2.15", "8.1.27"

$defaultPhpVersion = $phpVersions[0]
$defaultPhpRoot = "$env:LOCALAPPDATA\php-${defaultPhpVersion}"
$defaultPhpBinaryPath = "${defaultPhpRoot}\php.exe"

$env:CB_PECL_PATH = "${defaultPhpRoot}\pecl.bat"
$env:CB_RUBY_PATH = $rubyBinaryPath
$process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $rubyBinaryPath -ArgumentList "`"${projectRoot}\bin\build-source-package.rb`""
if (-not $process.ExitCode -eq 0) {
    Write-Host "--- Unable to build source package. Exit code $($process.ExitCode)"
    exit 1
}
$packageVersion = (Get-Content -Path "${projectRoot}/PACKAGE_VERSION" -Raw).Trim()
$packageFileName = (Get-Content -Path "${projectRoot}/PACKAGE_FILENAME" -Raw).Trim()
$packageFilePath = "${projectRoot}\${packageFileName}"
Remove-Item -Path "${projectRoot}\PACKAGE_*" -Force
Write-Host "--- Building binary packages for SDK ${packageVersion} (${packageFilePath})"

foreach ($phpVersion in $phpVersions) {
    foreach ($tsFlavour in ("", "-nts")) {
        $phpRoot = "$env:LOCALAPPDATA\php-${phpVersion}${tsFlavour}"
        $env:PATH = "${cmakeRoot}\bin;${phpRoot}\msys2\usr\bin;$originalPath"

        $phpBinaryPath = "${phpRoot}\php.exe"
        $peclScriptPath = "${phpRoot}\pecl.bat"
        $phpizeScriptPath = "${phpRoot}\phpize.bat"

        Write-Host "--- Using PHP (${phpBinaryPath}):" (& "${phpBinaryPath}" --version)

        $workDirectory = "${projectRoot}\build-${phpVersion}${tsFlavour}"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Path $workDirectory
        New-Item -ItemType Directory -Force -Path $workDirectory

        Write-Host "--- Work directory: ${workDirectory}"
        Copy-Item -Path $packageFilePath -Destination $workDirectory

        Push-Location $workDirectory
            $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $peclScriptPath -ArgumentList "bundle", $packageFileName
            if (-not $process.ExitCode -eq 0) {
                Write-Host "--- Unable to unpack source package ${packageFileName} at ${workDirectory}. Exit code $($process.ExitCode)"
                exit 1
            }
            Push-Location "couchbase"
                $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $phpizeScriptPath
                if (-not $process.ExitCode -eq 0) {
                    Write-Host "--- Unable to generate configure script at ${workDirectory}. Exit code $($process.ExitCode)"
                    exit 1
                }
                $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath ".\configure.bat" -ArgumentList "--enable-couchbase"
                if (-not $process.ExitCode -eq 0) {
                    Write-Host "--- Unable to execute configure script at ${workDirectory}. Exit code $($process.ExitCode)"
                    exit 1
                }
            Pop-Location
        Pop-Location
        exit 0
    }
}
