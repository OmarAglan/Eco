# Deferred Ecosystem Goal After the Qalam IDE Milestone

**Status:** Deferred — محفوظ للمستقبل، وليس هدف العمل الحالي

**Priority gate:** Resume only after Qalam provides a polished, Baa-native IDE experience.

**Scope:** Qalam IDE, Takween, Baa, and Nazm on Windows and Linux.

## Objective

Finish the remaining ecosystem hardening and production-admission work without
interrupting the current Qalam IDE priority. The resumed work will make
cancellation reliable across the full toolchain, qualify Nazm's in-process API
for production use, and complete the next local-first package-management slice.

## 1. Qalam Process-Tree Cancellation

Make cancellation terminate the complete process tree started by Qalam:

```text
Qalam -> Takween -> Baa -> Nazm / linker / user program
```

Required work:

- Own Windows process trees with Job Objects.
- Own POSIX process trees with process groups.
- Cancel Takween and every descendant, including children and grandchildren.
- Add deterministic child/grandchild fixtures.
- Add a headless Qalam -> Takween -> Baa -> Nazm cancellation gate on Windows
  and Linux.
- Preserve the structured `TOOLING_CANCELLED` result and Takween event
  semantics.
- Verify temporary processes and artifacts are cleaned up.
- Update the umbrella ecosystem roadmap and compatibility lock with the final
  cancellation contract.

Acceptance criteria:

- No Takween, Baa, Nazm, linker, executable, or fixture descendant survives a
  completed cancellation.
- Qalam reports cancellation as cancellation, never as an unexplained build
  failure.
- The behavior passes on Windows and Linux.

## 2. In-Process Nazm Production Admission

After cancellation hardening, qualify the stable Nazm API for production use
inside Baa rather than relying only on an external Nazm process.

Required work:

- Run the full 100-source Baa/Nazm coverage corpus through the in-process API.
- Verify assembly, sections, symbols, relocations, link results, and runtime
  behavior against the admitted production path.
- Add concurrency and re-entrancy coverage.
- Add allocation-failure and error-propagation coverage.
- Run leak, stress, determinism, and performance gates.
- Make every unsupported form and Nazm failure visible; never silently fall
  back to GAS.
- Record an explicit production-default decision with evidence.

Acceptance criteria:

- The stable Nazm API passes the full corpus and platform gates with equivalent
  observable behavior.
- Baa can select the admitted path without losing diagnostic, source-map,
  fingerprint, or cache correctness.
- The production-default decision is documented and reflected in ecosystem
  compatibility data.

## 3. Local-First Package Milestone

Complete the next package-system slice without introducing a public registry.

Required work:

- Add the Arabic package commands `أضف`, `احذف`, and `ثبت`.
- Finish NFC normalization and migration rules for package identity.
- Add package namespaces and required package metadata.
- Preserve safe archive extraction, vendoring, hashes, lockfile behavior, and
  Baa/target compatibility constraints.
- Add Windows/Linux tests for Arabic names, Unicode paths, dependency graphs,
  locked installs, and migration conflicts.
- Keep resolution local-first and deterministic; defer remote registry design.

Acceptance criteria:

- A local dependency can be added, removed, installed, vendored, locked, and
  rebuilt using Arabic commands on Windows and Linux.
- Canonically equivalent Unicode package names cannot create distinct or
  ambiguous identities.
- Namespace and Baa/target constraint failures are structured and actionable.

## Resumption Order

1. Complete and admit the Qalam Baa-native IDE milestone.
2. Harden Qalam process-tree cancellation.
3. Admit Nazm's in-process production path.
4. Complete the local-first package CLI, NFC identity, and namespaces.
5. Re-run the full ecosystem compatibility and cross-platform CI gates.

## Explicitly Deferred

- A public package registry.
- Network package discovery or publication.
- Any cutover that lacks Windows/Linux evidence or silently falls back to a
  different toolchain.
