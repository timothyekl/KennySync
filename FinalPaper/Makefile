all: paper FORCE

paper: images acm_proc_article-sp.cls sigproc-sp.tex sigproc.bib
	pdflatex -interaction=batchmode sigproc-sp.tex
	bibtex sigproc-sp
	pdflatex -interaction=batchmode sigproc-sp.tex
	pdflatex -interaction=batchmode sigproc-sp.tex
	make clean-auxfiles

images: flies.eps fly.eps rosette.ps
	epstopdf flies.eps
	epstopdf fly.eps
	epstopdf rosette.ps

clean-auxfiles: clean-images
	rm -f sigproc-sp.{aux,bbl,blg,log}

clean-images:
	rm -f {flies,fly,rosette}.pdf

clean: clean-auxfiles
	rm -f sigproc-sp.pdf

FORCE:
