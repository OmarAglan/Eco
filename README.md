# Eco — Arabic-First Systems Development Ecosystem

Eco is the integration workspace for nine independently released projects:

| Project | Role | Current workspace baseline |
|---|---|---:|
| [Baa](https://github.com/OmarAglan/Baa) | Arabic-first systems language, reference compiler, standard library, and tooling contracts | 0.6.0 |
| [Nazm](https://github.com/OmarAglan/Nazm) | Arabic-first x86-64 assembler and ELF64/COFF object writer | 0.4.0 |
| [Takween](https://github.com/OmarAglan/Takween) | Project build, run, test, dependency, and package workflow | 0.1.0 |
| [Qalam-IDE](https://github.com/OmarAglan/Qalam-IDE) | RTL-first editor and graphical tooling client | 3.7.0 |
| [Baa-LSP](https://github.com/OmarAglan/Baa-LSP) | Baa-only Language Server Protocol adapter between editors and the reference compiler | 0.1.0 preview |
| [ArbSh](https://github.com/RuqoomTech/ArbSh) | Arabic-first shell and standalone terminal host | 0.8.1-alpha |
| [Baa-Developer-Kit](https://github.com/OmarAglan/Baa-Developer-Kit) | Offline installer orchestration and release manifest owner | 0.6.0 candidate |
| [Pyramid-Engine](https://github.com/RuqoomTech/Pyramid-Engine) | Arabic-capable native runtime and future Baa scripting consumer | 0.6.0-pre-alpha |
| [PyramidOS](https://github.com/RuqoomTech/PyramidOS) | Experimental freestanding consumer and long-term systems testbed | 0.8.1 baseline |

The projects remain separate repositories. This directory owns only their shared
compatibility snapshot, integration roadmap, and cross-project verification.

The 0.6.0 kit candidate packages Qalam 3.7.0 and builds every component
installer from the revisions this lock pins, each with a green Windows and
Linux CI run. Its [verification record](https://github.com/OmarAglan/Baa-Developer-Kit/blob/main/docs/VERIFICATION_STATUS.md)
lists those runs and separates them from what remains: Qalam's Linux
installer and manual visual review, and Authenticode signing. The pinned source
revisions do not by themselves establish release readiness.

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
.\scripts\check-ecosystem.ps1            # full gate; needs the nine repositories present
.\scripts\check-ecosystem.ps1 -LockOnly  # lock and umbrella documents only
.\scripts\eco-status.ps1                 # local drift: pin vs HEAD, dirty trees, receipts
.\scripts\check-pinned-revisions.ps1     # does each pin really exist upstream?
.\scripts\materialize-workspace.ps1      # build a clean workspace from the pins alone
```

The check validates repository presence, exact pinned revisions, versions,
required contract documents, ownership references, milestone states, and the
current integration boundary. It does not replace project builds or tests. In
`-LockOnly` mode the member-repository assertions are reported as **skipped**:
an absent repository is unverified, never a pass.

`.github/workflows/ecosystem-consistency.yml` runs the lock-only gate and the
upstream pin check on every push and pull request. The full check against a
materialized workspace is manual (`workflow_dispatch`) because it clones all
nine pinned revisions and needs `ECOSYSTEM_PAT` to reach private repositories.

### What the lock stores

- `revision` — the exact commit this combination was verified at.
- `repository` — the `owner/name` repository the pin belongs to.
- `milestones` — the E0–E6 states. A milestone may be `closed` only while its
  roadmap section holds no unchecked work items.
- `verification.receipt` — `null`, or `{ run_url, verified_revision, verified_at }`.
  A receipt counts only when `verified_revision` equals the pin, so an old green
  run can never certify a revision that has since moved.
- `pending_gates` — what remains unproven for that pin. A component without a
  receipt must name at least one pending gate.
- `pin_policy` — absent, or `"frozen"`. A frozen pin must carry a `pin_note`
  saying why it is held back.

### Drift is a decision, not an error to erase

`eco-status.ps1` separates a straight-line advance from a real divergence. A pin
can be frozen on purpose: Qalam is pinned at the 3.7.0 revision the Baa
Developer Kit `0.6.0` candidate packages, so a workspace ahead of it is expected. Its
`pin_policy` is `"frozen"` and its `pin_note` records why.

`check-ecosystem.ps1` fails on every other drift until someone re-pins. For a
frozen pin it accepts only a straight-line advance and prints it as accepted
drift; a divergence or an unreachable pin still fails. Its member-file
assertions then read the workspace tree, not the frozen revision; the
materialized-workspace CI job checks the pins themselves. The distance between
"these trees happen to be checked out" and "this combination was verified" is
the whole purpose of this file.

The kit's CI checks out the same Baa, Nazm, Takween, Qalam, and Baa-LSP
revisions this lock pins and builds their installers from them, so the kit's
receipt and the component receipts describe one combination.

After building Baa, Nazm, Qalam with `QALAM_BUILD_TESTS=ON`, and Baa-LSP, run
the hosted integration receipt. Nazm is required: it is Baa's production
assembler. The `hosted-golden-path` CI job runs the same script on Linux against
a fresh build of exactly the pinned revisions.

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
