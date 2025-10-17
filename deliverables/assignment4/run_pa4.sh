#!/usr/bin/env bash
# Assignment 4: SED, AWK, Shell
set -euo pipefail

INPUT="/mnt/scratch/CS131_jelenag/projects/team03_sec3/avin/team3-finance-analysis/deliverables/assignment4/personal-finance-ml-dataset.zip"
OUTPUT="./out"
LOGS="logs"

chmod -R g+rX .
mkdir -p "$OUTPUT" "$LOGS"
unzip $INPUT
mv synthetic_personal_finance_dataset.csv dataset.csv

# 1: Clean & Normalize
head -n 15 dataset.csv > "$OUTPUT/before.csv"

sed -E '
  s/^[[space:]]+//;
  s/[[:space:]]+$//;
  s/[[:space:]]+/,/g;
  s/,([0-9]{3})(\b|[^0-9])/\1\2/g;
  s/\b([Nn][Aa]|[Nn][Uu][Ll][Ll]|none|NaN)\b/NA/g;
' "$OUTPUT/before.csv" > "$OUTPUT/after.csv"

# 2: Skinny tables & frequency tables

awk -F',' 'NR>1 && $3!="NA"{c[$3]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' dataset.csv | sort -t$',' -k3,2nr -k1,1 | { printf "gender,count\n"; cat; } > "$OUTPUT/freq_gender.csv"

awk -F',' 'NR>1 && $5!="NA"{c[$5]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' dataset.csv | sort -t$',' -k3,2nr -k1,1 | { printf "gender,count\n"; cat; } > "$OUTPUT/freq_employment.csv"

awk -F',' 'NR>1 && $6!="NA"{c[$6]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' dataset.csv | sort -t$',' -k2,2nr -k1,1 | { printf "job_title,count\n"; cat; } | head -n 5 > "$OUTPUT/top5_job_title.csv"

awk -F',' 'NR>1 { print $1","$2","$7","$8","$9","$10 }' dataset.csv | sort -t',' -k1,1 | { printf "user_id,age,monthly_income_usd,monthly_expenses_usd,savings_usd,has_loan\n"; cat; } > "$OUTPUT/skinny_users_finance.csv"
