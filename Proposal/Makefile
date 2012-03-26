PDFLATEX_FLAGS = -interaction=batchmode -shell-escape

all: Proposal

Proposal: Proposal.tex Proposal.bib
	pdflatex $(PDFLATEX_FLAGS) Proposal.tex
	bibtex Proposal
	pdflatex $(PDFLATEX_FLAGS) Proposal.tex
	pdflatex $(PDFLATEX_FLAGS) Proposal.tex
	make clean_auxfiles

clean_auxfiles: FORCE
	rm -f Proposal.{aux,bbl,blg,log,out}

clean: clean_auxfiles FORCE
	rm -f Proposal.pdf

FORCE:
