#!/bin/sh
# Shared: resolve and run the project's verify gate.
# Returns 0 if verify passes OR if no verify target exists yet (nothing
# to gate on). Set VERIFY_FULL=1 to request the fuller lane (the
# project's verify script decides what that means).
run_verify() {
	root=$(git rev-parse --show-toplevel)
	if [ -x "$root/scripts/verify" ]; then
		echo "verify: scripts/verify"
		"$root/scripts/verify"
		return $?
	fi
	# node check, not grep: '"verify"' matches deps or other scripts' bodies
	# anywhere in the file and would gate commits on a script that isn't there.
	if [ -f "$root/package.json" ] \
		&& node -e 'process.exit(require(process.argv[1]).scripts?.verify ? 0 : 1)' "$root/package.json" 2>/dev/null; then
		echo "verify: npm run verify"
		( cd "$root" && npm run --silent verify )
		return $?
	fi
	if [ -f "$root/Makefile" ] && grep -qE '^verify:' "$root/Makefile"; then
		echo "verify: make verify"
		( cd "$root" && make -s verify )
		return $?
	fi
	echo "verify: no verify target yet (skipping) — add scripts/verify, an npm \"verify\" script, or a Makefile \"verify:\" target."
	return 0
}
