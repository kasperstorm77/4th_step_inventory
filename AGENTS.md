# AGENTS.md

Repository-wide entry point for coding agents. Apply this file from the Git
root through every descendant unless a closer `AGENTS.md` or
`AGENTS.override.md` supplies more specific instructions.

## Required instruction chain

1. Read [`CLAUDE.md`](CLAUDE.md) completely before investigating or changing
   the repository. Its filename is historical; its project rules apply to
   every coding agent and are the canonical source for safety, architecture,
   workflow, verification, Git, release, and response requirements.
2. Read the closest area-specific `CLAUDE.md` before touching files under
   `lib/<area>/`. Treat those files as scoped extensions of the root rules.
3. Read the canonical document that owns the requested behavior:
   - [`docs/architecture.md`](docs/architecture.md) for current behavior and
     invariants.
   - [`docs/implementation_plan.md`](docs/implementation_plan.md) for accepted
     future work and operational runbooks.
   - [`docs/historic_implementation.md`](docs/historic_implementation.md) for
     prior decisions and completed implementation context.
4. Read
   [`docs/static_guidelines/documentation_setup.md`](docs/static_guidelines/documentation_setup.md)
   and
   [`docs/static_guidelines/claude_md_best_practices.md`](docs/static_guidelines/claude_md_best_practices.md)
   before creating or restructuring documentation or agent instructions.

## Working agreement

- Follow system and explicit user instructions before repository guidance.
- Follow the closest scoped repository instruction when repository files
  differ; otherwise treat [`CLAUDE.md`](CLAUDE.md) as authoritative.
- Inspect the working tree before editing and preserve unrelated user changes.
- Diagnose the root cause before implementing a fix. Keep changes within the
  requested scope and register discovered deferred work in the implementation
  plan.
- Keep one canonical owner for each fact. Link to that owner instead of copying
  policy between instruction or documentation files.
- Run focused checks while iterating and the completion gates required by
  [`CLAUDE.md`](CLAUDE.md) before reporting success.
- Apply the opaque-file publication rule in [`CLAUDE.md`](CLAUDE.md): never
  read, search, print, diff, parse, or modify `NEVER_READ_THIS_FILE.md`; when
  Git reports it changed or untracked during an authorized commit/push, stage
  and publish it without inspecting its contents.
- Do not commit, push, bump versions, build releases, or publish externally
  unless the user explicitly requests that action.

## Handoff

Lead with the result, state what was and was not verified, and end with exactly
one recommended next step. Keep supporting detail in the canonical documents
and link to it instead of reproducing it in chat.
