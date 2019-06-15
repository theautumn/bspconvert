#!/bin/bash
FILES=21*.pdf
TEMPDIR=./temp

mkdir -p ./temp

for f in $FILES
do

		echo "Working on "$f
		filename=$(basename $f)
		sectionno=${filename:0:11}

		# gs extracts the first page of the PDF
		printf  "Ghostscripting...\n\n"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
		   -dFirstPage=1 \
		   -dLastPage=1 \
		   -sOutputFile=$TEMPDIR/1_gs.pdf \
		   ${f}


		# Convert that single page to jpg
		printf "\nConverting PDF --> PNG...\n"
		convert -density 400 $TEMPDIR/1_gs.pdf $TEMPDIR/2_convert.png
		printf "done\n\n"

		# Extract just the portions of the page we are interested in.
		printf "Extracting interesting pieces of the page...\n\n"
		mogrify -gravity North\
						-density 400x400\
						-units PixelsPerInch\
						-crop '100%x25%'\
						-write $TEMPDIR/titlestrip.png\
						$TEMPDIR/2_convert.png

		mogrify -gravity East\
						-density 800x800\
						-units PixelsPerInch\
						-crop '25%x100%+0-500'\
						-write $TEMPDIR/numberdateiss.png\
						$TEMPDIR/titlestrip.png

		mogrify -gravity Center\
						-density 400x400\
						-units PixelsPerInch\
						-crop '50%x70%+50+100'\
						-write $TEMPDIR/title.png\
						$TEMPDIR/titlestrip.png

		tesseract $TEMPDIR/title.png $TEMPDIR/title bazaar
		tesseract $TEMPDIR/numberdateiss.png $TEMPDIR/numberdateiss bsp_number

		printf "\n\n Title and Section\n"
		printf '%s\n' '-----------------------'

		echo $sectionno
		printf "\n"
		cat $TEMPDIR/title.txt
#		cat numberdateiss.txt
#		cat numberdateiss.txt | tr -d -c '[0-9A-Za-z]' | \
#				sed -e 's/\(SECTION\)\(...\)\(...\)\(...\)\(Issue\)\([0-9]\)\([A-Z]*[a-z]*\)\([0-9]*\)/\1 \2-\3-\4 \5 \6 \7 \8/'
done
