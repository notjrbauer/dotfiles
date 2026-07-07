.PHONY: clean upgrade plugins reset help bench bench-save bench-compare bench-reset bench-noplugins bench-vs bench-clean wezterm debug

# Benchmark directory
BENCH_DIR := ./.benchmarks
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Display available commands
help:
	@echo "Available commands:"
	@echo "  make clean           - 🧹 Remove Neovim cache, state, and lock file"
	@echo "  make upgrade         - ⬆️  Upgrade Neovim Nightly via Homebrew"
	@echo "  make plugins         - 📦 Install/sync plugins"
	@echo "  make reset           - ♻️  Clean and then upgrade Neovim"
	@echo "  make bench           - ⏱️  Run startup time benchmark"
	@echo "  make bench-save      - 💾 Save benchmark with timestamp"
	@echo "  make bench-compare   - 📊 Compare two saved benchmarks"
	@echo "  make bench-reset     - 🔄 Benchmark before/after reset"
	@echo "  make bench-noplugins - 🚀 Benchmark without plugins (--clean)"
	@echo "  make bench-vs        - ⚔️  Compare with/without plugins"
	@echo "  make bench-clean     - ♻️  Clean bench directory"
	@echo "  make wezterm         - ♻️  Clean and upgrade wezterm"   
	@echo "  make debug           - 🆘  Start without deps"
	@echo "  make help            - 🆘  Show this help message"

clean:
	@echo "🧹 Cleaning Neovim files..."
	rm -rf \
		~/.local/share/nvim \
		~/.local/state/nvim \
		~/.cache/nvim
	@echo "✅ Done cleaning."

upgrade:
	@echo "⬆️  Upgrading Neovim Nightly..."
	brew upgrade --cask neovim-nightly --no-quarantine --greedy-latest
	@echo "✅ Neovim Nightly upgraded."

plugins:
	@echo "📦 Installing Plugins..."
	# Config uses vim.pack: a headless startup runs vim.pack.add and installs
	# any missing plugins, then quits. (Old lazy.nvim "+Lazy! sync" is gone.)
	nvim --headless "+lua print('plugins ready')" +qa
	@echo "✅ Plugins installed."

# Create benchmark directory if it doesn't exist
$(BENCH_DIR):
	@mkdir -p $(BENCH_DIR)

# Run a quick startup benchmark
bench:
	@echo "⏱️  Running Neovim startup benchmark..."
	@echo "Running 10 iterations..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		/usr/bin/time -p nvim --headless +qa 2>&1 | grep real | awk '{print $$2}'; \
	done > /tmp/nvim_bench.tmp
	@echo "📊 Results:"
	@awk '{s+=$$1} END {printf "Average: %.3fs\n", s/NR}' /tmp/nvim_bench.tmp
	@sort -n /tmp/nvim_bench.tmp | head -1 | awk '{printf "Min:     %.3fs\n", $$1}'
	@sort -n /tmp/nvim_bench.tmp | tail -1 | awk '{printf "Max:     %.3fs\n", $$1}'
	@rm /tmp/nvim_bench.tmp

# Save detailed benchmark with timestamp
bench-save: $(BENCH_DIR)
	@echo "💾 Saving detailed benchmark..."
	@echo "# Neovim Startup Benchmark - $(TIMESTAMP)" > $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "# Neovim version:" >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@nvim --version | head -1 >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "" >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "## Timing Summary (10 runs):" >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		/usr/bin/time -p nvim --headless +qa 2>&1 | grep real | awk '{print $$2}'; \
	done > /tmp/nvim_bench.tmp
	@# Calculate stats using shell commands
	@awk '{s+=$$1} END {printf "Average: %.3fs\n", s/NR}' /tmp/nvim_bench.tmp >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@sort -n /tmp/nvim_bench.tmp | head -1 | awk '{printf "Min:     %.3fs\n", $$1}' >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@sort -n /tmp/nvim_bench.tmp | tail -1 | awk '{printf "Max:     %.3fs\n", $$1}' >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@sort -n /tmp/nvim_bench.tmp | awk 'NR==5{printf "Median:  %.3fs\n", $$1}' >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "" >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "## Detailed Startup Analysis:" >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@nvim --startuptime /tmp/nvim_startup.log --headless +qa
	@head -20 /tmp/nvim_startup.log >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@echo "..." >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@tail -10 /tmp/nvim_startup.log >> $(BENCH_DIR)/bench_$(TIMESTAMP).txt
	@rm /tmp/nvim_bench.tmp /tmp/nvim_startup.log
	@echo "✅ Benchmark saved to $(BENCH_DIR)/bench_$(TIMESTAMP).txt"

# Compare two benchmark files
bench-compare: $(BENCH_DIR)
	@echo "📊 Available benchmark files:"
	@ls -1 $(BENCH_DIR)/bench_*.txt 2>/dev/null | nl || (echo "No benchmark files found. Run 'make bench-save' first." && exit 1)
	@echo ""
	@read -p "Enter number for first benchmark: " first; \
	read -p "Enter number for second benchmark: " second; \
	file1=$$(ls -1 $(BENCH_DIR)/bench_*.txt | sed -n "$${first}p"); \
	file2=$$(ls -1 $(BENCH_DIR)/bench_*.txt | sed -n "$${second}p"); \
	if [ -f "$$file1" ] && [ -f "$$file2" ]; then \
		echo "🔍 Comparing $$file1 vs $$file2"; \
		echo ""; \
		echo "=== First Benchmark ==="; \
		grep -A 4 "Timing Summary" "$$file1"; \
		echo ""; \
		echo "=== Second Benchmark ==="; \
		grep -A 4 "Timing Summary" "$$file2"; \
		echo ""; \
		echo "📈 Comparison:"; \
		avg1=$$(grep "Average:" "$$file1" | awk '{print $$2}' | sed 's/s//'); \
		avg2=$$(grep "Average:" "$$file2" | awk '{print $$2}' | sed 's/s//'); \
		awk -v a1="$$avg1" -v a2="$$avg2" 'BEGIN { \
			diff = a2 - a1; \
			percent = (diff / a1) * 100; \
			if (diff > 0) { \
				printf "⚠️  Slower by %.3fs (%.1f%% increase)\n", diff, percent; \
			} else if (diff < 0) { \
				printf "🚀 Faster by %.3fs (%.1f%% improvement)\n", -diff, -percent; \
			} else { \
				printf "🟰 No significant change\n"; \
			} \
		}'; \
	else \
		echo "❌ Invalid selection. File1: [$$file1] File2: [$$file2]"; \
	fi

