# Eco Integration Roadmap

This roadmap orders work that crosses repository boundaries. It does not replace
the project roadmaps and cannot be used to bypass their release or correctness
gates.

## Operating principles

1. **Contracts before coupling.** Consumers integrate only with documented,
   versioned producer surfaces.
2. **Hosted path first.** Qalam + Takween + Baa must work as one developer
   experience before freestanding integration expands.
3. **Text remains inspectable.** Baa-to-Nazm integration begins with Arabic
   textual assembly and a shadow comparison path.
4. **No silent fallback.** Unsupported compiler, assembler, target, package, or
   manifest behavior must fail visibly.
5. **Deterministic dependency state.** Future packages use a committed lockfile,
   hashes, and no implicit lifecycle scripts.
6. **PyramidOS gates remain authoritative.** No integration milestone may divert
   its v0.9 boot, memory, storage, or VFS stabilization work.
7. **A shell is not a compiler dependency.** ArbSh is the official Arabic shell
   direction, but Baa, Nazm, and Takween remain directly invokable tools.
8. **Share contracts and corpora before runtime libraries.** Qalam, ArbSh,
   Pyramid-Engine, and PyramidOS use different languages and rendering stacks;
   common Arabic behavior begins as versioned data fixtures and acceptance
   tests rather than forced binary coupling.
9. **A receipt names a revision or it proves nothing.** `ecosystem.lock.json`
   records verification as `{ run_url, verified_revision, verified_at }` and
   accepts it only when the revision equals the pin. Where CI has never run
   against the pinned commit the receipt stays `null` and the open work is
   named in `pending_gates`. A local build is never recorded as a receipt.
10. **A pin may be frozen deliberately.** Drift is reported with its direction
   by `scripts/eco-status.ps1` and resolved by a recorded decision — never by
   silently re-pinning to whatever the workspace happens to hold.

## E0 — Contract reconciliation

**Outcome:** every repository agrees on ownership and current compatibility.

- [x] Add Nazm to Baa's ecosystem boundaries and compatibility matrix.
- [x] Replace Takween's Baa 0.4.4.1 baseline with an explicit migration baseline.
- [x] Record which Baa JSON/build contracts are implemented versus planned.
- [x] Define the Baa/Nazm producer-consumer boundary and shadow admission gate.
- [x] Record the PyramidOS i386 versus ecosystem x86-64 strategy decision as an
      explicit post-v0.9 architecture gate.
- [x] Add an umbrella lock snapshot and static consistency check.
- [x] Add one hosted smoke command covering Baa QA, Takween build/run, Qalam
      tooling tests, and optional Nazm verification.

**Gate:** `.\scripts\check-ecosystem.ps1` passes and no canonical ecosystem
document omits a participating project.

## E1 — Takween build-system foundation

**Outcome:** Takween is a tested, cross-platform consumer of current Baa
contracts rather than a Windows command-string wrapper.

- [x] Move the source baseline to Baa 0.6.0 and verify help/version/init/check/build/run/clean.
- [x] Add an automated CLI, clean-safety, build, and run smoke runner; focused
      parser unit separation remains part of the foundation gate.
- [x] Replace `cmd /c` process composition with a structured argv/cwd process
      API supplied by Baa.
- [x] Consume compiler exit codes, diagnostics JSON, and build manifests without
      parsing human output.
- [x] Consume Baa `target-info-v1` discovery instead of assuming a Windows executable.
- [x] Define `takween-manifest-v1`: typed values, sections, targets, profiles,
      dependencies, and workspaces; preserve a documented v0 migration path.

**Gate:** the same sample project builds and runs on Windows and Linux, and a
source error is available as `diagnostics-json-v1` to callers.

