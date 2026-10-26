# Cambric Game — Windows install helper
# Usage: .\install_windows.ps1 -Source <build_dir> -Dest <install_dir>
#
# Copies the Windows release build to the destination directory.
# Run after: dart run scripts/cambric.dart build windows

param(
  [string]$Source = "build\windows\x64\runner\Release",
  [string]$Dest   = "$env:LOCALAPPDATA\CambricGame"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Source)) {
  Write-Error "Source not found: $Source. Run 'dart run scripts/cambric.dart build windows' first."
  exit 1
}

Write-Host "Installing to $Dest ..."
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item -Recurse -Force "$Source\*" $Dest
Write-Host "Done. Installed to $Dest"

# Optional: create a desktop shortcut
$exeName = Get-ChildItem $Dest -Filter "*.exe" | Select-Object -First 1
if ($exeName) {
  $shortcut = "$env:USERPROFILE\Desktop\$($exeName.BaseName).lnk"
  $ws = New-Object -ComObject WScript.Shell
  $sc = $ws.CreateShortcut($shortcut)
  $sc.TargetPath = "$Dest\$($exeName.Name)"
  $sc.WorkingDirectory = $Dest
  $sc.Save()
  Write-Host "Shortcut created: $shortcut"
}
