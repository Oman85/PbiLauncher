# PBI Launcher

Shows a Power BI report full screen on a kiosk, signs in to it, and keeps it there (it replaces `PowerBILauncher.exe`).

It runs on the kiosk as the logged-on kiosk account, from `C:\Users\Public\Documents\PbiLauncher\`, one instance per screen (`-Instance S1`, `S2`, ...). Everything it reads and writes - configs, status, logs, control files - is in that folder.

| | |
|---|---|
| `PbiLauncher/PbiLauncher.ps1` | The launcher. [Web Launcher](https://github.com/Oman85/WebLauncher) is generated from it. |
| `PbiLauncher/EXAMPLE.json` | A screen's config, to copy to `S<n>\<COMPUTERNAME>.json`. |
| `PbiLauncher/Start-PbiLauncher.cmd` | Starts it by hand. |
| `Tests/Test-PbiLauncher.ps1` | End-to-end runs against `Tests/FixtureServer.ps1` with a headless Edge (Windows). |
| `Tests/Test-RestartRequest.ps1` | How `restart.txt` is read. Runs on any PowerShell. |
| `Docs/PowerBI-Launcher.md` | The full manual: settings, states, recovery, troubleshooting. |

## Installing

Copy the `PbiLauncher` folder to `C:\Users\Public\Documents\` on the kiosk, write the screen's config (`PbiLauncher\S1\<COMPUTERNAME>.json`, from `EXAMPLE.json`), and start it at logon with a shortcut in the kiosk account's Startup folder:

```
C:\Windows\System32\conhost.exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\Public\Documents\PbiLauncher\PbiLauncher.ps1" -Instance S1
```

`PbiLauncher\Start-PbiLauncher.cmd` starts it by hand.

## Control files

Dropped into a screen's folder (`C:\Users\Public\Documents\PbiLauncher\S<n>\`). The launcher acts on each within seconds and deletes it, except `hold.txt`.

| File | What it does |
|---|---|
| `kill.txt` | Stop the launcher and close Edge. |
| `relaunch.txt` | Restart Edge. |
| `refresh.txt` | Reload the page. |
| `restart.txt` | Restart the PC. Empty or plain text: after 10 s. As JSON, `{"Seconds": 60, "Message": "Back in a minute", "By": "alice"}`: after that countdown (0 to 3600 s), with the message in Windows' restart notice. |
| `snapshot.txt` | Save a screenshot and a page summary in `Status\`. |
| `hold.txt` | Pause until it is deleted. |
| `password.seed` | The sign-in password, on one line; the launcher encrypts it for the kiosk account and deletes it. |

[Kiosk Fleet Web](https://github.com/Oman85/kiosk-fleet-web) writes these through each kiosk's Public Documents share: **Reload**, **Restart browser**, **Hold**, **Stop**, **Screenshot**, and **Restart...**, which writes `restart.txt` with its countdown and message. It needs nothing else on the kiosk: no admin share, no WMI or CIM.

## Tests

```powershell
.\Tests\Test-RestartRequest.ps1       # anywhere, seconds
```

The end-to-end tests need Windows and Edge; see the table above.

## History

Split out of [vigilant-fishstick](https://github.com/Oman85/vigilant-fishstick) with its history. The fleet tools stayed there: the PowerShell collector and manager, `Deploy-*.ps1` (which install over the admin share) and `Get-*Status.ps1`. Where the manual mentions them, they are in that repository.
