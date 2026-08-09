# Dotfiles — bootstrap + symlink management.
#
#   make bootstrap   FRESH MACHINE: CLT + Homebrew + brew bundle + links + node + nvim
#   make install     symlink everything into $HOME / $XDG_CONFIG_HOME (idempotent)
#   make uninstall   remove only the symlinks that point back into this repo
#   make relink      uninstall + install (repoint after moving the repo)
#   make status      show which of this repo's links are live / missing / stale
#   make help        this list
#
# `bootstrap` delegates to ./bootstrap.sh, `install` to ./install.sh (the
# source of truth for what links where). `uninstall`/`status` don't hardcode a
# list — they scan the usual roots for symlinks resolving into $(DOTFILES), so
# they never drift.

DOTFILES := $(patsubst %/,%,$(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
XDG      := $(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(HOME)/.config)
ROOTS    := $(HOME) $(XDG) $(HOME)/.claude
SHELL    := /bin/bash

.DEFAULT_GOAL := help

.PHONY: bootstrap install uninstall relink status help

bootstrap: ## Fresh machine: CLT + Homebrew + brew bundle + symlinks + node + nvim
	@./bootstrap.sh

install: ## Symlink dotfiles into place (safe to re-run)
	@./install.sh

uninstall: ## Remove only symlinks pointing back into this repo
	@removed=0; \
	for root in $(ROOTS); do \
	  [ -d "$$root" ] || continue; \
	  for l in "$$root"/.* "$$root"/*; do \
	    [ -L "$$l" ] || continue; \
	    case "$$(readlink "$$l")" in \
	      "$(DOTFILES)"/*) rm -v "$$l"; removed=$$((removed+1));; \
	    esac; \
	  done; \
	done; \
	echo "removed $$removed symlink(s)."

relink: uninstall install ## Repoint links (e.g. after moving the repo)

status: ## Show live / stale links that reference this repo
	@echo "repo: $(DOTFILES)"; \
	found=0; \
	for root in $(ROOTS); do \
	  [ -d "$$root" ] || continue; \
	  for l in "$$root"/.* "$$root"/*; do \
	    [ -L "$$l" ] || continue; \
	    tgt="$$(readlink "$$l")"; \
	    case "$$tgt" in \
	      "$(DOTFILES)"/*) found=$$((found+1)); \
	        if [ -e "$$l" ]; then echo "  ok    $$l -> $$tgt"; \
	        else echo "  STALE $$l -> $$tgt"; fi;; \
	    esac; \
	  done; \
	done; \
	[ "$$found" -gt 0 ] || echo "  (no links into this repo found)"

help: ## Show this help
	@grep -E '^[a-z].*:.*## ' $(MAKEFILE_LIST) \
	  | sed -E 's/:.*## /\t/' \
	  | awk -F'\t' '{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
