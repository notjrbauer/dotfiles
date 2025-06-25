.PHONY: clean upgrade reset help

# Display available commands
help:
	@echo "Available commands:"
	@echo "  make clean    - 🧹 Remove Neovim cache, state, and lock file"
	@echo "  make upgrade  - ⬆️  Upgrade Neovim Nightly via Homebrew"
	@echo "  make reset    - ♻️  Clean and then upgrade Neovim"
	@echo "  make help     - 🆘 Show this help message"

clean:
	@echo "🧹 Cleaning Neovim files..."
	rm -rf \
		~/.local/share/nvim \
		~/.local/state/nvim \
		~/.cache/nvim \
		~/.config/nvim/lazy-lock.json
	@echo "✅ Done cleaning."

upgrade:
	@echo "⬆️  Upgrading Neovim Nightly..."
	brew upgrade --cask neovim-nightly --no-quarantine --greedy-latest
	@echo "✅ Neovim Nightly upgraded."

plugins:
	@echo "⬆️  Installing Plugins..."
	nvim --headless "+Lazy! sync" +qa
	@echo "✅  Plugins installed."

reset: clean upgrade
