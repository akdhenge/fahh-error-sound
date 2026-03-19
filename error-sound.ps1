# =============================================================================
# ps-error-sound — Terminal Error Sound for PowerShell
# Author  : Akshay
# Version : 1.0.0
# GitHub  : https://github.com/akdhenge/ps-error-sound
#
# Plays a WAV file whenever a command fails in your PowerShell terminal.
# Detects two kinds of failures:
#   - External programs (git, npm, tsc, etc.) via $LASTEXITCODE
#   - PowerShell cmdlet errors via the $Error list
#
# Usage after install:
#   Enable-ErrorSound    # turn on (persists across sessions)
#   Disable-ErrorSound   # turn off (persists across sessions)
# =============================================================================

# --- Configuration -----------------------------------------------------------

# Path to your WAV file. The installer places error.wav here automatically.
# Change this to any .wav file you prefer.
$_ESWavPath = "$env:USERPROFILE\.ps-error-sound\error.wav"

# -----------------------------------------------------------------------------

# Persistent toggle state — stored on disk so on/off survives session restarts
$_ESStateFile = "$env:USERPROFILE\.ps-error-sound\state"

# Read saved state from disk; default to enabled if no state file exists yet
$global:ErrorSoundEnabled = if (Test-Path $_ESStateFile) {
    (Get-Content $_ESStateFile) -eq "true"
} else { $true }

# Skip the very first prompt after shell startup — $LASTEXITCODE is undefined
# at that point and would cause a false trigger on some systems
$global:_ESIsFirstPrompt = $true

# Snapshot of $Error.Count from the previous prompt — used to detect new errors
$global:_ESLastErrorCount = 0

# Snapshot of $LASTEXITCODE from the previous prompt — used to fire the sound
# only once per failing external command, not on every PS cmdlet that follows it
$global:_ESLastExitCode = 0

# Pre-load the WAV into memory at startup so Play() fires instantly.
# Without this, SoundPlayer reads the file from disk on every play call,
# adding a noticeable delay before each sound.
if (Test-Path $_ESWavPath) {
    $global:_ESPlayer = New-Object System.Media.SoundPlayer $_ESWavPath
    $global:_ESPlayer.Load()
} else {
    Write-Warning "ps-error-sound: WAV not found at '$_ESWavPath'. See README or run: .\install.ps1 -WavPath 'C:\path\to\sound.wav'"
}


# The prompt function runs automatically after every command.
# NOTE: If you already have a custom prompt function in your profile,
# you will need to merge this logic into it manually (see README).
function prompt {
    $currentErrorCount = $global:Error.Count

    # Condition 1: external command failure (git, npm, tsc, ping, etc.)
    # $LASTEXITCODE is non-zero AND changed since last prompt, so we only
    # trigger once per new failure rather than on every cmdlet that runs after
    $exitFailed = (
        $LASTEXITCODE -ne $null -and
        $LASTEXITCODE -ne 0 -and
        $LASTEXITCODE -ne $global:_ESLastExitCode
    )

    # Condition 2: PowerShell cmdlet error (e.g. Get-Item on a missing path)
    # $Error is a rolling list — if its count grew, a new error was added
    $psErrored = ($currentErrorCount -gt $global:_ESLastErrorCount)

    if (-not $global:_ESIsFirstPrompt -and $global:ErrorSoundEnabled -and ($exitFailed -or $psErrored)) {
        if ($global:_ESPlayer) {
            try { $global:_ESPlayer.Play() } catch {}
        }
    }

    # Save current state as baseline for the next prompt call
    $global:_ESLastExitCode   = $LASTEXITCODE
    $global:_ESLastErrorCount = $currentErrorCount
    $global:_ESIsFirstPrompt  = $false

    # Return the standard PowerShell prompt string
    "PS $($executionContext.SessionState.Path.CurrentLocation)> "
}


# Enable the error sound for this session and all future sessions
function Enable-ErrorSound {
    $global:ErrorSoundEnabled = $true
    "true" | Set-Content $_ESStateFile
    Write-Host "Error sound enabled"
}

# Disable the error sound for this session and all future sessions
function Disable-ErrorSound {
    $global:ErrorSoundEnabled = $false
    "false" | Set-Content $_ESStateFile
    Write-Host "Error sound disabled"
}
