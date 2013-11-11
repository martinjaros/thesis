OPTIONS = --standalone --number-sections --table-of-contents
TEMPLATES = --template=templates/template.tex
TEMPLATES += --include-in-header=templates/header.tex
TEMPLATES += --include-before-body=templates/body.tex

.PHONY: all clean

all: document.pdf index.html

clean:
	@rm -f index.html document.pdf images/*.pdf sources/images_converted.txt

index.html: sources/* images/*
	@echo $@
	@pandoc $(OPTIONS) --mathjax -o $@ sources/header.txt sources/*.md sources/images.txt

document.pdf: sources/* templates/* samples/* sources/images_converted.txt $(patsubst %.svg, %.pdf, $(wildcard images/*.svg))
	@echo $@
	@pandoc $(OPTIONS) $(TEMPLATES) -o $@ sources/*.md sources/images_converted.txt

images/%.pdf: images/%.svg
	@echo $@
	@inkscape $< --export-pdf=$@

sources/images_converted.txt: sources/images.txt
	@echo $@
	@sed 's/.svg/.pdf/g' $< > $@

