# ps-error-sound

Plays a custom sound whenever a command fails in your PowerShell terminal — covering both external programs (`git`, `npm`, `tsc`, etc.) and PowerShell cmdlet errors.

---

## Requirements

- Windows with PowerShell 5.1+

---

## Included sound

`sounds/fahh.wav` — based on the [FAHH meme sound](https://www.youtube.com/results?search_query=fahh+meme+sound). Used as the default. Swap it out for any `.wav` you like.

---

## Install

**1. Clone the repo**
```powershell
git clone https://github.com/akdhenge/ps-error-sound.git
cd ps-error-sound
```

**2. Run the installer**

The default `fahh.wav` is included — just run:
```powershell
.\install.ps1
```

Or use your own WAV file instead:
```powershell
.\install.ps1 -WavPath "C:\path\to\your\sound.wav"
```

**3. Reload your profile**
```powershell
. $PROFILE
```

That's it. The script lives at `~\.ps-error-sound\error-sound.ps1` and is dot-sourced into your profile automatically.

---

## Uninstall

```powershell
.\install.ps1 -Uninstall
. $PROFILE
```

---

## Usage

```powershell
Enable-ErrorSound    # turn on  (persists across sessions)
Disable-ErrorSound   # turn off (persists across sessions)
```

The on/off state is saved to `~\.ps-error-sound\state` so it survives restarts.

---

## Manual install (no installer)

If you'd rather not run a script, just add this to your `$PROFILE`:

```powershell
. "C:\path\to\cloned\repo\error-sound.ps1"
```

Open your profile in Notepad:
```powershell
notepad $PROFILE
```

If your profile doesn't exist yet:
```powershell
New-Item -Path $PROFILE -ItemType File -Force
```

---

## Custom prompt conflict

`error-sound.ps1` defines a `prompt` function. If you already have a custom `prompt` in your profile, the last one loaded wins.

To merge them, copy the detection block from `error-sound.ps1` into your existing `prompt` function:

```powershell
function prompt {
    $currentErrorCount = $global:Error.Count

    $exitFailed = ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $global:_ESLastExitCode)
    $psErrored  = ($currentErrorCount -gt $global:_ESLastErrorCount)

    if (-not $global:_ESIsFirstPrompt -and $global:ErrorSoundEnabled -and ($exitFailed -or $psErrored)) {
        if ($global:_ESPlayer) { try { $global:_ESPlayer.Play() } catch {} }
    }

    $global:_ESLastExitCode   = $LASTEXITCODE
    $global:_ESLastErrorCount = $currentErrorCount
    $global:_ESIsFirstPrompt  = $false

    # ... your existing prompt string here ...
}
```

---

## How it works

The `prompt` function in PowerShell runs automatically after every command. This script hooks into it to check two things:

| Check | Catches |
|---|---|
| `$LASTEXITCODE -ne 0` and changed since last prompt | External program failures — fires once per failure, not on every subsequent cmdlet |
| `$Error.Count` grew | PowerShell cmdlet errors |

The WAV file is loaded into memory at shell startup (`SoundPlayer.Load()`), so playback is instant with no disk read delay.

---

## Changing the sound

The default is `sounds/fahh.wav` (FAHH meme sound). To use something else, either:

Replace the file directly:
```powershell
Copy-Item "C:\path\to\new\sound.wav" "$env:USERPROFILE\.ps-error-sound\fahh.wav"
. $PROFILE
```

Or rerun the installer with a new file:
```powershell
.\install.ps1 -WavPath "C:\path\to\new\sound.wav"
```
