OPTIONS = --number-sections --table-of-contents --include-in-header=templates/header.tex --template=templates/template.tex

.PHONY: all clean

all: document.pdf

clean:
	@rm document.pdf
	@rm images/*.pdf

document.pdf: sources/*.md $(patsubst %.svg, %.pdf, $(wildcard images/*.svg))
	@echo $@
	@pandoc $(OPTIONS) -o $@ sources/*.md

images/%.pdf: images/%.svg
	@echo $@
	@inkscape $< --export-pdf=$@
