---
title: "Broken or moved links detected"
labels: documentation
---
The scheduled link check found one or more URLs in depictr's sources
(DESCRIPTION, README, help pages or vignettes) that are unreachable, or that
redirect to a new address.

- Failing run, with the list of URLs: {{ env.RUN_URL }}

CRAN flags redirecting and unreachable URLs. Update each redirecting URL to its
final destination and each unreachable one to a working equivalent.

A transient network timeout can occasionally cause a false positive, so re-run
the `link-check` workflow to confirm before changing anything. This issue
receives a comment on each subsequent failure and can be closed once the link
check passes again.
