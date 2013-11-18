TEX_OPTIONS = --number-sections --toc --template=templates/template.tex
TEX_OPTIONS += --variable=geometry:"margin=1in"
TEX_OPTIONS += --variable=fontsize:"12pt"

HTML_OPTIONS = --toc --standalone --mathjax

.PHONY: all clean

all: document.pdf index.html

clean:
	@rm -f index.html document.pdf images/*.pdf images/list-pdf.txt

index.html: sources/* images/*
	@echo $@
	@pandoc $(HTML_OPTIONS) -o $@ sources/*.md images/list-svg.txt

document.pdf: sources/* templates/* samples/* $(patsubst %.svg, %.pdf, $(wildcard images/*.svg))
	@echo $@
	@pandoc $(TEX_OPTIONS) -o $@ sources/*.md images/list-pdf.txt

images/%.pdf: images/%.svg | images/list-pdf.txt
	@echo $@
	@inkscape $< --export-pdf=$@

images/list-pdf.txt: images/list-svg.txt
	@echo $@
	@sed 's/.svg/.pdf/g' $< > $@
