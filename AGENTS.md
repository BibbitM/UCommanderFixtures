# Repository Guidelines

## Project Structure & Module Organization

This Unreal Engine project provides real package and container fixtures for UCommander. It has no C++ source modules or local automated test suite.

- `UCommanderFixtures.uproject` identifies the project and associated engine.
- `Content/Summary/` contains package-summary assets and adjacent `.pkginfo.txt` dumps.
- `Content/OFPAFixture/` contains World Partition fixtures and `EditorEvidence.json`; related actor packages live in `Content/__ExternalActors__/`.
- `Config/` stores project defaults. `.agents/skills/` contains shared agent instructions and tooling.
- `Saved/`, `Intermediate/`, and `DerivedDataCache/` are generated, ignored directories.

## Build, Test, and Development Commands

Run these commands from the repository root.

```powershell
git lfs install
git lfs pull
powershell -NoProfile -File setup-agents.ps1
powershell -NoProfile -File .agents/skills/pkginfo/scripts/Invoke-PkgInfo.ps1 Content/Summary/M_Summary.uasset
```

The first two commands configure Git LFS and fetch binary assets. The setup script links Claude Code skills to `.agents/skills/`. The PkgInfo script resolves the project's engine and writes a dump beside the asset. Use `-EngineDir <engine-root>` if resolution fails.

Open `UCommanderFixtures.uproject` in its associated Unreal Editor to create, save, or cook fixtures. There is no repository build command.

## Coding Style & Naming Conventions

Follow the existing PowerShell conventions for four-space indentation, descriptive function names, and explicit error handling. Keep JSON formatting consistent with each file.

Follow the existing asset naming conventions. Use `BP_` for Blueprints, `M_` for materials, `L_` for levels, and `WP_` for World Partition maps. Let Unreal generate external actor paths. Create binary fixtures through the editor or engine tools.

## Testing Guidelines

Validate changed assets in Unreal Editor and regenerate relevant package dumps. Keep `EditorEvidence.json` consistent with affected actors and package paths. PkgInfo runtime name-table indices can change between runs.

Run consumer tests in UCommander when validating fixture changes against the reader. Record the engine version and validation steps for fixture changes.

## Commit & Pull Request Guidelines

Follow the history's short, imperative commit subjects, such as `Add renamed summary actor fixture`. Keep each change focused on a fixture or tooling concern.

In pull requests, describe the test case enabled, changed assets, engine version, and validation performed. Link related UCommander issues and include editor screenshots when they clarify fixture behavior. Include required external actor packages and updated evidence. Keep binary assets under Git LFS.

## Codex Commit Attribution

Preserve the configured Git author identity. For each commit Codex creates with its own contribution, include the following trailer exactly once.

```text
Co-authored-by: Codex <noreply@openai.com>
```

Skip the trailer for commits created solely by the owner or another agent. Do not rewrite existing commits to add attribution.
