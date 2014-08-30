#!/bin/bash

pandoc sections/*.md -N --toc -o Drillbridge.pdf --latex-engine=xelatex -B sections/05_PREAMBLE.txt --template=template.tex
