#!/usr/bin/env bash

# Assignment 3: Finding structure in large datasets

# Step 1. Define relationships
unzip -p personal-finance-ml-dataset.zip synthetic_personal_finance_dataset.csv | awk -F ',' 'NR>1 {print $4 "\t" $9}' | sort > edges.tsv

# Step 2. Filter significant clusters
cut -f1 edges.tsv | sort | uniq -c | awk '{count=$1; $1=""; sub(/^ /, ""); print $0 "\t" count}' | sort -t$'\t' -k2,2nr > entity_counts.tsv

N=2000

awk -F'\t' -v N="$N" '$2>=N {print $1}' entity_counts.tsv > to_keep.txt

awk -F'\t' 'NR==FNR { keep[$1]=1; next } keep[$1]' to_keep.txt edges.tsv > edges_thresholded.tsv

# Step 3. Histogram of cluster sizes
cut -f1 edges_thresholded.tsv | sort | uniq -c | awk '{count=$1; $1=""; sub(/^ /,""); print $0 "\t" count}' | sort -t$'\t' -k2,2nr > cluster_sizes.tsv

# Step 4. Top-30 tokens inside clusters
cut -f2 edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 > top30_clusters.txt

cut -f2 edges.tsv | sort | uniq -c | sort -nr | head -30 > top30_overall.txt
diff top30_clusters.txt top30_overall.txt > diff_top30.txt

# Step 5. Network visualization
# used scp to create a copy the the cluster_sizes.tsv and exported that to an excel file to get the graph 

# Step 6. Summary statistics about clusters
unzip -p personal-finance-ml-dataset.zip synthetic_personal_finance_dataset.csv | awk -F',' 'NR>1 {print $9 "\t" $7}' > savings_income.tsv

awk -F'\t' 'NR==FNR { m[$1]=$2; next } { if ($2 in m) print $1 "\t" m[$2] }' savings_income.tsv edges_thresholded.tsv > education_level_monthly_income.tsv

# datamash setup done here 

# sorting before using datamash
sort -k1,1 education_level_monthly_income.tsv > education_level_monthly_income_sorted.tsv

source ~/.bashrc
which datamash
datamash -g 1 count 2 mean 2 median 2 < education_level_monthly_income_sorted.tsv > cluster_outcomes.tsv
