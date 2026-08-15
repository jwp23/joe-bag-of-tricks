# Licensing & Attribution

**Read before vendoring from any upstream.** This repo is bound for public release, so license
hygiene is non-negotiable.

## Upstream compatibility
- superpowers is **MIT** — compatible. Preserve its copyright + license notice when vendoring.
- For any NEW upstream: verify the license permits redistribution under this repo's license
  BEFORE vendoring. Refuse unknown or incompatible licenses.
- Record source + license for every vendored/patched/replaced file in `customizations.md`.

## Attribution discipline (public repo)
- Keep upstream `LICENSE` files; the top-level [`NOTICE`](../NOTICE) credits obra/superpowers
  (MIT) and any other upstreams — keep it in sync with `docs/customizations.md` as upstreams are
  added or dropped.
- Do not strip authorship headers from vendored or patched files.
