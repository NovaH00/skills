# =============================================================================
# Makefile for LaTeX Paper Automation
# =============================================================================

MAIN = main
BUILD_DIR = build
DOCX_OUT = $(BUILD_DIR)/$(MAIN).docx
PDF_OUT = $(MAIN).pdf
SCRIPTS_DIR = scripts

.PHONY: all pdf docx verify clean watch

all: pdf

# Build PDF using latexmk
pdf:
	latexmk -pdf -synctex=1 -interaction=nonstopmode $(MAIN).tex

# Continuous compilation watch mode
watch:
	latexmk -pdf -pvc -synctex=1 -interaction=nonstopmode $(MAIN).tex

# Export to Word (.docx) using pandoc with citation processing
docx:
	@mkdir -p $(BUILD_DIR)
	pandoc $(MAIN).tex \
		--from latex \
		--to docx \
		--output $(DOCX_OUT) \
		--bibliography=references.bib \
		--citeproc \
		--standalone
	@echo "Exported Word document to $(DOCX_OUT)"

# Verify experiment run provenance against runs.json
verify:
	@if [ -f $(SCRIPTS_DIR)/sync_runs.py ]; then \
		python3 $(SCRIPTS_DIR)/sync_runs.py verify; \
	elif [ -f sync_runs.py ]; then \
		python3 sync_runs.py verify; \
	else \
		echo "Notice: sync_runs.py not found in paper directory."; \
	fi

# Clean auxiliary compilation files
clean:
	latexmk -C $(MAIN).tex
	rm -rf $(BUILD_DIR) *.bbl *.run.xml *.synctex.gz
