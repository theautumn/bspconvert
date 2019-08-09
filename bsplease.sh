#!/bin/bash
FILES=218-122*.pdf
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
						-crop '2190x690+50+150'\
						-write $TEMPDIR/title.png\
						$TEMPDIR/titlestrip.png

		printf "Masking off lower left corner to fix text recognition...\n\n"
		mogrify -gravity Center \
						-size 2190x690 \
						-fill 'rgba( 255, 215, 0 , 1 )' \
						-draw 'rectangle 0,550 100,690' \
						-write $TEMPDIR/title.png \
						$TEMPDIR/title.png

		tesseract $TEMPDIR/title.png $TEMPDIR/title bazaar
		tesseract $TEMPDIR/numberdateiss.png $TEMPDIR/numberdateiss bsp_number

		printf "\n\n Title and Section\n"
		printf '%s\n' '-----------------------'

		echo $sectionno
		echo $sectionno >> output.txt
		printf "\n"
		echo "" >> output.txt
		cat $TEMPDIR/title.txt | sed -e 's/NO\. I/NO. 1/g' -e '/^$/q' |\
				sed -e '/^$/d'

		cat $TEMPDIR/title.txt | sed -e 's/NO\. I/NO. 1/g' -e '/^$/q' |\
				sed -e '/^$/d' >> output.txt

		echo "" >> output.txt
#		cat numberdateiss.txt
done
