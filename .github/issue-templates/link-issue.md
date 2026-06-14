---
title: "Broken or moved links detected"
labels: documentation
---
The scheduled link check found one or more URLs in depictr's sources
(DESCRIPTION, README, help pages or vignettes) that are unreachable, or that
redirect to a new address.

- Failing run, with the list of URLs: {{ env.RUN_URL }}

CRAN flags moved and broken URLs, so these are worth fixing: update each URL to
its final destination (for a redirect) or to a working equivalent.

A transient network timeout can occasionally cause a false positive, so re-run
the **link-check** workflow to confirm before changing anything. This issue
updates itself on each subsequent failure and can be closed once the link check
passes again.
