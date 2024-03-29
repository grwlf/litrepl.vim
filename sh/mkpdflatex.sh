#!/bin/sh

set -e -x

CWD="$LITREPL_ROOT"
TEX="$1"
shift
test -f "$TEX"

D=$CWD/_pdflatex
mkdir $D 2>/dev/null || true

TEXminted=$(dirname "$TEX")/$(basename "$TEX" .tex).minted.tex
trap "rm $TEXminted" 0 1 2 9

(
cd $(dirname "$TEX")
sed "s@usepackage{minted}@usepackage[outputdir=$D]{minted}@" \
  "$(basename $TEX)" > "$(basename $TEXminted)"
pdflatex \
  --shell-escape \
  --output-directory="$D" \
  "$(basename $TEXminted)" "$@"
)

cp $D/$(basename "$TEXminted" .tex).pdf \
   $(dirname "$TEX")/$(basename "$TEX" .tex).pdf
