---
name: pkginfo
description: Generate Unreal Engine PkgInfo dumps (`<AssetName>.pkginfo.txt` saved next to the asset) for given .uasset/.umap files by running the PkgInfo commandlet with the project's engine. Use whenever the user asks for a PkgInfo dump, "zrzut PkgInfo", package summary/info, `.pkginfo.txt` files, or wants to (re)generate or refresh package dumps for fixture assets — even if they only list asset names without mentioning the commandlet.
---

# PkgInfo dumps

Run the bundled script from the repo root; it does everything (finds the `.uproject`, resolves
the engine from `EngineAssociation`, runs the commandlet once per asset, verifies the output):

```
powershell -NoProfile -File .agents/skills/pkginfo/scripts/Invoke-PkgInfo.ps1 <asset1> <asset2> ...
```

- Assets are `.uasset` / `.umap` paths, absolute or relative to the repo root. If the user gives
  bare names (e.g. `M_Summary`), first find `M_Summary.uasset` / `M_Summary.umap` under `Content/`.
- Output: `<AssetName>.pkginfo.txt` in the asset's folder, overwritten if present.
- Default switches are `-all` (summary, name map, imports, exports, ...). Only if the user asks
  for a narrower dump, call the script from PowerShell with other PkgInfo switches:
  `& .agents/skills/pkginfo/scripts/Invoke-PkgInfo.ps1 <asset> -ExtraArgs @('-names','-imports')`.
- Overrides: `-Project <path.uproject>`, `-EngineDir <engine root>` when auto-detection fails.
- Each run takes ~30–60 s (editor startup), so allow a long command timeout (several minutes)
  when dumping more than one asset.
- Exit code 1 means at least one asset failed; the `FAIL` line names its log
  (`%TEMP%\pkginfo-logs\<AssetName>.log`) — read it before reporting.

## How it works (for troubleshooting)

The script calls, per asset:

```
<Engine>\Engine\Binaries\Win64\UnrealEditor-Cmd.exe <Project>.uproject -run=PkgInfo <asset> -all
    -dumptofile=<dir>\<AssetName>.pkginfo.txt -unattended -nop4 -nosplash -nullrhi -abslog=<log>
```

`-dumptofile` gives clean text without log prefixes; one run per asset because a single
`-dumptofile` with several packages would merge them into one file. Engine resolution order:
`HKCU:\Software\Epic Games\Unreal Engine\Builds` (GUID or version key) →
`HKLM:\SOFTWARE\EpicGames\Unreal Engine\<ver>\InstalledDirectory` → `C:\Program Files\Epic Games\UE_<ver>`.

## Things worth telling the user

- **Regenerating is not byte-identical.** Name Map lines contain `Comparison Index` /
  `Display Index`, which are runtime FName table indices and change on every run. If the asset
  did not change, a diff against the committed dump should touch only those lines — check with
  ```powershell
  git diff --unified=0 -- <dump> | Where-Object { $_ -match '^[+-]\s' -and $_ -notmatch 'Comparison Index' }
  ```
  (no output = only index noise). Mention this when the user regenerates committed dumps.
- The header shows the package as `/Temp/<Folder>/<Asset>` rather than `/Game/...`, because
  PkgInfo is given a file path; the real `/Game/...` name still appears in the Name Map.
- `ZenShared: Unable to reach ZenServer` lines in the log are harmless (shared DDC offline).
- The dump files are left uncommitted — committing is the user's call.
