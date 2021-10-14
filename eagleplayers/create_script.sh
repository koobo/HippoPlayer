#!/bin/bash
find . -type f -exec echo "fimp \"{}\" \"{}.im\" -m8" \; | sed 's/\.\///g'
