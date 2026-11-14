<#
.SYNOPSIS
    Makes the repo's agent skills visible to every supported coding agent.

.DESCRIPTION
    Skills live in .agents/skills/ (the Agent Skills location read by Codex and other agents).
    Claude Code reads .claude/skills/, so this script links that path to .agents/skills/:
    a directory junction on Windows (no admin rights or Developer Mode needed), a symlink elsewhere.

    The link is local (.claude/skills is git-ignored). Run the script once after cloning, and
    again if the repo folder is moved (a junction stores an absolute path). Safe to re-run.
#>
$ErrorActionPreference = 'Stop'

$root   = $PSScriptRoot
$target = Join-Path $root '.agents\skills'
$link   = Join-Path $root '.claude\skills'

if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "Skills folder not found: $target"
}
New-Item -ItemType Directory -Force -Path (Split-Path $link) | Out-Null

$existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.LinkType) {
        $current = @($existing.Target)[0]
        # Combine keeps $current as-is when it is absolute (junction) and resolves it when relative.
        if ($current -and [IO.Path]::GetFullPath([IO.Path]::Combine((Split-Path $link), $current)).TrimEnd('\', '/') -eq
                          [IO.Path]::GetFullPath($target).TrimEnd('\', '/')) {
            Write-Host "OK: .claude/skills already links to .agents/skills"
            exit 0
        }
        # Delete only the link itself, never the folder it points to.
        [IO.Directory]::Delete($link, $false)
    }
    elseif ($existing.PSIsContainer -and -not (Get-ChildItem -LiteralPath $link -Force)) {
        Remove-Item -LiteralPath $link -Force
    }
    else {
        throw ".claude/skills already exists and is not empty. Move its skills to .agents/skills/, delete it, and re-run."
    }
}

if ($env:OS -eq 'Windows_NT') {
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
} else {
    New-Item -ItemType SymbolicLink -Path $link -Target '../.agents/skills' | Out-Null
}
Write-Host "Linked .claude/skills -> .agents/skills"
