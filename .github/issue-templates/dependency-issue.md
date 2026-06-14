---
title: "Dependency check is failing"
labels: dependencies
---
The scheduled dependency check failed for **{{ env.CONFIG }}**.

This usually means that a recent release, or a development version, of one of
depictr's dependencies has introduced a change that breaks the package.

- Failing run, with the full check log: {{ env.RUN_URL }}

This issue updates itself on each subsequent failure, and can be closed once the
dependency check passes again. If the `dependency-autofix` workflow is enabled
(an `ANTHROPIC_API_KEY` secret is set), it will already have attempted a fix and,
where possible, opened a pull request linked here.
