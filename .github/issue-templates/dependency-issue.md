---
title: "Dependency check is failing"
labels: dependencies
---
The scheduled dependency check failed for **{{ env.CONFIG }}**.

This usually means that a recent release, or a development version, of one of
depictr's dependencies has introduced a change that breaks the package.

- Failing run, with the full check log: {{ env.RUN_URL }}

This issue receives a comment on each subsequent failure, and can be closed once
the dependency check passes again. If the `dependency-autofix` workflow is
enabled (a `CLAUDE_CODE_OAUTH_TOKEN` secret is set), it starts once the failing
run has finished. Where it can fix the failure safely, it opens a pull request,
on which a maintainer has to start R-CMD-check. Otherwise, it comments here
with the cause and the options.
