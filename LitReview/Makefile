PDFLATEX_FLAGS = -interaction=batchmode -shell-escape

all: LitReview

LitReview: LitReview.tex LitReview.bib
	pdflatex $(PDFLATEX_FLAGS) LitReview.tex
	bibtex LitReview
	pdflatex $(PDFLATEX_FLAGS) LitReview.tex
	pdflatex $(PDFLATEX_FLAGS) LitReview.tex
	make clean_auxfiles

clean_auxfiles: FORCE
	rm -f LitReview.{aux,bbl,blg,log,out}

clean: clean_auxfiles FORCE
	rm -f LitReview.pdf

FORCE:
