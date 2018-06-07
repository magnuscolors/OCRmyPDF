#!/bin/bash
# 1. Watch WATCHED_DIR folder recursively.
# 2. in ocr_and_email_92.sh: OCR pdf-images to multipage pdf documents with tex$
#
#change the variable below with the folder you want this script to watch for ne$

. /appenv/bin/activate
cd /home/docker

WATCHED_DIR=/mnt/omp/pdf_in
export SHELL=/bin/bash
(echo start; inotifywait -mr -e create,moved_to "$WATCHED_DIR" --format "%w%f") |
while read event; do

                 oIFS=$IFS
                 IFS=$'\n'
                 find $WATCHED_DIR -iname *.pdf |
                 while read -r file; do
                        fileocr="${file/pdf_in/pdf_ocr}"
                        filedecrypt="${file/pdf_in/pdf_dec}"
                        filedecerror="${file/pdf_in/pdf_dec_error}"
                        fileorig="${file/pdf_in/pdf_orig}"
                        filename="`basename $file`"
                        shopt -s nocasematch
                        case "$filename" in
                        .*.pdf) rm "$file" && echo "$file" "deleted";;
                        *.pdf) ocrmypdf --deskew --force-ocr --output-type pdf -l "eng+nld" "$file" "$fileocr"
                        return_code=$?
                        if [ $return_code -eq 0 ]
                            then
                              echo "$file" "ocr-ed"
                        else
                            if [ $return_code -eq 8 ]
                                then
                                    echo "$file" "encrypted, decrypting" && \
                                qpdf --decrypt "$file" "$filedecrypt" && \
                                    echo "$file" "decrypted" || echo "$file" "not decrypted" && \
                                                                rm "$filedecrypt" && \
                                                                echo "$file" "deleted from pdf_dec" && \
                                                                mv "$file" "$filedecerror" && \
                                                                continue
                                ocrmypdf --deskew --force-ocr --output-type pdf -l "eng+nld" "$filedecrypt" "$fileocr" && \
                                    echo "$file" "ocr-ed" && \
                                rm "$filedecrypt" && \
                                    echo "$file" "deleted from pdf_dec"
                            fi
                        fi
                               mv "$file" "$fileorig" && \
                                    echo "$file" "moved to orig" ;;
                        *) mv "$file" "$fileorig" && echo "$file" "Oops" ;;
                        esac
                        shopt -u nocasematch
                 done
                 IFS=$oIFS
done