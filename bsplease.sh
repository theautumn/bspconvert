#!/bin/bash

# A little script to make renaming Bell System Practices a bit easier."
# Sarah Autumn, 2020
# sarah@connectionsmuseum.org

# Define some colors
red=$'\e[1;31m'
yel=$'\e[1;33m'
end=$'\e[0m'

# Define some basic vars.
FILESDIR=in
TEMPDIR=temp
SECTION_REGEX="^([0-9]{3}.){2}([0-9]{3})(.*)"
mkdir -p ./temp

for f in $FILESDIR/*.pdf
do
		test -f "$f" || printf "No PDFs in input directory\n" && exit

		filename=$(basename -- "$f")
		printf "\n\nWorking on "$filename

		# Checks to see if section number is in beginning of filename.
		# If so, use it. If not, set flag so we can figure it out later.
		if [[ $filename =~ $SECTION_REGEX ]]; then
			printf "\nFilename contains BSP number. Using that for section."
			sectionno=${filename:0:11}
		else
			printf "\n${yel}Warning:${end} Filename DOES NOT contain BSP number. " 
			printf "Setting flag to perform OCR on section header."
			section_ocr_needed=true
		fi

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

		# If we need to process the section number, then lets do it.
		if [ "$section_ocr_needed" = true ] ; then
			tesseract $TEMPDIR/4_numberdateiss.png $TEMPDIR/numberdateiss quiet
			sectionno="$(grep -Eo '([0-9]{3}.){2}([0-9]{3})' $TEMPDIR/numberdateiss.txt)"
			issueno="$(ack -ho '(?<=ue )\d+' $TEMPDIR/numberdateiss.txt)"
		fi

		printf "Title and Section\n"
		printf '%s\n' '-----------------------'

		#cat $TEMPDIR/numberdateiss.txt | sed -e 's/ue l/ue 1/g' | \
		#		tee $TEMPDIR/numberdateiss.txt
		echo $sectionno "Issue:" $issueno
		printf "\n"
		cat $TEMPDIR/title.txt | sed -e 's/NO\. I/NO. 1/g' -e '/^$/q' \
				-e 's/§/5/g' |  sed -e '/^$/d' | tee output.txt

		# If the section number we got from OCR is all bonkers, ask the user.
		if [ -z "$sectionno" ] ; then
			printf "\n"
			printf "$red    Section number is all mangled:$end\n\n"
			printf "    "
			head -1 $TEMPDIR/numberdateiss.txt
			printf "\nPlease enter the correct section number.\n"
			read -p "Number: " sectionno
			printf "\nThanks\n"
		fi
	
		cp $FILESDIR/$filename ./done/$sectionno\_iss$issueno.pdf

		unset sectionno
done
