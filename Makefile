
document.pdf: sources/* | $(patsubst %.svg,%.pdf,$(wildcard images/*.svg))
	pandoc --number-sections --toc --bibliography=templates/biblio.bib --csl=templates/iso690.csl --variable=fontsize:"12pt" --variable=geometry:"margin=1in" -o $@ $^

images/%.pdf: images/%.svg
	inkscape $< --export-pdf=$@

