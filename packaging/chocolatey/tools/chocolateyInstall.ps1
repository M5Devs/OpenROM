$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName    = 'openrom'
  fileType       = 'exe'
  url64bit       = 'https://github.com/M5Devs/OpenROM/releases/download/v3.9.5/OpenROM-v3.9.5-Setup.exe'
  silentArgs     = '/S'
  validExitCodes = @(0)
  checksum64     = 'AUTO_CHECKSUM_REPLACED_BY_ACTION'
  checksumType64 = 'sha256'
}

Install-ChocolateyPackage @packageArgs