# Benchmark before and after reset
bench-reset: $(BENCH_DIR)
	@echo "🔄 Running benchmark before/after reset..."
	@echo "📊 Benchmarking current state..."
	@$(MAKE) bench-save
	@echo ""
	@echo "♻️  Performing reset..."
	@$(MAKE) reset
	@$(MAKE) plugins
	@echo ""
	@echo "📊 Benchmarking after reset..."
	@$(MAKE) bench-save
	@echo ""
	@echo "🔍 Comparing results..."
	@files=$$(ls -1t $(BENCH_DIR)/bench_*.txt | head -n 2); \
	file1=$$(echo "$$files" | sed -n '1p'); \
	file2=$$(echo "$$files" | sed -n '2p'); \
	if [ -f "$$file1" ] && [ -f "$$file2" ]; then \
		echo "Before reset: $$(grep "Average:" "$$file2" | awk '{print $$2}')"; \
		echo "After reset:  $$(grep "Average:" "$$file1" | awk '{print $$2}')"; \
		echo ""; \
		before=$$(grep "Average:" "$$file2" | awk '{print $$2}' | sed 's/s//'); \
		after=$$(grep "Average:" "$$file1" | awk '{print $$2}' | sed 's/s//'); \
		awk -v b="$$before" -v a="$$after" 'BEGIN { \
			diff = a - b; \
			percent = (diff / b) * 100; \
			if (diff > 0) { \
				printf "⚠️  Slower by %.3fs (%.1f%% increase)\n", diff, percent; \
			} else if (diff < 0) { \
				printf "🚀 Faster by %.3fs (%.1f%% improvement)\n", -diff, -percent; \
			} else { \
				printf "🟰 No significant change\n"; \
			} \
		}'; \
	else \
		echo "❌ Could not find benchmark files for comparison"; \
	fi
# Benchmark without plugins
bench-noplugins:
	@echo "🚀 Running Neovim startup benchmark (no plugins)..."
	@echo "Running 10 iterations with --clean..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		/usr/bin/time -p nvim --clean --headless +qa 2>&1 | grep real | awk '{print $$2}'; \
	done > /tmp/nvim_bench_clean.tmp
	@echo "📊 Results (No Plugins):"
	@awk '{s+=$$1} END {printf "Average: %.3fs\n", s/NR}' /tmp/nvim_bench_clean.tmp
	@sort -n /tmp/nvim_bench_clean.tmp | head -1 | awk '{printf "Min:     %.3fs\n", $$1}'
	@sort -n /tmp/nvim_bench_clean.tmp | tail -1 | awk '{printf "Max:     %.3fs\n", $$1}'
	@rm /tmp/nvim_bench_clean.tmp

# Compare with and without plugins
bench-vs:
	@echo "⚔️  Benchmarking Neovim: With vs Without Plugins"
	@echo ""
	@echo "🔧 Benchmarking WITH plugins..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		/usr/bin/time -p nvim --headless +qa 2>&1 | grep real | awk '{print $$2}'; \
	done > /tmp/nvim_bench_with.tmp
	@echo ""
	@echo "🚀 Benchmarking WITHOUT plugins (--clean)..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		/usr/bin/time -p nvim --clean --headless +qa 2>&1 | grep real | awk '{print $$2}'; \
	done > /tmp/nvim_bench_without.tmp
	@echo ""
	@echo "📊 COMPARISON RESULTS:"
	@echo "===================="
	@echo "With plugins:    $$(awk '{s+=$$1} END {printf "%.3fs", s/NR}' /tmp/nvim_bench_with.tmp)"
	@echo "Without plugins: $$(awk '{s+=$$1} END {printf "%.3fs", s/NR}' /tmp/nvim_bench_without.tmp)"
	@echo ""
	@awk 'FNR==NR{with+=$$1; with_count++; next} {without+=$$1; without_count++} END { \
		with_avg = with/with_count; \
		without_avg = without/without_count; \
		diff = with_avg - without_avg; \
		if (diff > 0) { \
			slowdown = (diff / without_avg) * 100; \
			printf "🐌 Plugins add %.3fs overhead (%.1f%% slower)\n", diff, slowdown; \
		} else { \
			printf "🤔 Unexpected result: plugins faster?\n"; \
		} \
	}' /tmp/nvim_bench_with.tmp /tmp/nvim_bench_without.tmp
	@rm /tmp/nvim_bench_with.tmp /tmp/nvim_bench_without.tmp

bench-clean:
	@echo "🧹 Cleaning Benchmark files..."
	@rm -rf $(BENCH_DIR)
	@echo "✅ Done cleaning."

debug:
	vim -u NONE -U NONE -N -i NONE init.lua

wezterm:
	brew upgrade --cask wezterm@nightly --no-quarantine --greedy-latest

reset: clean upgrade
