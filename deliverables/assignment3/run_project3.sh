#!/usr/bin/env bash
# Assignment 3: Finding structure in large datasets

INPUT="/mnt/scratch/CS131_jelenag/projects/team03_sec3/avin/team3-finance-analysis/deliverables/assignment3/personal-finance-ml-dataset.zip"
chmod -R g+rX $INPUT

OUTPUT="./out"

mkdir -p "$OUTPUT"

N=2000

# Step 1. Define relationships
unzip -p $INPUT synthetic_personal_finance_dataset.csv | awk -F ',' 'NR>1 {print $4 "\t" $9}' | sort > "$OUTPUT/edges.tsv"

# Step 2. Filter significant clusters
cut -f1 "$OUTPUT/edges.tsv" | sort | uniq -c | awk '{count=$1; $1=""; sub(/^ /, ""); print $0 "\t" count}' | sort -t$'\t' -k2,2nr > "$OUTPUT/entity_counts.tsv"

awk -F'\t' -v N="$N" '$2>=N {print $1}' "$OUTPUT/entity_counts.tsv" > "$OUTPUT/to_keep.txt"

awk -F'\t' 'NR==FNR { keep[$1]=1; next } keep[$1]' "$OUTPUT/to_keep.txt" "$OUTPUT/edges.tsv" > "$OUTPUT/edges_thresholded.tsv"

# Step 3. Histogram of cluster sizes
cut -f1 "$OUTPUT/edges_thresholded.tsv" | sort | uniq -c | awk '{count=$1; $1=""; sub(/^ /,""); print $0 "\t" count}' | sort -t$'\t' -k2,2nr > "$OUTPUT/cluster_sizes.tsv"

# Step 4. Top-30 tokens inside clusters
cut -f2 "$OUTPUT/edges_thresholded.tsv" | sort | uniq -c | sort -nr | head -30 > "$OUTPUT/top30_clusters.txt"

cut -f2 "$OUTPUT/edges.tsv" | sort | uniq -c | sort -nr | head -30 > "$OUTPUT/top30_overall.txt"

diff "$OUTPUT/top30_clusters.txt" "$OUTPUT/top30_overall.txt" > "$OUTPUT/diff_top30.txt"

# Step 5. Network visualization
# used scp to create a copy the the cluster_sizes.tsv and exported that to an excel file to get the graph 

# Step 6. Summary statistics about clusters
unzip -p $INPUT synthetic_personal_finance_dataset.csv | awk -F',' 'NR>1 {print $9 "\t" $7}' > "$OUTPUT/savings_income.tsv"

awk -F'\t' 'NR==FNR { m[$1]=$2; next } { if ($2 in m) print $1 "\t" m[$2] }' "$OUTPUT/savings_income.tsv" "$OUTPUT/edges_thresholded.tsv" > "$OUTPUT/education_level_monthly_income.tsv"

# datamash setup done here 

# sorting before using datamash
sort -k1,1 "$OUTPUT/education_level_monthly_income.tsv" > "$OUTPUT/education_level_monthly_income_sorted.tsv"

source ~/.bashrc
which datamash
datamash -g 1 count 2 mean 2 median 2 < "$OUTPUT/education_level_monthly_income_sorted.tsv" > "$OUTPUT/cluster_outcomes.tsv"
