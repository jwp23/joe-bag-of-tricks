# Pre-Loaded Stack References

Starting points — always verify versions with the user. For each stack, give the **command** for the formatter/linter, not a description of its rules. Idioms below are the few project-relevant deltas worth stating; standard conventions are excluded.

- **Node/TypeScript** — Prettier; ESLint (flat config). Docs: nodejs.org/docs, typescriptlang.org/docs. Idioms: ES modules, Zod validation, strict TS, async/await.
- **Python** — Ruff (format + lint); mypy/pyright. Docs: docs.python.org/3. Idioms: type hints, `pathlib`, dataclasses/Pydantic, context managers.
- **Go** — `gofmt` (non-negotiable); golangci-lint. Docs: go.dev/doc. Idioms: `context.Context` first param, explicit error returns, table-driven tests.
- **Rust** — rustfmt; clippy. Docs: doc.rust-lang.org, docs.rs. Idioms: `Result`/`Option`, derive macros, cargo conventions.
- **Bash** — shfmt; shellcheck. Docs: gnu.org/software/bash/manual. Idioms: `set -euo pipefail`, quote variables, `[[ ]]` over `[ ]`.
- **Terraform** — `terraform fmt`; tflint. Docs: developer.hashicorp.com/terraform. Idioms: modules, remote state, variable validation.
- **Helm/K8s** — `helm lint`; kubeconform. Docs: helm.sh/docs, kubernetes.io/docs. Idioms: values-schema validation, resource limits, RBAC least-privilege.
