#!/bin/bash
OurPath="$(pwd)"
grep -q "[[:space:]]" <<<"${OurPath}" && { echo "\"${OurPath}\" contains whitespace." >&2 ; exit 1 ; }
echo "\"${OurPath}\" has no whitespace"

