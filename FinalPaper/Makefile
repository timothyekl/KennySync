LATEX = pdflatex
LATEXFLAGS = -interaction=batchmode

all: paper FORCE

paper: images acm_proc_article-sp.cls sigproc-sp.tex sigproc.bib
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
	bibtex sigproc-sp
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
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
