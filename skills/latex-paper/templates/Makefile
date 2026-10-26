# =============================================================================
# Makefile for LaTeX Paper Automation
# =============================================================================

MAIN = main
OUTPUTS_DIR = outputs
FINAL_DIR = $(OUTPUTS_DIR)/final
INTERMEDIATE_DIR = $(OUTPUTS_DIR)/intermediate
SCRIPTS_DIR = scripts

PDF_OUT = $(FINAL_DIR)/$(MAIN).pdf
DOCX_OUT = $(FINAL_DIR)/$(MAIN).docx
HTML_OUT = $(FINAL_DIR)/$(MAIN).html

.PHONY: all pdf docx html verify clean distclean watch

all: pdf docx html

# Build PDF using latexmk with separated intermediate and final outputs
pdf:
	@mkdir -p $(FINAL_DIR) $(INTERMEDIATE_DIR)
	latexmk -pdf -synctex=1 -interaction=nonstopmode \
		-auxdir=$(INTERMEDIATE_DIR) \
		-outdir=$(FINAL_DIR) \
		$(MAIN).tex
	@echo "Built PDF at $(PDF_OUT)"

# Continuous compilation watch mode
watch:
	@mkdir -p $(FINAL_DIR) $(INTERMEDIATE_DIR)
	latexmk -pdf -pvc -synctex=1 -interaction=nonstopmode \
		-auxdir=$(INTERMEDIATE_DIR) \
		-outdir=$(FINAL_DIR) \
		$(MAIN).tex

# Export to Word (.docx) using pandoc with citation processing
docx:
	@mkdir -p $(FINAL_DIR)
	pandoc $(MAIN).tex \
		--from latex \
		--to docx \
		--output $(DOCX_OUT) \
		--bibliography=references.bib \
		--citeproc \
		--standalone
	@echo "Exported Word document to $(DOCX_OUT)"

# Export to HTML using pandoc with MathJax and citation processing
html:
	@mkdir -p $(FINAL_DIR)
	pandoc $(MAIN).tex \
		--from latex \
		--to html5 \
		--output $(HTML_OUT) \
		--bibliography=references.bib \
		--citeproc \
		--mathjax \
		--standalone
	@echo "Exported HTML document to $(HTML_OUT)"

# Verify experiment run provenance against runs.json
verify:
	@if [ -f $(SCRIPTS_DIR)/sync_runs.py ]; then \
		python3 $(SCRIPTS_DIR)/sync_runs.py verify; \
	elif [ -f sync_runs.py ]; then \
		python3 sync_runs.py verify; \
	else \
		echo "Notice: sync_runs.py not found in paper directory."; \
	fi

# Clean intermediate auxiliary files
clean:
	@if command -v latexmk >/dev/null 2>&1; then \
		latexmk -C -auxdir=$(INTERMEDIATE_DIR) -outdir=$(FINAL_DIR) $(MAIN).tex 2>/dev/null || true; \
	fi
	rm -rf $(INTERMEDIATE_DIR)
	@echo "Cleaned intermediate compilation artifacts."

# Clean all output artifacts including final exports
distclean: clean
	rm -rf $(OUTPUTS_DIR)
	@echo "Cleaned all outputs."
