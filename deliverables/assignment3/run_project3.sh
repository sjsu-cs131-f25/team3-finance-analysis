#!/usr/bin/env bash
set -euo pipefail

# Assignment 3: Finding structure in large datasets

# Step 1. Define relationships

awk -F ',' 'NR>1 {print $4 "\t" $9}' personal-finance-ml-dataset.csv | sort > edges.tsv

# Step 2. Filter significant clusters

cut -f1 edges.tsv | sort | uniq -c | awk '{print $2 "\t" $1}' | sort -t$'\t' -k2,2nr > entity_counts.tsv

N=1000

awk -F'\t' -v N="$N" '$2>=N {print $1}' entity_counts.tsv > to_keep.txt

awk -F'\t' 'NR==FNR { keep[$1]=1; next } keep[$1]' to_keep.txt edges.tsv > edges_thresholded.tsv

# Step 3. Histogram of cluster sizes

cut -f1 edges_thresholded.tsv | sort | uniq -c | awk '{print $2 "\t" $1}' | sort -t$'\t' -k2,2nr > cluster_sizes.tsv