**CI receipt (2026-07-13):** Baa build/quick/full passed on Windows and Linux in
[run 29242072003](https://github.com/OmarAglan/Baa/actions/runs/29242072003);
the shared Takween smoke suite passed on `windows-latest` and `ubuntu-latest`
in [run 29251889635](https://github.com/OmarAglan/Takween/actions/runs/29251889635).

## E2 — Qalam hosted workflow

**Outcome:** Qalam provides fast language feedback through Baa and project
workflows through Takween.

- [x] Invoke `baa --check --diagnostics=json` for structured editor diagnostics.
- [x] Validate schema version and render file/span/code/message/hints.
- [x] Discover `مشروع.تكوين` and route build/run/clean/test through Takween.
- [x] Retain direct Baa compile as an explicit single-file fallback.
- [x] Add Qt tests for compiler argument construction, JSON parsing, and Takween
      project discovery/invocation.
- [x] Complete Qalam Workbench Phase A with separate recent projects/files,
      reopen/remove actions, autosaved crash recovery, and an interrupted-session
      restoration test through the real file manager.
- [x] Complete Workbench Phase B with one shared document model, at most two
      horizontal or vertical editor groups, tab drag/move actions, shared
      content/save/undo state, one bottom panel, and persisted/restored tabs,
      active documents, orientation, and splitter sizes.

**Gate:** opening a broken Takween project displays the correct structured Baa
diagnostic; fixing it allows build and run through Takween.

**Workbench receipt (2026-08-27):** Qalam 3.5.0 passed 28/28 local Windows
tests, including the recent-project, crash-recovery, shared-document, disk-save,
two-group, and split-session fixtures. Its isolated Qalam + Baa-LSP payload and
standalone installer built successfully. Baa Developer Kit 0.4.0 records and
packages that exact installer; clean all-users lifecycle and cross-platform CI
remain release gates.

### E2.1 — Baa language-server boundary

**Outcome:** Qalam consumes semantic editor services through a standard,
Baa-only LSP process instead of owning compiler analysis transport.

- [x] Define the Qalam ↔ Baa-LSP ↔ Baa ownership boundary.
- [x] Create the standalone Baa-LSP repository and initial protocol core.
- [x] Implement framing, lifecycle, full document synchronization, and the
      `diagnostics-json-v1` bridge with UTF-8 byte to UTF-16 conversion.
- [x] Connect Qalam's generic LSP client and retire its direct live compiler
      process after diagnostic parity.
- [x] Add compiler-backed symbols, completion, hover, signature help,
      definition, references, rename, code actions, formatting, semantic
      tokens, folding, and selection ranges through versioned Baa contracts.
- [x] Pass real-process, rapid-edit, Arabic-path, active-cancellation, Windows,
      and Linux integration gates with pinned Baa, Nazm, and Takween builds.
- [x] Recover unexpected Baa-LSP exits in Qalam with capped backoff, reopen the
      newest unsaved document versions, and stop after three failed restarts.
- [x] Package Baa-LSP independently and under Qalam's automatic discovery path
      on Windows/Linux; run the independent protocol client against the
      installed server and isolate the combined Windows runtime.
- [x] Add dynamic Takween workspace folders and refresh project context when
      `مشروع.تكوين` or `تكوين.قفل` changes, without parsing either file in Qalam.
- [x] Add compiler-owned parameter-name inlay hints through Baa's versioned
      `inlay-hints-json-v1`, strict Baa-LSP translation, and source-safe Qalam
      overlays without editor-side language inference.
- [x] Add telemetry-free structured server logs through the opt-in
      `baa-lsp-log-v1` contract and a bounded plain-text Qalam consumer.
- [x] Replace old-system `T*` Qalam-owned source/type names with explicit
      `Qalam*` names and enforce the boundary with a source naming test.

**Gate:** an unsaved Baa error travels Qalam → Baa-LSP → Baa and returns as a
version-matched LSP diagnostic on Windows and Linux, with no shadow file and no
compiler-output parsing inside Qalam.

**CI receipt (2026-08-11):** Baa-LSP built its pinned Baa, Nazm, and Takween
revisions and passed all eight protocol suites on `windows-latest` and
`ubuntu-latest` in
[run 31503770097](https://github.com/OmarAglan/Baa-LSP/actions/runs/31503770097).
That run closes the real-process protocol gate; the later receipts below close
client crash recovery and packaging.

**Packaging receipt (2026-08-11):** standalone Baa-LSP archives passed in
[run 31506691139](https://github.com/OmarAglan/Baa-LSP/actions/runs/31506691139),
then combined Qalam + Baa-LSP Windows/Linux artifacts passed in
[run 31506739091](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31506739091).
Crash recovery and packaging are now closed.

**Dynamic workspace receipt (2026-08-11):** Baa-LSP add/reload/remove and
visible failed-refresh coverage passed against real Takween on both hosts in
[run 31509393734](https://github.com/OmarAglan/Baa-LSP/actions/runs/31509393734).
Qalam's Arabic multi-root client fixture and combined Windows/Linux packages
passed in
[run 31509433467](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31509433467).
Structured logs remain production-admission work.

**Structured log admission progress (2026-10-10):** Baa-LSP `a0a39a2` freezes
the 16 `baa-lsp-log-v1` events in an installed catalogue, binds every server
log call site to it, and requires every event sent by the real server with
real Baa and Takween to be a catalogued one; Windows and Linux passed in
[run 38052093589](https://github.com/OmarAglan/Baa-LSP/actions/runs/38052093589).
The Eco full check now requires Qalam's Arabic presenter and the catalogue to
hold the same event set.

**Structured log admission closed (2026-10-10):** the catalogue, the call-site
contract, the real-server runtime check and the Qalam cross-check all passed:
Baa-LSP on Windows and Linux in
[run 38052093589](https://github.com/OmarAglan/Baa-LSP/actions/runs/38052093589),
the full Eco check and the hosted golden path at the pinned combination in
[run 38056873573](https://github.com/OmarAglan/Eco/actions/runs/38056873573).
Baa-LSP `ddb776b` records the admission and passed both hosts in
[run 38056992193](https://github.com/OmarAglan/Baa-LSP/actions/runs/38056992193).
`baa-lsp-log-v1` is admitted for production use; Baa-LSP's open gate is now
incremental document overlays or an in-process Baa frontend API.

**Inlay and self-contained tooling receipt (2026-08-12):** Baa's compiler-owned
contract passed on Windows/Linux in
[run 31588302507](https://github.com/OmarAglan/Baa/actions/runs/31588302507).
Baa-LSP's strict range/cancellation/real-process bridge and standalone packages
passed on both hosts after a transient Windows certificate-download rerun in
[run 31588386653](https://github.com/OmarAglan/Baa-LSP/actions/runs/31588386653).
Qalam's versioned client, source-safe Arabic overlays, and combined
Qalam + Baa-LSP + Baa + Nazm artifacts passed in
[run 31591831751](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31591831751),
including Baa-to-Nazm object generation from an Arabic path in both package jobs.

**Structured log and naming receipt (2026-08-15):** Baa-LSP's opt-in,
telemetry-free `baa-lsp-log-v1` contract passed all Windows/Linux protocol and
package jobs in
[run 31876227451](https://github.com/OmarAglan/Baa-LSP/actions/runs/31876227451).
Qalam's strict local client, bounded plain-text Output presentation, replay
rejection, and combined ecosystem packages passed in
[run 31876292514](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31876292514).
The follow-up migration from old-system `T*` names to explicit `Qalam*` names
passed in
[run 31876657973](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31876657973).
The corrected fail-closed naming guard then passed the same Windows/Linux build
and package gate in
[run 31877079469](https://github.com/OmarAglan/Qalam-IDE/actions/runs/31877079469).

### E2.2 — ArbSh official shell and terminal boundary

**Outcome:** ArbSh becomes Eco's Arabic-first interactive shell, works as a
standalone terminal, and can be selected as Qalam's default shell without
duplicating shell parsing or build semantics inside the IDE.

- [x] Register ArbSh as an independently released ecosystem project with clear
      ownership and an exact workspace revision.
- [x] Establish the .NET 10/C# 14 baseline, unified build metadata, clean
      136-test Windows receipt, vulnerability audit, self-contained Windows
      publish checks, and Windows/Linux CI gates.
- [ ] Freeze `arbsh-host-v1`: version discovery, UTF-8 logical input/output,
      working directory, environment, exit status, cancellation, and explicit
      interactive versus non-interactive modes.
- [x] Add the reusable non-interactive structured-process core using
      argv/cwd/environment, UTF-8 stdin/stdout/stderr, exit/failure
      classification, and cancellation without a shell command string; its ten
      focused tests and all 146 ArbSh tests pass locally on Windows.
- [x] Route unresolved ArbSh commands through that structured process core
      while preserving built-in precedence, session working directory,
      bidirectional line-oriented pipelines, redirection, exit codes, separate
      stdout/stderr, launch failure, and cancellation. Nine focused tests and
      all 155 ArbSh tests pass locally on Windows; dedicated Arabic `تشغيل`
      dispatch for Baa/Takween remains separate below.
- [x] Own launched Windows process trees with a kill-on-close Job Object,
      expose the active ownership mode, fail closed when assignment fails, and
      verify cancellation removes a real descendant. Eleven focused runner
      tests and all 156 ArbSh tests pass locally on Windows at revision
      `e04e99bba7c573317d5f9b06d63102eac6e9842b`.
- [x] Implement Linux launch through util-linux `setsid` with direct argv,
      effective-PATH preflight, session verification, group termination, and
      the same cancellation plus normal-root-exit descendant tests. All 159
      ArbSh tests pass locally on Windows at revision
      `8ef3176ac9dee25135f37998d6cbe390a42ec524`.
- [x] Add typed incremental stdout/stderr streaming while retaining complete
      captured results, consume final pipeline output before the process exits,
      and brand the GUI, executable, and package with an original Arabic icon.
      All 161 ArbSh tests pass locally on Windows at revision
      `e94f7e785c698cfb1b3675da71c7ad3eef9e82fc`.
- [x] Raise the terminal's high-contrast Arabic typography, add bounded
      keyboard/mouse zoom, make `الأوامر` and bare `مساعدة` enumerate the full
      Arabic command catalog, and gate every command/parameter against missing
      Arabic metadata plus smoke execution. All 175 ArbSh tests pass locally on
      Windows at revision `4ee9179bb67468f765f0fc745713f29b27afd340`.
- [x] Obtain the Linux CI receipt for those process-group gates; macOS retains
      the visible transitional .NET tree-kill mode. All 175 ArbSh tests pass on
      both Windows and Ubuntu in
      [run 37796006742](https://github.com/RuqoomTech/ArbSh/actions/runs/37796006742)
      at revision `15b9dbbb6eee4d6bfc4c9e3b739897fe917b2b29`, with Linux
      asserting `setsid` process-group ownership for cancellation and
      normal-root-exit descendant cleanup. The run also fixes the one failing
      Linux test, which marked a file hidden by attribute rather than by the
      POSIX leading dot.
- [x] Polish the standalone terminal with Arabic application chrome and icon,
      a compact live working-directory panel, execution status, shortcut hints,
      larger typography, and focused GUI model tests.
- [ ] Add ConPTY on Windows and PTY on Linux for foreground interactive
      processes, incremental stdin, resize, terminal control flow, and
      background jobs.
- [ ] Make `تشغيل` invoke Baa single-file workflows and Takween projects through
      their public CLIs while preserving their exit codes and diagnostics.
- [ ] Add Qalam shell profiles and host the ArbSh CLI in its bottom terminal
      through PTY/ConPTY. Do not embed the Avalonia window in Qt.
- [ ] Package ArbSh independently; add it to Baa-Developer-Kit only after its
      standalone install/upgrade/repair/uninstall gates pass.
- [ ] Pass Arabic paths, spaces, long paths, multiline input, history,
      completion, cancellation, nested processes, and interactive Baa/Takween
      workflows on Windows and Linux.

**Gate:** the same ArbSh session can build and run a Takween project standalone
and inside Qalam on Windows/Linux, with equivalent output and no surviving
child process after cancellation.

### E2.3 — Shared Arabic interaction corpus

**Outcome:** Arabic text quality improves consistently without forcing C#,
C++, Qt, and freestanding C to share one runtime library.

- [ ] Freeze `eco-arabic-text-corpus-v1` as logical input plus expected cursor,
      selection, grapheme, bidi, shaping, wrapping, clipboard, and path results.
- [ ] Make ArbSh the corpus owner and reference terminal implementation.
- [ ] Consume applicable hosted fixtures in Qalam and Pyramid-Engine.
- [ ] Define an explicitly bounded framebuffer/console subset for PyramidOS
      after its existing Arabic console milestone opens.
- [ ] Label unsupported Unicode/OpenType behavior honestly in each consumer;
      passing a bounded subset must not be described as full conformance.

**Gate:** every consumer reports the same logical behavior for its declared
subset, while renderer-specific pixel output remains independently validated.

## E3 — Nazm shadow and parity integration

**Outcome:** Nazm covers Baa's emitted machine surface and occupies the normal
production assembler position; GAS remains an explicit, never-automatic rollback.

- [x] Inventory instructions, operands, directives, sections, symbols, and
      relocations emitted by the complete Baa Windows/Linux corpus.
- [x] Freeze the non-default shadow admission order and no-silent-fallback
      policy before adding an emitter or executable shadow flag.
- [x] Add Baa's canonical Arabic Nazm emitter, first behind the shadow flag and
      then through the admitted normal assembler path.
- [x] Compare assembly success, object structure, link behavior, runtime results,
      symbols, relocations, and diagnostics in CI.
- [x] Add source mapping for assembler diagnostics.
- [x] Permit no guessed bytes and no silent GAS fallback.

**Gate:** Baa quick/full/stress/release and both target suites pass through the
normal and shadow Nazm paths with an approved parity report, deterministic
artifacts, equivalent observable behavior, and a tested explicit GAS rollback.

**Closure receipt (2026-07-19; current heads reverified 2026-08-23):** the
100-source Windows/Linux corpus, canonical Arabic emitter, object/link/runtime
parity, source maps, deterministic artifacts, no-fallback behavior, and explicit
GAS rollback were approved in Baa admission runs
[29685512987](https://github.com/OmarAglan/Baa/actions/runs/29685512987) and
[29687846586](https://github.com/OmarAglan/Baa/actions/runs/29687846586), with
Takween consumer receipt
[29689709002](https://github.com/OmarAglan/Takween/actions/runs/29689709002).
The currently pinned Baa, Nazm, and Takween heads remain green in
[Baa 32570639621](https://github.com/OmarAglan/Baa/actions/runs/32570639621),
[Nazm 32569904579](https://github.com/OmarAglan/Nazm/actions/runs/32569904579),
and [Takween 32569904685](https://github.com/OmarAglan/Takween/actions/runs/32569904685).
E3 is closed. The in-process `nazm-api-v1` default was a separate admission
decision, recorded in the two steps below.

**Embedded default, step 1 (2026-10-10):** Baa `31a1978` links `nazm-api-v1`
from the pinned Nazm `14c6cf4` into release builds and keeps it opt-in;
`baa --version` names the linked Nazm version, revision and mode. Evidence on
Windows and Linux: integration tests and corpus object-byte parity against the
subprocess on an opt-in and a default build, plus the clean-machine installer
and package gates with no Nazm executable reachable, in
[Baa CI 38058131936](https://github.com/OmarAglan/Baa/actions/runs/38058131936);
the quick/full/stress/release ladder (34/52/82/83) on a default build with no
Nazm executable selected in admission run
[38058138839](https://github.com/OmarAglan/Baa/actions/runs/38058138839); and
the release-candidate ladder on the shipping configuration in
[38058141056](https://github.com/OmarAglan/Baa/actions/runs/38058141056).
No shipped default changed in step 1.

**Embedded default, step 2 (2026-10-10):** approved after the step 1 receipts.
Baa `f73fa4b` builds its release installer and Linux packages with the embedded
Nazm as the default assembler: `baa --version` reports
`Embedded Nazm 0.4.0 (14c6cf4...), default`, an installed compiler needs no
Nazm executable, and the Windows installer no longer asks for one. An explicit
`--nazm-path` or a non-empty `BAA_NAZM` still selects that executable in a
separate process, a missing one is exit 4 and never a fallback, and
`--assembler=gas` stays as the rollback. Evidence on Windows and Linux: the
clean-machine installer and package gates in `default` mode and the
integration tests with corpus object-byte parity in
[Baa CI 38059638256](https://github.com/OmarAglan/Baa/actions/runs/38059638256);
the release-candidate ladder (34/52/82/83) on the strict default build with
`BAA_NAZM` unset and no `نظم` on `PATH` in
[38059645752](https://github.com/OmarAglan/Baa/actions/runs/38059645752); and the
subprocess ladder (34/52/82/83) of the same commit in admission run
[38059648700](https://github.com/OmarAglan/Baa/actions/runs/38059648700).
The standalone `نظم` command keeps shipping as its own tool.

**Allocation-failure injection (2026-10-11):** Nazm `ea03ff1` routes every heap
request through one door and builds its sources a second time with an injector
that can fail any heap request or arena allocation. Its tests fail each of the
830 ELF64 and 823 COFF allocation points behind `nazm-api-v1` across 14
sources, alone and as an exhausted heap, and require
`NAZM_STATUS_OUT_OF_MEMORY`, an empty result, and no live heap block. The
command is failed at every point too, one process each, and must exit 2 with
an Arabic message, no partial object or listing, and an untouched source file.
The sweep found and fixed a diagnostic-string leak in the API, an I/O status
where memory was the cause, and a source/output path guard that answered
"different" when it ran out of memory. Linux CI now runs all of CTest under
ASan and UBSan. Evidence on Windows and Linux:
[Nazm CI 38139822042](https://github.com/OmarAglan/Nazm/actions/runs/38139822042).
Baa `8fc9653`, Takween `e166c84`, Baa-LSP `d3bcf79`, and Kit `de693ba` moved
to that revision the same day: Baa CI 38140413339 and its release-candidate
ladder 38140413886, Takween 38141002459, Baa-LSP 38141005539, and the kit's
per-user and all-users lifecycle 38141542530.

**Lexer and parser fuzzing (2026-10-11):** Nazm `8e80779` adds a seeded fuzz
suite over the injected build. Each run generates 6000 inputs (raw bytes,
vocabulary soup, programs built line by line, and mutations of the 14 shipped
sources), assembles each to ELF64 and COFF, and requires an object or Arabic
diagnostics: no crash, no leak, no internal error, no diagnostic that is not
valid UTF-8, and the same answer when asked twice. One input in four is
assembled again with random allocation points failing. The fuzzing found and
fixed three defects: ill-formed UTF-8 was accepted inside comments and string
literals, a diagnostic that echoed a long name was cut inside a character, and
number literals beyond 64 bits wrapped through signed overflow instead of
being rejected. Twelve further seeds at 20000 inputs per generator, four with
undefined behavior trapped, found nothing more. The suite is a seeded
regression gate, not a coverage-guided campaign. Evidence on Windows and on
Linux under ASan and UBSan:
[Nazm CI 38142058580](https://github.com/OmarAglan/Nazm/actions/runs/38142058580).
Baa `cb687ed` builds with that revision and emits none of the newly rejected
forms (Baa CI 38142164273, release-candidate ladder 38142216525); Takween
`65110fc` (38142190688), Baa-LSP `f74a507` (38142193111), and Kit `c15b4cf`
(38143021354) follow. The published 0.6.0 artifacts still carry Nazm
`14c6cf4`.

**Compatibility policy (2026-10-11):** Nazm `0a3f397` adds
`Docs/COMPATIBILITY.md`. For the C API, the source format, the object file,
the capability document, the command line, and diagnostics it says what is a
break, what is an addition, and what is a fix, and the smallest release that
may carry each before and after 1.0. A break enters with an Arabic migration
diagnostic that names the replacement, never with an alias. Adding a register
name or a `NazmStatus` value is a break; adding an instruction name is not,
because a word before a colon is a label definition and an instruction name
in operand position is a label reference. Diagnostic wording and listing
columns are outside the contract. Tests stand behind the text:
`unit_test_api` pins every status and format value, the size of every public
struct and the offset of every field on a 64-bit host, rebuilds the
fingerprint from its parts, and assembles an instruction name used as a
symbol for ELF64 and COFF; `integration_api_fingerprint_contract` rejects a
CMake version that the header does not carry. Nothing under `src/` or
`include/` changed, so the library Baa embeds is the same code as at
`8e80779`. Evidence on Windows and Linux:
[Nazm CI 38145374602](https://github.com/OmarAglan/Nazm/actions/runs/38145374602).
Baa `394acb1` (CI 38145496435), Takween `10cffc9` (38145945086), Baa-LSP
`e07fbb4` (38145948459), and Kit `4f3a67f` (38146197202) follow; Baa's release-candidate
ladder was not rerun for a documentation-and-tests revision and last passed
in 38142216525 at `cb687ed`. One gap is recorded rather than closed: the
fingerprint names a release, not a revision, so every revision between 0.4.0
and the next release reports the 0.4.0 fingerprint, and a consumer of an
untagged revision must add the revision to its cache identity. Baa's cache
key does not do that today.

**1.0 readiness review (2026-10-11):** Nazm `e405681` adds
`Docs/READINESS.md`, the list of conditions for Nazm 1.0 across instructions,
outputs, tests, documentation, and the release. The criterion is the
compatibility policy: a condition is anything whose later correction would be
a break. The list rests on measurement rather than on roadmap ticks. The
instruction, register, and directive names were cross-checked between the
keyword table, the capability document, and the terminology reference. Merged
line coverage of the library was 92.7% before the review and 93.2% after its
tests. A new test, `differential_register_matrix_gas`, generates 116,442
statements that put every register in every operand position of every
implemented form, assembles them through the real command line, and compares
the disassembly with GNU as; it runs on Windows and on Linux under Release
and under ASan and UBSan. It found no wrong byte: 363 statements differ in
bytes only, where GNU as writes the short accumulator-immediate form and Nazm
the general one. Of 28 conditions, 10 are met, 13 are open, and 5 are owner
decisions: whether to declare the 16-bit widening forms the encoder already
accepts, whether to freeze the 80 register names or reserve their prefixes,
whether to keep or tighten the literal pattern rule, how an untagged revision
is identified in the fingerprint, and whether 1.0 ships signed. The open
conditions include an executed test of the 64-bit absolute relocation path, a
differential for symbolic forms, the multi-file DWARF paths, COFF link-and-run
and coverage in Nazm's own CI, and a Linux archive with a clean-machine
receipt. The revision changes documentation and tests only; nothing under
`src/` or `include/` changed, so the library Baa embeds is the same code as
at `8e80779`. Evidence on Windows and Linux:
[Nazm CI 38152050738](https://github.com/OmarAglan/Nazm/actions/runs/38152050738).
Baa `b0d112c` (CI 38152306495), Takween `1b73a6c` (38152891667), Baa-LSP
`34349af` (38152894658), and Kit `f43acca` (38153184683) follow; Baa's release-candidate
ladder was again not rerun and last passed in 38142216525 at `cb687ed`.
Nazm's next gates were the owner decisions and the open conditions in
`Docs/READINESS.md`.

**1.0 conditions closed (2026-10-13):** Nazm `4a4da86` takes the five owner
decisions and closes the thirteen open conditions; `Docs/READINESS.md` has no
row left open. The decisions: declare the 16-bit widening forms; reserve the
prefixes `سجل_`, `مؤشر_` and `فهرس_` for register names instead of freezing
the 80 names; keep the literal pattern rule and test it; keep the fingerprint
a release identity and make consumers of an untagged revision add the
revision; ship 1.0 unsigned. Unlike the two revisions before it, this one
changes library source. Two faults were found by the new tests and fixed: a
jump or call whose target was neither a label nor a 64-bit register was
encoded with a zero displacement and is now rejected, and `.محاذاة` did not
raise the section alignment recorded in the object. New gates: a differential
that links the symbolic forms through GNU `ld` and compares the linked bytes
with GNU as, link-and-run for COFF and ELF, a `readelf` check of a two-file
line table, a libFuzzer target with its own CI job, line coverage of `src/`
in CI with a 90% floor (95.4% measured on Windows), a Linux archive checked
in a container with no compiler, and a UTF-8 check of tracked text. Nazm runs
34 CTest tests and 483 Unity tests on Windows. Evidence on Windows, Linux and
the fuzz job:
[Nazm CI 38382405665](https://github.com/OmarAglan/Nazm/actions/runs/38382405665).
Baa `f400dc8` (CI 38383101702) escapes user names that start with a reserved
prefix as `رمز_باء_<name>` and adds the embedded Nazm revision to its object
cache slot, which closes the gap recorded on 2026-10-11; because Nazm source
changed, its release-candidate ladder was rerun and passed in 38383102240.
Takween `00d5514` (38383127452), Baa-LSP `7ec7686` (38383133388), and Kit
`c0e013a` (38384310500) follow. The Nazm version is still 0.4.0. Its next
gate is cutting 0.5.0, which carries the breaking changes, and building the
three consumers on it before 1.0.

## E4 — Local packages before a public registry

**Outcome:** package semantics are proven without prematurely operating a
public service.

- [x] Add local/transitive path dependencies to typed manifests and compiler plans.
- [x] Add pinned Git dependencies with structured Git argv, exact commits, and
      offline reuse of a commit-addressed checkout.
- [x] Define and implement deterministic SemVer selection plus immutable
      SHA-256 archive identity for an explicit local package index.
- [x] Finish the deterministic local archive format, bounded safe extraction,
      vendoring, explicit offline verification, and Baa/target constraints.
- [ ] Define registry namespaces and an explicit Unicode NFC identity migration;
      do not change the byte-exact v1 identity contract silently.
- [x] Generate deterministic `takween-lock-v1` state for exact transitive path/Git
      nodes, sources, parent edges, selected Baa target, and Git commits.
- [x] Add local-index archive resolution with exact SemVer selections and
      immutable archive hashes to the lock contract; network registry access is
      explicitly absent.
- [x] Add an externally populated content-addressed cache foundation and prove
      locked rebuild/run offline.
- [x] Keep `baalib` bundled with the SDK.
- [ ] Publish higher-level official libraries as ordinary versioned packages.
- [x] Forbid implicit install/build lifecycle scripts in the first package format.

### E4.1 — GCC-like SDKs and transactional tool environments

**Outcome:** compiler distribution, globally installed tools, and locked project
dependencies are separate layers with no implicit cross-layer writes.

**Distribution decision:** do not reproduce MSYS2 as an operating-system package
manager. Ship Baa as an immutable, GCC-style SDK/sysroot; borrow MSYS2's useful
transaction, file-ownership, and named-environment ideas only for installing SDKs
and developer tools. Takween remains the npm-like owner of project libraries,
but resolves them from the manifest and committed lockfile instead of a mutable
global package tree. The first release works from local/signed archives; a public
registry remains a later E4.2 service.

- [ ] Define an immutable, versioned Baa SDK layout containing Baa, Nazm,
      `baalib`, headers, runtimes, and target files, with structured discovery
      comparable to a compiler sysroot rather than hard-coded physical paths.
- [ ] Freeze a `baa-sdk-v1` archive/metadata contract and make Takween install,
      verify, discover, select, and remove SDKs atomically without executing
      package-provided scripts.
- [ ] Allow multiple Baa SDK versions and targets to coexist and let Takween pin
      the selected SDK identity in project plans and locks.
- [ ] Add a content-addressed tool store and named environments for user-installed
      command-line tools on Windows and Linux.
- [ ] Add a transactional installed-package database with file ownership,
      preflight conflict detection, atomic commit/rollback, and safe removal.
- [ ] Keep third-party project dependencies out of SDK and tool prefixes; they
      remain manifest/lock-driven even when a matching tool package is installed.
- [ ] Expose Arabic-first environment/install/remove/list/owner commands and
      structured events for Qalam without implicit lifecycle scripts.

**Gate:** two Baa SDK versions coexist, a tool can be installed and removed from
a named environment transactionally, and two differently locked projects build
reproducibly without depending on the active global environment.

### E4.2 — Signed remote registry and publishing

- [ ] Add signed immutable repository snapshots, namespace ownership, key
      rotation/revocation, license/target/Baa metadata, and a safe yank policy.
- [ ] Add a compact compressed transport envelope while preserving the current
      deterministic file-list, hash, and bounded-extraction semantics.
- [ ] Add Arabic-first search/add/remove/update and publish workflows; reserve
      install for SDK/tool environments so project state remains lock-owned.
- [ ] Open a public service only after SDK/conformance and cross-platform
      transaction/security gates pass.

**Gate:** a multi-package workspace resolves and rebuilds reproducibly offline.
A public registry remains deferred until the Baa SDK/conformance gates allow it.

### E4.3 — Coordinated developer-kit distribution

**Outcome:** Baa-Developer-Kit is the release orchestrator for admitted tools,
not a second owner of their installed files.

- [x] Freeze `eco-installer-manifest-v1` for component identity, hashes,
      ordering, health checks, and Qalam-owned Baa-LSP recording.
- [x] Prove current-user install, real upgrade, repair, health checks, and clean
      uninstall locally for the 0.2.0 kit.
- [x] Pass the all-users `Program Files` lifecycle on a clean Windows worker.
      Kit `4d3e756`, CI run 37769971047 (2026-10-08): isolated per-user and
      all-users machine-PATH install, repair, runtime, and uninstall on a
      fresh `windows-latest` runner.
      Rebuilt at Nazm `14c6cf4`, Baa `246ed36`, Takween
      `1f25f86`, Baa-LSP `d2eabdc`, Qalam `f682bd9`: Kit `639404c`, CI run
      38051624676 (2026-10-10), same per-user and all-users lifecycle.
      Rebuilt with the embedded Nazm default at Nazm `14c6cf4`, Baa
      `8606d37`, Takween `e5c3d04`, Baa-LSP `5e3d5c9`, Qalam `f682bd9`: Kit
      `96b4ddd`, CI run 38062166442 (2026-10-10), same lifecycle; the installed Baa
      reports the embedded default and builds a program with no Nazm on PATH.
      Takween and Baa-LSP changed only their CI pin to that Baa.
      Rebuilt at Nazm `ea03ff1`, Baa `8fc9653`, Takween `e166c84`, Baa-LSP
      `d3bcf79`, Qalam `f682bd9`: Kit `de693ba`, CI run 38141542530
      (2026-10-11), same lifecycle. Rebuilt at Nazm `8e80779`, Baa `cb687ed`,
      Takween `65110fc`, Baa-LSP `f74a507`, Qalam `f682bd9`: Kit `c15b4cf`, CI
      run 38143021354 (2026-10-11), same lifecycle. Rebuilt at Nazm `0a3f397`,
      Baa `394acb1`, Takween `10cffc9`, Baa-LSP `e07fbb4`, Qalam `f682bd9`: Kit
      `4f3a67f`, CI run 38146197202 (2026-10-11), same lifecycle. Rebuilt at
      Nazm `e405681`, Baa `b0d112c`, Takween `1b73a6c`, Baa-LSP `34349af`, Qalam
      `f682bd9`: Kit `f43acca`, CI run 38153184683 (2026-10-11), same lifecycle.
      Rebuilt at Nazm `4a4da86`, Baa `f400dc8`, Takween `00d5514`, Baa-LSP
      `7ec7686`, Qalam `f682bd9`: Kit `c0e013a`, CI run 38384310500
      (2026-10-13), same lifecycle.
- [x] Prove Baa's own release artifacts on clean machines. Baa `b5f4383`
      (2026-10-10): the release-candidate ladder passed quick 34/34, full
      52/52, stress 82/82, and release 83/83 on Windows and Linux in run
      38045945587; the Windows installer on a fresh runner and the `.deb` and
      `.tar.gz` in a fresh `ubuntu:24.04` container without a C toolchain
      passed install, compile, run, and removal in run 38045707261. The Linux
      gate found and fixed an installed compiler that could not find its
      standard library and a `.deb` that did not declare its linker.
- [x] Give Nazm-assembled Linux objects a non-executable stack marking. Nazm
      `14c6cf4` (2026-10-10) ends every ELF64 object with an empty
      `.note.GNU-stack`; its CI links with `ld --fatal-warnings` and requires
      an `RW` `GNU_STACK` segment (run 38049146917). Baa `388b539` builds with
      that revision, and its clean-container gate fails on the linker warning
      for the Nazm and GAS paths (run 38049326563); the release-candidate
      ladder passed again on both hosts in run 38049343387.
- [x] Publish Baa 0.6.0 and Nazm 0.4.0 (2026-10-10), unsigned by decision.
      Baa tag `v0.6.0` and branch `release/v0.6.0` name the documentation-only
      release commit `4438abe`; the published installer, `.deb`, and `.tar.gz`
      with their SHA-256 files are the artifacts of Baa CI run 38065099777 on
      it. Nazm tag `v0.4.0` names `14c6cf4`, the exact source embedded in that
      Baa, with the installer of CI run 38049146917. At publication Takween,
      Baa-LSP, and the kit built against Baa `8606d37`, which differs from the
      tag only in documentation; they have since moved past the tag with the
      Nazm revisions recorded under E3. The kit itself is not published.
- [ ] Sign every public installer and the kit with a valid Authenticode chain.
- [ ] Add ArbSh as an independently owned component only after E2.2's
      standalone installer gate passes.
- [ ] Keep Pyramid-Engine and PyramidOS as optional, separately released
      workloads rather than inflating the default language developer kit.

**Gate:** a clean machine installs, upgrades, repairs, verifies, and removes the
admitted toolset without PATH collisions, orphaned files, or hidden developer
tool dependencies.

**Foundation receipt (updated 2026-08-01):** Takween resolves the highest matching
SemVer from `takween-index-v1`, verifies the selected local archive with Baa's
portable SHA-256 primitive, safely extracts into a digest-addressed cache,
records the exact choice in `takween-lock-v1`, vendors deterministically, and
supports explicit offline verification. Multi-package workspaces are implemented;
the next gates are the separated SDK/tool environment and signed-registry tracks.

## E5 — PyramidOS mixed-build experiment

**Entry condition:** PyramidOS v0.9 gates pass and the architecture target
decision is documented.

- [ ] Freeze entrypoint, calling convention, object format, sections, relocation,
      and forbidden runtime behavior.
- [ ] Either support i386/ELF32 coherently across Baa/Nazm/Takween or adopt a
      staged PyramidOS x86-64 migration; do not create an unowned hybrid target.
- [ ] Link one pure, non-driver Baa module into the existing C/assembly kernel.
- [ ] Build the image through a Takween OS profile and boot in QEMU.
- [ ] Prove the final kernel has no hidden CRT/libc dependency.

**Gate:** one non-trivial mixed module boots and passes `diagnose` without
weakening PyramidOS's native build or rollback path.

## E6 — Pyramid-Engine Baa scripting experiment

**Entry condition:** Pyramid-Engine reaches its verified Windows vertical slice
and Baa freezes the hosted embedding prerequisites. C++ remains the behavioral
reference until parity is demonstrated.

- [x] Register Pyramid-Engine as an ecosystem runtime consumer without adding
      it to the hosted compiler/build dependency chain.
- [ ] Freeze a narrow hosted ABI/FFI for calling Baa functions from C++ and
      calling an approved engine API from Baa.
- [ ] Define Baa runtime ownership, allocation, strings, errors, threads,
      module loading, debugger hooks, and hot-reload state migration.
- [ ] Compile one gameplay-only Baa module and load it from an existing C++
      example; do not begin with graphics, platform, or engine-core rewrites.
- [ ] Add deterministic reload, crash containment, version mismatch, and
      Windows packaging tests.
- [ ] Let Qalam edit and debug the Baa gameplay module through Baa-LSP; the
      future Pyramid editor continues to own scene/asset authoring UI.
- [ ] Consider Takween orchestration only after it can represent the mixed
      CMake/native+Baa graph without replacing Pyramid-Engine's validated CMake
      build prematurely.

**Gate:** one gameplay module can be built, loaded, debugged, reloaded, and
rolled back without destabilizing the native reference application.

## Definition of ecosystem readiness

The core hosted toolchain is ready for a coordinated release only when E0–E3
are closed, the hosted golden path has a repeatable CI receipt, and the pinned
versions in `ecosystem.lock.json` match tested release artifacts. ArbSh joins a
default developer-kit release only after E2.2 and its installer gate pass.
Pyramid-Engine and PyramidOS may remain explicit preview consumer tracks; they
must not block or weaken the hosted language tools.
