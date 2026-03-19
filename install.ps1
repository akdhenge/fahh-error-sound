# =============================================================================
# ps-error-sound — Installer
# =============================================================================
# Copies the script to ~/.ps-error-sound/ and wires it into your $PROFILE.
#
# Basic usage (uses sounds/error.wav from the repo):
#   .\install.ps1
#
# Specify your own WAV file:
#   .\install.ps1 -WavPath "C:\Users\You\Music\MySound.wav"
#
# Uninstall:
#   .\install.ps1 -Uninstall
# =============================================================================

param(
    # Optional: path to a custom WAV file to use as the error sound
    [string]$WavPath,

    # Remove ps-error-sound from your profile and delete installed files
    [switch]$Uninstall
)

$installDir  = "$env:USERPROFILE\.ps-error-sound"
$destScript  = "$installDir\error-sound.ps1"
$destWav     = "$installDir\error.wav"
$profileLine = ". '$destScript'"
$marker      = "ps-error-sound"

# --- Uninstall ---------------------------------------------------------------
if ($Uninstall) {
    # Remove the dot-source line from $PROFILE
    if (Test-Path $PROFILE) {
        $lines = Get-Content $PROFILE | Where-Object { $_ -notmatch $marker }
        $lines | Set-Content $PROFILE
        Write-Host "Removed ps-error-sound from `$PROFILE."
    }

    # Delete the install directory
    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
        Write-Host "Deleted $installDir."
    }

    Write-Host "Uninstall complete. Reload your profile: . `$PROFILE"
    return
}

# --- Install -----------------------------------------------------------------

# Create the install directory if it doesn't exist
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# Copy the main script to the install directory
Copy-Item (Join-Path $PSScriptRoot "error-sound.ps1") $destScript -Force
Write-Host "Installed script to $destScript"

# Resolve WAV source: prefer -WavPath arg, then repo sounds/, then warn
if ($WavPath) {
    if (Test-Path $WavPath) {
        Copy-Item $WavPath $destWav -Force
        Write-Host "Copied WAV from $WavPath"
    } else {
        Write-Warning "WAV file not found at '$WavPath'. Skipping."
    }
} elseif (Test-Path (Join-Path $PSScriptRoot "sounds\fahh.wav")) {
    Copy-Item (Join-Path $PSScriptRoot "sounds\fahh.wav") $destWav -Force
    Write-Host "Copied default sound (fahh.wav) from repo"
} elseif (-not (Test-Path $destWav)) {
    Write-Warning "No WAV file found. Place a .wav file at '$destWav', or rerun:"
    Write-Warning "  .\install.ps1 -WavPath 'C:\path\to\your\sound.wav'"
}

# Ensure $PROFILE exists (it may not on a fresh Windows install)
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Host "Created `$PROFILE at $PROFILE"
}

# Append the dot-source line only if not already present
if (Select-String -Path $PROFILE -Pattern $marker -Quiet) {
    Write-Host "ps-error-sound already in `$PROFILE — skipping."
} else {
    "`n# $marker`n$profileLine" | Add-Content $PROFILE
    Write-Host "Added ps-error-sound to `$PROFILE."
}

# Remind about execution policy — required to run .ps1 scripts
$policy = (Get-ExecutionPolicy -Scope CurrentUser)
if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Write-Host ""
    Write-Host "NOTE: Your execution policy is '$policy'. Run this to allow scripts:"
    Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
}

Write-Host ""
Write-Host "Done! Reload your profile to activate:"
Write-Host "  . `$PROFILE"
