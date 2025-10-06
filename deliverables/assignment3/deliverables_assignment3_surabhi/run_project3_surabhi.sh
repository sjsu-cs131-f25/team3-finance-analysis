# Step 4. Top-30 tokens inside clusters
cut -f2 edges_thresholded.tsv | sort | uniq -c | sort -nr | head -30 > top30_clusters.txt
cut -f2 edges.tsv | sort | uniq -c | sort -nr | head -30 > top30_overall.txt
diff top30_clusters.txt top30_overall.txt > diff_top30.txt

#Step 5. Network visualization
#used scp to create a copy the the cluster_sizes.tsv and exported that to an excel file to get the graph 

#Step 6. Summary statistics about clusters
unzip -p ../../personal-finance-ml-dataset.zip synthetic_personal_finance_dataset.csv | awk -F',' 'NR>1 {print $9 "\t" $7}' > savings_income.tsv

awk -F'\t' 'NR==FNR { m[$1]=$2; next } { if ($2 in m) print $1 "\t" m[$2] }' savings_income.tsv edges_thresholded.tsv > education_level_monthly_income.tsv

# datamash setup done here 

#sorting before using datamash
sort -k1,1 education_level_monthly_income.tsv > education_level_monthly_income_sorted.tsv

datamash -g 1 count 2 mean 2 median 2 < left_outcome.tsv > cluster_outcomes.tsv
datamash -g 1 count 2 mean 2 median 2 < left_outcome_sorted.tsv > cluster_outcomes.tsv

