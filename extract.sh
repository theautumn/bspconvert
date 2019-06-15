#!/bin/bash
FILES=218*.pdf
for f in $FILES
do
		# gs extracts the first page of the PDF
		printf  "Ghostscripting...\n\n"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
		   -dFirstPage=1 \
		   -dLastPage=1 \
		   -sOutputFile=temp.pdf \
		   ${f}


		# Convert that single page to jpg
		printf "Converting to jpg...\n\n"
		convert -density 400 temp.pdf temp.jpg

		# Extract just the portions of the page we are interested in.
		printf "Extracting interesting pieces of the page...\n\n"
		mogrify -gravity North\
						-density 400x400\
						-units PixelsPerInch\
						-crop '100%x25%'\
						-write titlestrip.png\
						temp.jpg

		mogrify -gravity East\
						-density 800x800\
						-units PixelsPerInch\
						-crop '25%x100%+0-500'\
						-write numberdateiss.png\
						titlestrip.png

		mogrify -gravity Center\
						-density 400x400\
						-units PixelsPerInch\
						-crop '50%x70%+50+100'\
						-write title.png\
						titlestrip.png

		tesseract title.png title bazaar
		tesseract numberdateiss.png numberdateiss bsp_number

		cat title.txt
		cat numberdateiss.txt | tr -d -c '[0-9A-Za-z]' | \
				sed -e 's/\(SECTION\)\(...\)\(...\)\(...\)\(Issue\)\([0-9]\)\([A-Z]*[a-z]*\)\([0-9]*\)/\1 \2-\3-\4 \5 \6 \7 \8/'
done
