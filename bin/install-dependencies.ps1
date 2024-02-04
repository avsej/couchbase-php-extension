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
if (Test-Path "${cmakeRoot}\bin\cmake.exe") {
    Write-Host "--- Installed CMake version (${cmakeRoot}):" (& "${cmakeRoot}\bin\cmake.exe" --version)
} else {
    $cmakeVersion = "3.28.1"
    $url = "https://github.com/Kitware/CMake/releases/download/v${cmakeVersion}/cmake-${cmakeVersion}-windows-x86_64.zip"
    Write-Host "--- Downloading CMake version ${cmakeVersion} from ${url}"
    $outputFilePath = "CMake${cmakeVersion}.zip"
    Invoke-WebRequest -Uri $url -OutFile $outputFilePath
    Write-Host "--- Download complete to ${outputFilePath}"

    Write-Host "--- Extract ${outputFilePath} to ${cmakeRoot}"
    Expand-Archive -Path ${outputFilePath} -DestinationPath ${cmakeRoot} -Force
    Get-ChildItem "${cmakeRoot}\cmake-${cmakeVersion}-windows-x86_64" | Move-Item -Destination "${cmakeRoot}" -Force

    Write-Host "--- Installation complete for CMake version ${cmakeVersion}"
    Remove-Item $outputFilePath
    Write-Host "--- Installed CMake version (${cmakeRoot}):" (& "${cmakeRoot}\bin\cmake.exe" --version)
}

$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
if (Test-Path "${sevenZipPath}") {
    Write-Host "--- 7-Zip is installed in ${sevenZipPath}"
}

$rubyVersion = "3.3.0"
$rubyMajorMinorVersion = $rubyVersion -replace '(\d+)\.(\d+)\.(\d+)', '$1$2'
$rubyRoot = "C:\Ruby${rubyMajorMinorVersion}-x64"
$rubyBinaryPath = "${rubyRoot}\bin\ruby.exe"

if (Test-Path $rubyBinaryPath) {
    Write-Host "--- Installed Ruby version (${rubyRoot}):" (& $rubyBinaryPath --version)
} else {
    $url = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-${rubyVersion}-1/rubyinstaller-devkit-${rubyVersion}-1-x64.exe"
    Write-Host "--- Downloading RubyInstaller version ${rubyVersion} from ${url}"

    $outputFilePath = "RubyInstaller-${rubyVersion}-1-x64.exe"
    Invoke-WebRequest -Uri $url -OutFile $outputFilePath
    $outputFilePath = Resolve-Path -Path $outputFilePath

    Write-Host "--- Download complete to ${outputFilePath}. Installing Ruby version ${rubyVersion}"
    $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $outputFilePath -ArgumentList "/NORESTART", "/VERYSILENT", "/CURRENTUSER", "/LOG=install-${rubyVersion}.log"
    if ($process.ExitCode -eq 0) {
        Write-Host "--- Installation complete for Ruby version ${rubyVersion}"
    } else {
        Write-Host "--- Installation failed with exit code $($process.ExitCode)"
        exit 1
    }

    Remove-Item $outputFilePath

    Write-Host "--- Installed Ruby version (${rubyRoot}):" (& $rubyBinaryPath --version)
}

