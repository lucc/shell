#!/bin/sh
for f in *.pdf; do
  pdfseparate $f ${f%pdf}page.%d.pdf
done
for f in *.page.*.pdf; do
  gm convert -black-threshold 87% -density 250x250 $f bmp:- | \
    potrace -eo ${f%pdf}eps -
done
rm *.pdf


exit
######
# second step

name=hans
 
for f in $name*.eps; do
  # this needs a lot of cpu
  epstopdf $f
  mv ${f%eps}pdf $f.pdf

  # this uploads the file to a server and takes damn long
  any2djvu -a -c -q $f.pdf
  mv $f.djvu $f.pdf.djvu

  djvu2pdf $f.pdf.djvu
  mv $f.pdf.pdf $f.pdf.djvu.pdf
done

pdftk $name*.eps.pdf.djvu.pdf cat output $name.pdf


# or 
for f in $name*.eps; do
  epstopdf --filter < $f > $f.pdf
done
pdftk $name*.eps.pdf cat output $name.eps.pdf
any2djvu -acq $name.eps.pdf
mv $name.eps.djvu $name.eps.pdf.djvu
djvu2pdf $name.eps.pdf.djvu
mv $name.eps.pdf.pdf $name.pdf
