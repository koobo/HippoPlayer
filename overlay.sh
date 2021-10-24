#!/bin/bash
if [ -z "$1" ]
  then
    echo "File missing!"
    exit 1
fi

OUT=$1.ovl

# Hex dump, remove line changes

# Look for: ........00003e9........4efa........abcd
# - last hunk length
# - HUNK_CODE ($3f9)
# - jmp x(pc) instruction
# - overlay magic marker "abcd"
# Clear last hunk length, this is to be the overlay hunk

# Look for: 000003ea00000002000003f64b2d502
# - HUNK_DATA ($3ea)
# - hunk length
# - HUNK_STOP ($3f6)
# - "K-P!"
# Replace HUNK_DATA with HUNK_OVERLAY ($3f5), converting the last hunk
# Replace hunk length with zero

xxd -p < $1 | tr -d '\n' | sed 's/........000003e9/00000000000003e9/' |  sed 's/000003ea........000003f64b2d502/000003f500000000000003f64b2d502/' |  xxd -r -p > $OUT
echo "Wrote $OUT"