$process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $rubyBinaryPath -ArgumentList "-rrubygems", "-rnokogiri", "-e", "`"puts Nokogiri::VERSION`""
if (-not ($process.ExitCode -eq 0)) {
    $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath "${rubyRoot}\bin\gem.cmd" -ArgumentList "install", "nokogiri"
    if ($process.ExitCode -eq 0) {
        Write-Host "--- Installed nokogiri library for Ruby"
    } else {
        Write-Host "--- Failed to install nokogiri library, code $($process.ExitCode)"
        exit 1
    }
}

$phpVersions = "8.3.2", "8.2.15", "8.1.27"
$pearInstallerFilePath = "${projectRoot}/go-pear.phar"
$phpSdkBinaryToolsFilePath = "${projectRoot}/php-sdk-binary-tools.zip"

foreach ($phpVersion in $phpVersions) {
    foreach ($tsFlavour in ("", "-nts")) {
        $phpRoot = "$env:LOCALAPPDATA\php-${phpVersion}${tsFlavour}"

        if (Test-Path "${phpRoot}\php.exe") {
            Write-Host "--- PHP ${phpVersion} is already installed in ${phpRoot}. Skipping download and installation."
            Write-Host "--- Installed PHP version:" (& "${phpRoot}\php.exe" --version)
        } else {
            $phpArchiveUrl = "https://windows.php.net/downloads/releases/php-${phpVersion}${tsFlavour}-Win32-vs16-x64.zip"
            $phpArchiveFilePath = "php-${phpVersion}${tsFlavour}.zip"

            Write-Host "--- Downloading PHP version ${phpVersion}${tsFlavour} from ${phpArchiveUrl}"
            Invoke-WebRequest -Uri $phpArchiveUrl -OutFile $phpArchiveFilePath
            $arguments = @("x", "-y", "-o`"${phpRoot}`"", "`"${phpArchiveFilePath}`"")
            $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $sevenZipPath -ArgumentList $arguments
            if (-not $process.ExitCode -eq 0) {
                Write-Host "--- Unable to extract PHP distro (${phpArchiveFilePath}). Exit code $($process.ExitCode)"
                exit 1
            }
            Remove-Item $phpArchiveFilePath

            $phpDevelPackUrl = "https://windows.php.net/downloads/releases/php-devel-pack-${phpVersion}${tsFlavour}-Win32-vs16-x64.zip"
            $phpDevelPackFilePath = "php-devel-pack-${phpVersion}${tsFlavour}.zip"
            Write-Host "--- Downloading PHP version ${phpVersion}${tsFlavour} from ${phpDevelPackUrl}"
            Invoke-WebRequest -Uri $phpDevelPackUrl -OutFile $phpDevelPackFilePath
            $arguments = @("x", "-y", "-o`"${phpRoot}`"", "`"${phpDevelPackFilePath}`"")
            $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $sevenZipPath -ArgumentList $arguments
            if (-not $process.ExitCode -eq 0) {
                Write-Host "--- Unable to extract PHP distro (${phpDevelPackFilePath}). Exit code $($process.ExitCode)"
                exit 1
            }
            Copy-Item -Force -Recurse -Path "${phpRoot}\php-${phpVersion}-devel-vs16-x64\*" -Destination "${phpRoot}\"
            Remove-Item -Force -Path $phpDevelPackFilePath
            Remove-Item -Force -Recurse -Path "${phpRoot}\php-${phpVersion}-devel-vs16-x64"

            # protect against spaces in the path
            $content = Get-Content "${phpRoot}\phpize.bat" -Raw
            $content = $content -Replace 'SET PHP_BUILDCONF_PATH=%~dp0', 'SET PHP_BUILDCONF_PATH="%~dp0"'
            $content | Set-Content "${phpRoot}\phpize.bat"

            # install SDK binary tools
            if (-not (Test-Path "${phpSdkBinaryToolsFilePath}")) {
                $phpSdkBinaryToolsUrl = "https://github.com/php/php-sdk-binary-tools/archive/refs/tags/php-sdk-2.2.0.zip"
                Invoke-WebRequest -Uri $phpSdkBinaryToolsUrl -OutFile $phpSdkBinaryToolsFilePath
            }
            $arguments = @("x", "-y", "-o`"${phpRoot}`"", "`"${phpSdkBinaryToolsFilePath}`"")
            $process = Start-Process -Wait -NoNewWindow -PassThru -FilePath $sevenZipPath -ArgumentList $arguments
            if (-not $process.ExitCode -eq 0) {
                Write-Host "--- Unable to extract PHP SDK binary tools (${phpSdkBinaryToolsFilePath}). Exit code $($process.ExitCode)"
                exit 1
            }
            Copy-Item -Force -Recurse -Path "${phpRoot}\php-sdk-binary-tools-php-sdk-2.2.0\msys2" -Destination "${phpRoot}\"
            Remove-Item -Force -Recurse -Path "${phpRoot}\php-sdk-binary-tools-php-sdk-2.2.0"

            # install PEAR
            if (-not (Test-Path "${pearInstallerFilePath}")) {
                $pearInstallerUrl = "https://pear.php.net/go-pear.phar"
                Invoke-WebRequest -Uri $pearInstallerUrl -OutFile $pearInstallerFilePath
            }
            Push-Location $phpRoot
                $inputFilePath = "__standard_input.txt"
                @("local", "yes") | Out-File -FilePath $inputFilePath -Encoding utf8
                $process = Start-Process -Wait -NoNewWindow -PassThru -RedirectStandardInput $inputFilePath -FilePath "${phpRoot}\php.exe" -ArgumentList "`"$pearInstallerFilePath`""
                if (-not $process.ExitCode -eq 0) {
                    Write-Host "--- Unable to install PEAR (${pearInstallerFilePath}) for ${phpRoot}. Exit code $($process.ExitCode)"
                    exit 1
                }
                Remove-Item -Path $inputFilePath
            Pop-Location

            Write-Host "--- Prepared PHP ${phpVersion}${tsFlavour} in ${phpRoot}"
        }
    }
}

Remove-Item -Path $pearInstallerFilePath -ErrorAction SilentlyContinue
Remove-Item -Path $phpSdkBinaryToolsFilePath -ErrorAction SilentlyContinue
