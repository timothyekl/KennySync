LATEX = pdflatex
LATEXFLAGS = -interaction=batchmode

all: paper FORCE

paper: acm_proc_article-sp.cls sigproc-sp.tex sigproc.bib
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
	bibtex sigproc-sp
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
	${LATEX} ${LATEXFLAGS} sigproc-sp.tex
	make clean-auxfiles

clean-auxfiles: FORCE
	rm -f sigproc-sp.{aux,bbl,blg,log}

clean: clean-auxfiles
	rm -f sigproc-sp.pdf

FORCE:
