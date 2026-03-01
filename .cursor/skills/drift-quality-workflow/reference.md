# Drift Config and MCP Reference

Use this file when you need exact drift.toml structure or the full list of MCP tools and Cortex workflows.

## drift.toml schema (representative)

```toml
[scan]
include = ["src/**", "lib/**", "app/**"]
exclude = ["node_modules/**", "dist/**", "build/**", ".git/**", "vendor/**"]

[policy]
mode = "standard"   # strict | standard | lenient

[gates]
pattern-compliance = { enabled = true, threshold = 80 }
constraint-verification = { enabled = true }
security-boundaries = { enabled = true }
test-coverage = { enabled = true, threshold = 60 }
error-handling = { enabled = true }
regression = { enabled = true }

[reporters]
formats = ["console", "json"]
```

## MCP entry-point tools

| Tool | Purpose |
|------|---------|
| `drift_scan` | Scan and analyze project (populates DB) |
| `drift_status` | Project health overview |
| `drift_tool` | Access internal analysis and Cortex tools (see below) |
| `drift_discover` | List analysis capabilities |
| `drift_workflow` | Multi-step analysis workflows |
| `drift_explain` | AI-ready context for code understanding |

## drift_tool internal tools

Pass `{ "tool": "<name>", ... }` to `drift_tool`:

- **Analysis:** `violations`, `patterns`, `call_graph`, `boundaries`, `check`, `gates`, `audit`
- **Security:** `owasp`, `crypto`, `taint`, `security_summary`
- **Structural:** `coupling`, `contracts`, `constraints`, `decomposition`, `wrappers`, `dna`
- **Graph:** `reachability`, `impact`, `error_handling`, `test_topology`
- **Advanced:** `simulate`, `decisions`, `context`, `generate_spec`
- **Feedback:** `dismiss`, `fix`, `suppress`
- **Operational:** `report`, `export`, `gc`, `status`

## Cortex tools (via drift_tool)

Use `{ "tool": "cortex_<name>", ... }`:

- **Memory:** `cortex_memory_add`, `cortex_memory_search`, `cortex_memory_get`, `cortex_memory_update`, `cortex_memory_delete`, `cortex_memory_list`, `cortex_memory_link`, `cortex_memory_unlink`
- **Retrieval:** `cortex_context`, `cortex_search`, `cortex_related`
- **Causal:** `cortex_why`, `cortex_explain`, `cortex_counterfactual`, `cortex_intervention`
- **Learning:** `cortex_learn`, `cortex_feedback`, `cortex_validate`
- **Generation:** `cortex_gen_context`, `cortex_gen_outcome`
- **Prediction:** `cortex_predict`, `cortex_preload`
- **Temporal:** `cortex_time_travel`, `cortex_time_diff`, `cortex_time_replay`, `cortex_knowledge_health`, `cortex_knowledge_timeline`
- **Multi-Agent:** `cortex_agent_register`, `cortex_agent_share`, `cortex_agent_project`, `cortex_agent_provenance`, `cortex_agent_trust`
- **System:** `cortex_status`, `cortex_metrics`, `cortex_consolidate`, `cortex_validate_system`, `cortex_gc`, `cortex_export`, `cortex_import`, `cortex_reembed`

## Cursor MCP config

To enable the Drift MCP server in Cursor, add to `.cursor/mcp.json` in the project root:

```json
{
  "mcpServers": {
    "drift": {
      "command": "node",
      "args": [
        "/path/to/driftv2/packages/drift-mcp/dist/index.js",
        "--project-root",
        "."
      ]
    }
  }
}
```

Replace `/path/to/driftv2` with the actual path to the Drift v2 repo.
