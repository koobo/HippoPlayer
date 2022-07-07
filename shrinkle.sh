#!/bin/bash
if [ -z "$1" ]
  then
    echo "File missing!"
    exit 1
fi

BASE=`basename "$1"`
# -w: write header
# -p: no progress
# -d: data mode
# -9: max compress
shrinkler -w -p -d -9 "$1" "shr/$BASE.shr"

# Older shrinkler needed manual header:
#TMPFILE=`mktemp`
#
## Write file length as a 4 byte binary
#echo "00000000: `stat -f%8.8Xz \"$1"`" | xxd -r > "$1.shr"
#shrinkler -p -d -9 "$1" $TMPFILE
#cat $TMPFILE >> "$1.shr"
#rm $TMPFILE
#mkdir -p shr
#mv "$1.shr" shr/
#echo "Wrote shr/$1.shr"
