SOURCES = $(wildcard sources/*.md)
GRAPHICS = $(wildcard images/*.svg)
OPTIONS = --number-sections --table-of-contents --include-in-header=templates/header.tex --template=templates/template.tex

.PHONY: all clean

all: outputs/document.pdf

clean:
	@rm -r -f outputs

outputs/document.pdf: $(SOURCES) | $(GRAPHICS:images/%.svg=outputs/%.eps) outputs
	@echo $@
	@pandoc $(OPTIONS) -o $@ $^

outputs/%.eps: images/%.svg | outputs
	@echo $@
	@inkscape $< --export-eps=$@

outputs:
	@mkdir outputs
