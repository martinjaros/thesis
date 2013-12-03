TEX_OPTIONS  = --number-sections --toc
TEX_OPTIONS += --variable=geometry:"margin=1in"
TEX_OPTIONS += --variable=fontsize:"12pt"

TEX_TEMPLATES  = --template=templates/template.tex
TEX_TEMPLATES += --include-before-body=templates/include.tex
TEX_TEMPLATES += --bibliography=sources/biblio.bib
TEX_TEMPLATES += --csl=templates/iso690.csl

HTML_OPTIONS  = --toc --standalone --mathjax
HTML_OPTIONS += --template=templates/template.html
HTML_OPTIONS += --bibliography=sources/biblio.bib
HTML_OPTIONS += --csl=templates/iso690.csl

.PHONY: all clean

all: document.pdf index.html

clean:
	@rm -f index.html document.pdf images/*.pdf images/list-pdf.txt

index.html: sources/* templates/* images/*
	@echo $@
	@pandoc $(HTML_OPTIONS) -o $@ sources/[0-9]*.md sources/annexes.md sources/references.md images/list-src.txt

document.pdf: sources/* templates/* samples/* $(patsubst %.svg, %.pdf, $(wildcard images/*.svg))
	@echo $@
	@pandoc $(TEX_OPTIONS) --template=templates/annexes.tex -o /tmp/tex2pdf-annexes.tex sources/annexes.md images/list-pdf.txt
	@pandoc $(TEX_OPTIONS) $(TEX_TEMPLATES) --include-after-body=/tmp/tex2pdf-annexes.tex -o $@ sources/[0-9]*.md sources/references.md images/list-pdf.txt
	@rm /tmp/tex2pdf-annexes.tex

images/%.pdf: images/%.svg | images/list-pdf.txt
	@echo $@
	@inkscape $< --export-pdf=$@

images/list-pdf.txt: images/list-src.txt
	@echo $@
	@sed 's/.svg/.pdf/g' $< > $@
