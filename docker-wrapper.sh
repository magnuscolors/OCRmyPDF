#!/bin/bash
# 1. Watch WATCHED_DIR folder recursively.
# 2. in ocr_and_email_92.sh: OCR pdf-images to multipage pdf documents with tex$
#
#change the variable below with the folder you want this script to watch for ne$

. /appenv/bin/activate
cd /home/docker

WATCHED_DIR=/mnt/omp/pdf_in
export SHELL=/bin/bash
OCRmyPDF=/opt/bin/ocrmypdf.sh

(echo start; inotifywait -mr -e create,moved_to "$WATCHED_DIR" --format "%w%f") |
while read event; do

                 oIFS=$IFS
                 IFS=$'\n'
                 shopt -s nocasematch
                 find $WATCHED_DIR -iname *.pdf |
                 while read -r file; do
                        fileocr="${file/pdf_in/pdf_ocr}"
                        filedecrypt="${file/pdf_in/pdf_dec}"
                        fileorig="${file/pdf_in/pdf_orig}"
                        filename="`basename $file`"
                        case "$filename" in
                        .*.pdf) rm "$file" && echo "$file" "deleted";;
                        *.pdf) qpdf --decrypt "$file" "$filedecrypt" && \
                               ocrmypdf --deskew --force-ocr -l "eng+nld" "$filedecrypt" "$fileocr" && \
                               mv "$file" "$fileorig" && \
                               rm "$filedecrypt" && \
                               echo "$filename" "OCR-ed";;
                        *) mv "$file" "$fileorig" && echo "$file" "Oops" ;;
                        esac
                 done
                 shopt -u nocasematch
                 IFS=$oIFS
done
