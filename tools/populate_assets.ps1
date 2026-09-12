# Populate empty Shinra Core asset folders from Kenney CC0 packs (already partial on disk)
# and direct Kenney.nl downloads for audio.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tmp = Join-Path $env:TEMP "shinra_assets_dl"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

function Download-Zip($url, $name) {
  $zip = Join-Path $tmp "$name.zip"
  Write-Host "Downloading $name..."
  Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  $dest = Join-Path $tmp $name
  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $dest -Force
  return $dest
}

# --- Audio (Kenney CC0) ---
$impact = Download-Zip "https://kenney.nl/media/pages/assets/impact-sounds/aace7346e6-1677589452/impact-sounds.zip" "impact"
$iface  = Download-Zip "https://kenney.nl/media/pages/assets/interface-sounds/ddd8546989-1677589452/interface-sounds.zip" "interface"

$audioDir = Join-Path $root "assets\audio"
New-Item -ItemType Directory -Force -Path $audioDir | Out-Null

$wavs = Get-ChildItem $impact,$iface -Recurse -Filter "*.wav" -ErrorAction SilentlyContinue
if ($wavs.Count -lt 3) { throw "No WAV files found in Kenney downloads" }

# Timeline cue names used by the app (AudioCueService slugifies to .mp3 — we copy as mp3 path via wav too)
$map = @{
  "impact_sfx"   = ($wavs | Where-Object { $_.Name -match "impact|punch|hit" } | Select-Object -First 1)
  "footsteps"    = ($wavs | Where-Object { $_.Name -match "foot|step|walk" } | Select-Object -First 1)
  "whoosh"       = ($wavs | Where-Object { $_.Name -match "whoosh|swing|swipe" } | Select-Object -First 1)
  "voice_cue"    = ($wavs | Where-Object { $_.Name -match "confirm|select|tick" } | Select-Object -First 1)
  "music_start"  = ($wavs | Where-Object { $_.Name -match "open|start|power" } | Select-Object -First 1)
  "music_stop"   = ($wavs | Where-Object { $_.Name -match "close|back|cancel" } | Select-Object -First 1)
  "sfx_punch"    = ($wavs | Where-Object { $_.Name -match "impact|punch" } | Select-Object -First 1)
  "sfx_kick"     = ($wavs | Where-Object { $_.Name -match "impact|hit" } | Select-Object -Skip 1 -First 1)
  "sfx_slash"    = ($wavs | Where-Object { $_.Name -match "swing|swipe|whoosh" } | Select-Object -First 1)
  "sfx_explosion"= ($wavs | Where-Object { $_.Name -match "explosion|bomb|heavy" } | Select-Object -First 1)
  "sfx_impact"   = ($wavs | Where-Object { $_.Name -match "impact" } | Select-Object -First 1)
  "sfx_whoosh"   = ($wavs | Where-Object { $_.Name -match "whoosh|swing" } | Select-Object -First 1)
}

$i = 0
foreach ($key in $map.Keys) {
  $src = $map[$key]
  if (-not $src) { $src = $wavs[$i % $wavs.Count]; $i++ }
  Copy-Item $src.FullName (Join-Path $audioDir "$key.wav") -Force
  Write-Host "  audio/$key.wav <- $($src.Name)"
}

# --- Characters: copy Kenney part PNGs already bundled ---
$kenneyParts = Join-Path $root "assets\animation_assets\kenney_toon-characters"
$charDir = Join-Path $root "assets\characters"
New-Item -ItemType Directory -Force -Path $charDir | Out-Null
$parts = Get-ChildItem $kenneyParts -Recurse -Filter "*.png" | Where-Object { $_.FullName -match "\\Parts\\" }
$n = 0
foreach ($p in $parts) {
  $n++
  $safe = ($p.Directory.Parent.Parent.Name -replace "\s","_").ToLower()
  Copy-Item $p.FullName (Join-Path $charDir "${safe}_$($p.BaseName).png") -Force
}
Write-Host "Copied $n character part PNGs to assets/characters/"

# --- Effects: copy lightning pixel frames ---
$fxDir = Join-Path $root "assets\effects\sprites"
New-Item -ItemType Directory -Force -Path $fxDir | Out-Null
$lightning = Join-Path $root "assets\animation_assets\Pixel Art Skill Animations - Lightning"
if (Test-Path $lightning) {
  Get-ChildItem $lightning -Recurse -Filter "*.png" | Where-Object { $_.FullName -match "Frames" } | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $fxDir $_.Name) -Force
  }
  Write-Host "Copied lightning VFX frames to assets/effects/sprites/"
}

Write-Host "Done. Update pubspec.yaml assets list if needed."
