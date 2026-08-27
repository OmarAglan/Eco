# Eco — Arabic-First Systems Development Ecosystem

Eco is the integration workspace for nine independently released projects:

| Project | Role | Current workspace baseline |
|---|---|---:|
| [Baa](https://github.com/OmarAglan/Baa) | Arabic-first systems language, reference compiler, standard library, and tooling contracts | 0.6.0 |
| [Nazm](https://github.com/OmarAglan/Nazm) | Arabic-first x86-64 assembler and ELF64/COFF object writer | 0.4.0 |
| [Takween](https://github.com/OmarAglan/Takween) | Project build, run, test, dependency, and package workflow | 0.1.0 |
| [Qalam-IDE](https://github.com/OmarAglan/Qalam-IDE) | RTL-first editor and graphical tooling client | 3.5.0 |
| [Baa-LSP](https://github.com/OmarAglan/Baa-LSP) | Baa-only Language Server Protocol adapter between editors and the reference compiler | 0.1.0 preview |
| [ArbSh](https://github.com/RuqoomTech/ArbSh) | Arabic-first shell and standalone terminal host | 0.8.1-alpha |
| [Baa-Developer-Kit](https://github.com/OmarAglan/Baa-Developer-Kit) | Offline installer orchestration and release manifest owner | 0.4.0 |
| [Pyramid-Engine](https://github.com/RuqoomTech/Pyramid-Engine) | Arabic-capable native runtime and future Baa scripting consumer | 0.6.0-pre-alpha |
| [PyramidOS](https://github.com/RuqoomTech/PyramidOS) | Experimental freestanding consumer and long-term systems testbed | 0.8.1 baseline |

The projects remain separate repositories. This directory owns only their shared
compatibility snapshot, integration roadmap, and cross-project verification.

## Intended hosted workflow

```text
                         Baa-Developer-Kit
                                  |
              installs versioned, independently owned tools
                                  v
ArbSh shell --------> Takween --------> Baa --------> Nazm
    ^                     ^               ^              |
    |                     |               |              +--> objects
    |                     |               +--> compiler contracts
    |                     +--> build/run/test/package workflows
    |
Qalam terminal panel     Qalam-IDE ----> Baa-LSP ----> Baa tooling contracts
```

ArbSh is the official Arabic shell direction, but no compiler or build tool
requires it in order to run. Qalam will host the ArbSh CLI through a real
PTY/ConPTY terminal session rather than embedding ArbSh's Avalonia window or
duplicating its shell parser.

Pyramid-Engine and PyramidOS are ecosystem consumers, not dependencies of the
hosted toolchain. Pyramid-Engine keeps CMake and its C++ reference runtime until
Baa has explicit hosted embedding, FFI, debugger, and hot-reload contracts.
PyramidOS remains outside the hosted critical path until its v0.9 boot, memory,
storage, and VFS gates pass. Its first integration is a tiny mixed C/Baa object
experiment, not a kernel rewrite and not a .NET/Avalonia port of ArbSh.

## Architecture layers

| Layer | Projects | Ownership rule |
|---|---|---|
| Language tools | Baa, Nazm, Takween | Own compilation, assembly, builds, dependencies, and packages through versioned contracts. |
| Developer experience | Qalam-IDE, Baa-LSP, ArbSh | Present editing, language intelligence, shell, and terminal UX without reimplementing compiler/build semantics. |
| Distribution | Baa-Developer-Kit | Verifies and orchestrates independently owned installers; it does not absorb their files or uninstall ownership. |
| Runtime consumers | Pyramid-Engine, PyramidOS | Consume admitted hosted or freestanding contracts behind their own readiness gates. |

## Sources of truth

- [`ecosystem.lock.json`](ecosystem.lock.json) pins the versions and contract
  states represented by this workspace.
- [`ECOSYSTEM_ROADMAP.md`](ECOSYSTEM_ROADMAP.md) defines cross-project ordering
  and acceptance gates. Project roadmaps remain authoritative for local work.
- Each project's own public contract remains authoritative for behavior it owns.
  The umbrella files may narrow integration admission, but must not redefine a
  compiler, assembler, IDE, build-system, or kernel contract.

## Check the workspace

From PowerShell:

```powershell
.\scripts\check-ecosystem.ps1
```

The check validates repository presence, exact pinned revisions, versions,
required contract documents, ownership references, and the current integration
boundary. It does not replace project builds or tests.

After building Baa, Qalam with `QALAM_BUILD_TESTS=ON`, Baa-LSP, and optionally
Nazm, run
the hosted integration receipt:

```powershell
.\scripts\test-hosted-ecosystem.ps1 `
  -BaaPath .\Baa\build\eco-verify\baa.exe `
  -QalamBuildDir .\Qalam-IDE\build\eco-tests `
  -BaaLspBuildDir .\Baa-LSP\build\eco-tests `
  -NazmPath .\Nazm\build\eco-verify\نظم.exe `
  -NazmBuildDir .\Nazm\build\eco-verify `
  -RuntimeBin C:\msys64\ucrt64\bin,C:\Qt\6.10.2\mingw_64\bin,C:\Qt\Tools\mingw1310_64\bin
```

This runs the contract check, Baa quick QA, Takween's real init/build/run/clean,
path/Git/local-archive, SemVer, SHA-256, and locked/offline smoke workflows,
Qalam's focused tooling tests, Baa-LSP's protocol suite and real compiler symbol
bridge, and the Nazm suite when supplied.

## Release rule

An ecosystem combination is supported only when:

1. `ecosystem.lock.json` pins every participating project and contract state;
2. each producer's contract tests pass;
3. each consumer has an integration test for the contract it consumes; and
4. the golden hosted workflow passes without parsing human-readable compiler
   or assembler output where a machine-readable format exists.
