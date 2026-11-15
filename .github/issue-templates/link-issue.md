---
title: "Broken or moved links detected"
labels: documentation
---
The scheduled link check found one or more URLs in depictr's sources
(DESCRIPTION, README, help pages or vignettes) that are broken, or that
redirect to a new address.

- Failing run, with the list of URLs: {{ env.RUN_URL }}

CRAN flags redirecting and broken URLs. Update each redirecting URL to its final
destination and each broken one to a working equivalent.

A URL that gives no answer at all, by a timeout or a connection error, does not
fail the run: the workflow asks for it three more times and then reports it as a
warning. An HTTP error can still be transient, so re-run the `link-check`
workflow to confirm before changing anything. This issue receives a comment on
each subsequent failure and can be closed once the link check passes again.
