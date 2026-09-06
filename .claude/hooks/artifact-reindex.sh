#!/bin/sh
# PostToolUse(Artifact): keep billing-docs STATUS.md section 6 in step with the
# artifact sources saved under design/.
#
# The generator reads each file's first-line `<!-- index: ... -->` comment, so a
# newly saved .html source only appears in the tree once it is re-run. Doing it
# here means `make check` stays green without anyone remembering.
#
# Never fails the tool call: the publish has already happened by this point, and
# a stale index is not worth surfacing as a tool error. No-op when the repo is
# absent, which is every machine that is not John's laptop.
set -u

gen="$HOME/dev/billing-docs/tools/build-index.py"
[ -f "$gen" ] || exit 0

python3 "$gen" >/dev/null 2>&1 || true
exit 0
