# UCommanderFixtures

Unreal Engine project with test assets (fixtures) for
[UCommander](https://github.com/BibbitM/UCommander).

Source code: https://github.com/BibbitM/UCommanderFixtures

## Purpose

This project supplies the test files for UCommander. The tests need real
Unreal Engine files: packages (`.uasset`, `.umap`) and containers (`.pak`,
`.utoc`/`.ucas`). Each asset is made by hand in the editor and saved or
cooked by the engine, so the tests read the same data as in real projects.

## Setup

### Agent skills

Skills for coding agents live in [`.agents/skills/`](.agents/skills). Codex
and other agents that follow the [Agent Skills](https://agentskills.io)
standard read them from there. Claude Code reads `.claude/skills/` instead, so
after cloning run once:

```powershell
powershell -NoProfile -File setup-agents.ps1
```

The script links `.claude/skills` to `.agents/skills` (a directory junction on
Windows, so no admin rights or Developer Mode are needed). The link is local
and ignored by Git. Run the script again if you move the repository folder.

To add a skill, create a folder with a `SKILL.md` in `.agents/skills/`. Both
agents see it without further setup.

## License

Copyright BIBBIT Michal Nowak.

UCommanderFixtures is licensed under either of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- MIT License ([LICENSE-MIT](LICENSE-MIT))

at your option.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.

## Trademarks

Unreal and Unreal Engine are trademarks or registered trademarks of Epic
Games, Inc. UCommanderFixtures is not affiliated with or endorsed by Epic
Games, Inc.
