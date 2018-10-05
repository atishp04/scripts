#!/bin/bash

pcount="$1"
subpfix=$2
output=$3
cpatch='git format-patch'
cpatch_sub='--subject-prefix '
cpatch_cover='--cover-letter -M -o'
create_patch_cmd="$cpatch -$pcount $cpatch_sub '$subpfix' $cpatch_cover $output"
eval $create_patch_cmd
scripts/checkpatch.pl $output/*