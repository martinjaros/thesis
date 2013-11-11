OPTIONS = --number-sections --table-of-contents
TEMPLATES = --template=templates/template.tex
TEMPLATES += --include-in-header=templates/header.tex
TEMPLATES += --include-before-body=templates/body.tex

.PHONY: all clean

all: document.pdf

clean:
	@rm document.pdf
	@rm images/*.pdf

document.pdf: sources/* templates/* samples/* $(patsubst %.svg, %.pdf, $(wildcard images/*.svg))
	@echo $@
	@pandoc $(OPTIONS) $(TEMPLATES) -o $@ sources/*.md

images/%.pdf: images/%.svg
	@echo $@
	@inkscape $< --export-pdf=$@
