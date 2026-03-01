---
name: drift-quality-workflow
description: Runs Drift-style codebase quality checks—scan, status, gates, and optional MCP tools. Use when the user asks for code quality, health check, pattern compliance, or drift analysis; before refactors or when onboarding to a codebase; or when configuring or interpreting drift.toml and quality gates.
---

# Drift-Style Codebase Quality Workflow

Apply a lightweight, Drift-inspired quality workflow: scan paths, run gates, and optionally use MCP tools when the Drift server is configured.

## When to Use This Workflow

- User asks for a "quality check," "health check," or "run drift."
- User wants to verify pattern compliance, constraints, or test coverage before/after changes.
- User is onboarding to the repo and needs a structured view of conventions and violations.
- User mentions `drift.toml`, quality gates, or MCP tools like `drift_scan` / `drift_status`.

## Quick Workflow

1. **Check for Drift tooling**
   - Look for `drift.toml` in project root or `drift v2` subfolder.
   - If present: follow "With Drift installed" below. If absent: follow "Without Drift" for manual checks.

2. **With Drift installed**
   - Run `drift scan` (or equivalent) to populate analysis.
   - Run `drift status` for health overview.
   - Run `drift check` (or `drift audit`) for gates and violations.
   - If MCP is configured: use `drift_scan`, `drift_status`, `drift_tool`, `drift_explain` as needed.

3. **Without Drift**
   - Infer conventions from existing code (naming, structure, tests).
   - Suggest a minimal `drift.toml` and gate set if the user wants to adopt this workflow.
   - For details on config and MCP tools, see [reference.md](reference.md).

## Gate Checklist (manual or drift-driven)

When assessing quality without Drift, or when interpreting Drift output, consider:

- **Pattern compliance**: Naming, file layout, and conventions consistent with the rest of the repo.
- **Constraints**: Architecture boundaries and dependency rules respected.
- **Security**: No obvious sensitive data in code, safe handling of inputs/outputs.
- **Tests**: Critical paths covered; suggest adding tests where missing.
- **Error handling**: Failures handled and surfaced clearly.

## Config and MCP

- **Config**: `drift.toml` defines scan include/exclude, policy mode, gates (pattern-compliance, constraint-verification, security-boundaries, test-coverage, error-handling, regression), and reporters.
- **MCP**: If the Drift MCP server is configured (e.g. in `.cursor/mcp.json`), use `drift_scan`, `drift_status`, `drift_tool`, `drift_workflow`, `drift_explain` per the tool descriptions.

For full config schema and MCP tool list, see [reference.md](reference.md).

## Output Format

When reporting quality or health:

1. **Summary**: One line on overall health (e.g. pass/fail, gate counts).
2. **Gates**: Which gates passed or failed and brief reason.
3. **Actions**: Concrete next steps (fix violation X, add test for Y, or add `drift.toml`).

Keep output scannable; avoid long prose unless the user asks for detail.
