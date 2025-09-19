# Memory Fragmentation Analysis Makefile
# Generates visualization PNGs for all fragmentation data

# Directories
PW_DATA_DIR = pw-data-v1/fragmentation
OUTPUT_DIR = output
IMAGES_DIR = images

# Data archive
PW_DATA_ARCHIVE = pw-data-v1.tar.gz

# Python scripts
VISUALIZER = ./fragmentation_visualizer.py
AB_COMPARE = ./fragmentation_ab_compare.py

# Check if data needs to be extracted
ifeq ($(wildcard $(PW_DATA_DIR)/*.json),)
    NEED_EXTRACT = yes
else
    NEED_EXTRACT = no
endif

# Find all JSON data files in pw-data-v1/fragmentation
PW_JSON_FILES := $(wildcard $(PW_DATA_DIR)/*_fragmentation_data_interim.json)
PW_CONFIGS := $(patsubst $(PW_DATA_DIR)/%_fragmentation_data_interim.json,%,$(PW_JSON_FILES))

# Output PNG files - one per configuration
PW_SINGLE_PNGS := $(patsubst %,$(OUTPUT_DIR)/%_single.png,$(PW_CONFIGS))

# Comparison PNGs
PW_4K_VS_16K_PNG := $(OUTPUT_DIR)/pw2-xfs-reflink-4k-vs-16k.png
PW_4K_VS_32K_PNG := $(OUTPUT_DIR)/pw2-xfs-reflink-4k-vs-32k.png
PW_16K_VS_32K_PNG := $(OUTPUT_DIR)/pw2-xfs-reflink-16k-vs-32k.png
PW_DEV_COMPARISON_PNG := $(OUTPUT_DIR)/pw2-dev-comparison-16k-vs-32k.png
PW_ALL_COMPARISON_PNG := $(OUTPUT_DIR)/pw2-all-configs-comparison.png

# Main targets
.PHONY: all clean simple compare pw-analysis pw-single pw-comparisons copy-to-images extract-data check-data

# Default target - extract data first, then run parallel build
all: check-data
	@$(MAKE) -j$(shell nproc) all-targets

all-targets: pw-analysis-targets simple compare

# Check and extract data if needed (runs first, not in parallel)
check-data:
	@if [ ! -f $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json ]; then \
		echo "Extracting data from $(PW_DATA_ARCHIVE)..."; \
		mkdir -p pw-data-v1; \
		tar -xzf $(PW_DATA_ARCHIVE) -C pw-data-v1; \
		echo "Data extracted successfully"; \
	fi

# Legacy targets for backward compatibility
simple:
	@echo "Generating simple fragmentation analysis..."
	@if [ -f data/fragmentation_data_simple.json ]; then \
		$(VISUALIZER) data/fragmentation_data_simple.json; \
	else \
		echo "Warning: data/fragmentation_data_simple.json not found"; \
	fi

compare:
	@echo "Generating A/B comparison..."
	@if [ -f data/fragmentation_data_simple.json ] && [ -f data/fragmentation_data_load.json ]; then \
		$(VISUALIZER) data/fragmentation_data_simple.json --compare data/fragmentation_data_load.json --labels "A" "B"; \
	else \
		echo "Warning: comparison data files not found"; \
	fi

# Extract data from archive if needed
extract-data:
	@if [ "$(NEED_EXTRACT)" = "yes" ] || [ ! -d $(PW_DATA_DIR) ] || [ -z "$$(ls -A $(PW_DATA_DIR)/*.json 2>/dev/null)" ]; then \
		echo "Extracting data from $(PW_DATA_ARCHIVE)..."; \
		mkdir -p pw-data-v1; \
		tar -xzf $(PW_DATA_ARCHIVE) -C pw-data-v1; \
		echo "Data extracted successfully"; \
	else \
		echo "Data already extracted"; \
	fi

# Main parallel writeback analysis target
pw-analysis: check-data
	@$(MAKE) -j$(shell nproc) pw-analysis-targets

pw-analysis-targets: pw-single pw-comparisons copy-to-images
	@echo "==================================================="
	@echo "Parallel Writeback Analysis Complete!"
	@echo "Generated visualizations in: $(OUTPUT_DIR)/"
	@echo "Copied to: $(IMAGES_DIR)/"
	@echo "==================================================="

# Generate all single configuration analyses
pw-single: $(PW_SINGLE_PNGS)
	@echo "Single configuration analyses complete"

# Generate comparison analyses
pw-comparisons: $(PW_4K_VS_16K_PNG) $(PW_4K_VS_32K_PNG) $(PW_16K_VS_32K_PNG) $(PW_DEV_COMPARISON_PNG) $(PW_ALL_COMPARISON_PNG)
	@echo "Comparison analyses complete"

# Create output directory
$(OUTPUT_DIR):
	@mkdir -p $(OUTPUT_DIR)

# Copy generated images to images directory
copy-to-images:
	@echo "Copying visualizations to $(IMAGES_DIR)/"
	@mkdir -p $(IMAGES_DIR)
	@if ls $(OUTPUT_DIR)/*.png 1> /dev/null 2>&1; then \
		cp $(OUTPUT_DIR)/*.png $(IMAGES_DIR)/; \
	fi

# Rule to generate single configuration PNG
$(OUTPUT_DIR)/%_single.png: $(PW_DATA_DIR)/%_fragmentation_data_interim.json $(OUTPUT_DIR)
	@echo "Generating single analysis for $*..."
	@$(VISUALIZER) $< -o $@


# 4K vs 16K comparison
$(PW_4K_VS_16K_PNG): $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json \
                      $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json \
                      $(OUTPUT_DIR)
	@echo "Generating 4K vs 16K comparison..."
	@$(VISUALIZER) $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json \
		--compare $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json \
		--labels "XFS 4K" "XFS 16K" \
		-o $@

# 4K vs 32K comparison
$(PW_4K_VS_32K_PNG): $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json \
                      $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json \
                      $(OUTPUT_DIR)
	@echo "Generating 4K vs 32K comparison..."
	@$(VISUALIZER) $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json \
		--compare $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json \
		--labels "XFS 4K" "XFS 32K" \
		-o $@

# 16K vs 32K comparison
$(PW_16K_VS_32K_PNG): $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json \
                       $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json \
                       $(OUTPUT_DIR)
	@echo "Generating 16K vs 32K comparison..."
	@$(VISUALIZER) $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json \
		--compare $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json \
		--labels "XFS 16K" "XFS 32K" \
		-o $@

# Dev comparison (16K dev vs 32K dev)
$(PW_DEV_COMPARISON_PNG): $(OUTPUT_DIR)
	@echo "Generating dev kernel comparison..."
	@if [ -f $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json ] && \
	    [ -f $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks-dev_fragmentation_data_interim.json ]; then \
		$(VISUALIZER) $(PW_DATA_DIR)/pw2-xfs-reflink-16k-4ks-dev_fragmentation_data_interim.json \
			--compare $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks-dev_fragmentation_data_interim.json \
			--labels "XFS 16K-dev" "XFS 32K-dev" \
			-o $@; \
	else \
		echo "Warning: Dev kernel data files not found"; \
	fi

# All configurations comparison using A/B compare script if available
$(PW_ALL_COMPARISON_PNG): $(OUTPUT_DIR)
	@echo "Generating all configurations comparison..."
	@if [ -f $(AB_COMPARE) ]; then \
		python3 $(AB_COMPARE) pw-data-v1 --output $@; \
	else \
		echo "Using standard comparison for all configs..."; \
		if [ -f $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json ] && \
		   [ -f $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json ]; then \
			$(VISUALIZER) $(PW_DATA_DIR)/pw2-xfs-reflink-4k_fragmentation_data_interim.json \
				--compare $(PW_DATA_DIR)/pw2-xfs-reflink-32k-4ks_fragmentation_data_interim.json \
				--labels "Baseline 4K" "Best 32K" \
				-o $@; \
		fi; \
	fi

# Clean targets
clean:
	@echo "Cleaning generated files..."
	@rm -f fragmentation_analysis_*.png
	@rm -f fragmentation_comparison_*.png
	@rm -rf $(OUTPUT_DIR)

clean-all: clean
	@echo "Cleaning all generated and backup files..."
	@rm -f *_old.py
	@rm -f *.pyc
	@rm -rf __pycache__

clean-data:
	@echo "Cleaning extracted data files..."
	@rm -rf pw-data-v1/fragmentation

clean-everything: clean-all clean-data
	@echo "All generated and extracted files removed"

# Help target
help:
	@echo "Memory Fragmentation Analysis Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Run all analyses in parallel (DEFAULT - uses all cores)"
	@echo "  pw-analysis      - Generate parallel writeback analyses (auto-parallel)"
	@echo "  pw-single        - Generate individual configuration analyses"
	@echo "  pw-comparisons   - Generate comparison analyses"
	@echo "  simple           - Generate simple fragmentation analysis (legacy)"
	@echo "  compare          - Generate A/B comparison (legacy)"
	@echo "  clean            - Remove generated PNG files"
	@echo "  clean-all        - Remove all generated and backup files"
	@echo "  clean-data       - Remove extracted data files"
	@echo "  clean-everything - Remove all generated and extracted files"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Note: All targets now run in parallel by default using all CPU cores"
	@echo "Generated files will be in: $(OUTPUT_DIR)/ and $(IMAGES_DIR)/"

# Debug target to show detected configurations
debug-configs:
	@echo "Detected configurations in $(PW_DATA_DIR):"
	@for config in $(PW_CONFIGS); do \
		echo "  - $$config"; \
	done
	@echo ""
	@echo "JSON files found:"
	@for file in $(PW_JSON_FILES); do \
		echo "  - $$file"; \
	done