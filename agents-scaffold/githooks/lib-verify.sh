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
	elif [ -e "$root/scripts/verify" ]; then
		# A verify script that exists but is not executable is a gate that
		# silently stopped gating. Refuse rather than fall through.
		echo "verify: scripts/verify exists but is not executable — chmod +x it." >&2
		return 1
	fi
	# node check, not grep: '"verify"' matches deps or other scripts' bodies
	# anywhere in the file and would gate commits on a script that isn't there.
	# The cheap grep is only a pre-filter. A missing node and a missing script
	# used to fail the same way (2>/dev/null) and both fell through to "no
	# gate" — with fnm, node is on PATH only after `fnm env`, which a GUI git
	# client or a bare hook shell never ran.
	if [ -f "$root/package.json" ] && grep -q '"verify"' "$root/package.json"; then
		if ! command -v node >/dev/null 2>&1; then
			echo "verify: package.json mentions \"verify\" but node is not on this hook's PATH — refusing to skip the gate." >&2
			return 1
		fi
		if node -e 'process.exit(require(process.argv[1]).scripts?.verify ? 0 : 1)' "$root/package.json"; then
			echo "verify: npm run verify"
			( cd "$root" && npm run --silent verify )
			return $?
		fi
	fi
	if [ -f "$root/Makefile" ] && grep -qE '^verify:' "$root/Makefile"; then
		echo "verify: make verify"
		( cd "$root" && make -s verify )
		return $?
	fi
	echo "verify: no verify target yet (skipping) — add scripts/verify, an npm \"verify\" script, or a Makefile \"verify:\" target."
	return 0
}
