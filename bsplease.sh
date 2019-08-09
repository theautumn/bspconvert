#!/bin/bash
FILES=./the-gauntlet/21*.pdf
TEMPDIR=./temp

mkdir -p ./temp

for f in $FILES
do

		printf "\n\nWorking on "$f
		filename=$(basename $f)
		sectionno=${filename:0:11}

		# gs extracts the first page of the PDF
		printf  "\nGhostscripting...\n"
		gs -q -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
		   -dFirstPage=1 \
		   -dLastPage=1 \
		   -sOutputFile=$TEMPDIR/1_gs.pdf \
		   ${f}


		# Convert that single page to jpg
		printf "Converting PDF --> PNG...\n"
		convert -density 400 $TEMPDIR/1_gs.pdf $TEMPDIR/2_convert.png
		printf "done\n"

		# Extract just the portions of the page we are interested in.
		printf "Extracting interesting pieces of the page...\n"
		mogrify -gravity North \
						-density 400x400 \
						-units PixelsPerInch \
						-crop '100%x25%' \
						-write $TEMPDIR/3_titlestrip.png \
						$TEMPDIR/2_convert.png

		mogrify -gravity East \
						-density 800x800 \
						-units PixelsPerInch \
						-crop '25%x100%+0-500' \
						-write $TEMPDIR/4_numberdateiss.png \
						$TEMPDIR/3_titlestrip.png

		mogrify -gravity Center \
						-density 400x400 \
						-units PixelsPerInch \
						-crop '2230x690+30+150' \
						-write $TEMPDIR/5_title.png \
						$TEMPDIR/3_titlestrip.png

		printf "Masking off areas where title is unlikely to appear...\n\n"
		mogrify -gravity Center \
						-size 2190x690 \
						-fill 'rgba( 255, 215, 215 , 1 )' \
						-draw 'rectangle 0,0 120,60' \
						-draw 'rectangle 0,550 160,690' \
						-draw 'rectangle 1800,550 2230,690' \
						-draw 'rectangle 0,660 2190,690' \
						-write $TEMPDIR/6_title_masked.png \
						$TEMPDIR/5_title.png

		tesseract $TEMPDIR/6_title_masked.png $TEMPDIR/title bazaar quiet
		tesseract $TEMPDIR/4_numberdateiss.png $TEMPDIR/numberdateiss bsp_number\
						quiet

		printf "Title and Section\n"
		printf '%s\n' '-----------------------'

		echo $sectionno
		echo $sectionno >> output.txt
		printf "\n"
		echo "" >> output.txt
		cat $TEMPDIR/title.txt | sed -e 's/NO\. I/NO. 1/g' -e '/^$/q' \
				-e 's/§/5/g' |  sed -e '/^$/d'


		cat $TEMPDIR/title.txt | sed -e 's/NO\. I/NO. 1/g' -e '/^$/q' \
				-e 's/§/5/g' |  sed -e '/^$/d' >> output.txt

		echo "" >> output.txt
#		cat numberdateiss.txt
done
