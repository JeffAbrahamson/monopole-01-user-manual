MAIN         := monopole-01-manual
OUTDIR       := pdf
SVG_DIR      := images
INKSCAPE_DIR := svg-inkscape

# --- SVGs ---------------------------------------------------------
SVGS       := $(wildcard $(SVG_DIR)/*.svg)
SVG_BASES  := $(notdir $(basename $(SVGS)))
SVG_PDFS   := $(addprefix $(INKSCAPE_DIR)/,$(addsuffix _svg-tex.pdf,$(SVG_BASES)))
SVG_TEXS   := $(addprefix $(INKSCAPE_DIR)/,$(addsuffix _svg-tex.pdf_tex,$(SVG_BASES)))

# --- AVIF -> PNG --------------------------------------------------------------
AVIF_DIR   := images
AVIFS      := $(wildcard $(AVIF_DIR)/*.avif)
AVIF_PNGS  := $(AVIFS:.avif=.png)

# Choose converter: "magick" (ImageMagick) or "avifdec" (libavif-bin)
AVIF_CONVERTER ?= magick
# If you want to force avifdec, run: make AVIF_CONVERTER=avifdec

.PHONY: all svg clean

all: $(OUTDIR)/$(MAIN).pdf

$(OUTDIR) $(INKSCAPE_DIR):
	mkdir -p $@

# Convert foo.svg -> svg-inkscape/foo_svg-tex.pdf (+ .pdf_tex)
$(INKSCAPE_DIR)/%_svg-tex.pdf: $(SVG_DIR)/%.svg | $(INKSCAPE_DIR)
	inkscape --export-type=pdf --export-latex --export-filename=$@ $<

# Declare the sidecar
$(INKSCAPE_DIR)/%_svg-tex.pdf_tex: $(INKSCAPE_DIR)/%_svg-tex.pdf ; @true

svg: $(SVG_PDFS) $(SVG_TEXS)

# --- AVIF conversion rules ----------------------------------------------------
# images/foo.avif -> images/foo.png
# Uses ImageMagick by default; switch to avifdec by setting AVIF_CONVERTER=avifdec
$(AVIF_DIR)/%.png: $(AVIF_DIR)/%.avif
ifeq ($(AVIF_CONVERTER),magick)
	@command -v convert >/dev/null || { echo "ImageMagick not found"; exit 1; }
	convert $< $@
else ifeq ($(AVIF_CONVERTER),avifdec)
	@command -v avifdec >/dev/null || { echo "avifdec not found (install libavif-bin)"; exit 1; }
	avifdec $< $@
else
	$(error Unsupported AVIF_CONVERTER '$(AVIF_CONVERTER)'; use 'magick' or 'avifdec')
endif

# --- Build document -----------------------------------------------------------
$(OUTDIR)/$(MAIN).pdf: $(MAIN).tex $(SVG_PDFS) $(SVG_TEXS) $(AVIF_PNGS) | $(OUTDIR)
	latexmk -lualatex -halt-on-error -interaction=nonstopmode -outdir=$(OUTDIR) $(MAIN)

# --- Cleaning ----------------------------------------------------------------
clean:
	latexmk -C -outdir=$(OUTDIR) $(MAIN) || true
	# Remove only the PNGs that were generated from AVIF sources
	rm -f $(AVIF_PNGS)
	rm -rf $(INKSCAPE_DIR)
	rm -f $(OUTDIR)/$(MAIN).aux $(OUTDIR)/$(MAIN).fdb_latexmk $(OUTDIR)/$(MAIN).fls $(OUTDIR)/$(MAIN).log
