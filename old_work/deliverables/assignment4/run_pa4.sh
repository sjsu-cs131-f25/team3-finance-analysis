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

awk -F',' 'NR>1 && $5!="NA"{c[$5]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' dataset.csv | sort -t$',' -k3,2nr -k1,1 | { printf "employment_status,count\n"; cat; } > "$OUTPUT/freq_employment.csv"

awk -F',' 'NR>1 && $6!="NA"{c[$6]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' dataset.csv | sort -t$',' -k2,2nr -k1,1 | { printf "job_title,count\n"; cat; } | head -n 6 > "$OUTPUT/top5_job_title.csv"

awk -F',' 'NR>1 { print $1","$2","$7","$8","$9","$10 }' dataset.csv | sort -t',' -k1,1 | { printf "user_id,age,monthly_income_usd,monthly_expenses_usd,savings_usd,has_loan\n"; cat; } > "$OUTPUT/skinny_users_finance.csv"

awk -F',' 'NR==1 || ($1!="" && $1!="NA" && $2!="NA" && $2+0>=18 && $2+0<=70)' dataset.csv > "$OUTPUT/filtered_age18_70.csv"

# 4: Ratios, Buckets and Per-Entity Summaries

awk -F',' 'NR==1 {next}
{
  income = $7 + 0
  savings = $9 + 0
  ratio = (income > 0 ? savings / income : 0)
  if (ratio > 0.5) bucket="HI"
  else if (ratio >= 0.2) bucket="MID"
  else if (ratio > 0) bucket="LO"
  else bucket="ZERO"
  printf "%s,%.2f,%s\n",$1,ratio,bucket
}
' dataset.csv \
| { printf "user_id,savings_ratio,bucket\n"; cat; } > "$OUTPUT/savings_ratio_bucket.csv"

awk -F',' 'NR>1 {count[$3]++} END {
  printf "bucket,count\n"
  for (b in count) printf "%s,%d\n",b,count[b]
}' "$OUTPUT/savings_ratio_bucket.csv" \
|sort -t',' -k2,2nr -k1,1 > "$OUTPUT/bucket_summary.csv"

awk -F',' 'NR>1 {sum[$3]+=$2; count[$3]++}
END {
  printf "bucket,avg_ratio\n"
  for (b in sum) if (count[b]>0)
  printf "%s,%.3f\n",b,sum[b]/count[b]
}' "$OUTPUT/savings_ratio_bucket.csv" \
| sort -t',' -k2,2nr > "$OUTPUT/avg_ratio_per_bucket.csv"

awk -F',' 'NR>1 {user[$1]=$2; b[$1]=$3}
END {
  printf "user_id,ratio,bucket\n"
  for (u in user) printf "%s,%.2f,%s\n",u,user[u],b[u]
}' "$OUTPUT/savings_ratio_bucket.csv" \
| sort -t',' -k1,1 > "$OUTPUT/per_user_summary.csv"

#5: String Structure Analysis

awk -F',' 'NR>1 && $6!="NA"{
  t=tolower($6);
  len=length(t);
  if(len<10) bucket="short";
  else if(len<=20) bucket="medium";
  else bucket="long";
  sub(/ manager| analyst| engineer| specialist| director| assistant/,"",t);
  clean[t]++;
  lenbucket[bucket]++;
}
END{
  printf "normalized_job_root,count\n";
  for(k in clean) printf "%s,%d\n",k,clean[k];
}' dataset.csv | sort -t',' -k2,2nr > "$OUTPUT/job_root_freq.csv"

awk -F',' 'NR>1 && $6!="NA"{
  len=length($6);
  if(len<10) bucket="short";
  else if(len<=20) bucket="medium";
  else bucket="long";
  count[bucket]++;
}
END{
  printf "length_bucket,count\n";
  for(b in count) printf "%s,%d\n",b,count[b];
}' dataset.csv | sort -t',' -k2,2nr > "$OUTPUT/job_title_length_buckets.csv"

#6: Signal Discovery

awk -F',' 'NR>1 && $5!="NA" && $7>0 && $9!="NA" {
  income=$7+0; savings=$9+0; ratio=savings/income;
    sum[$5]+=ratio; count[$5]++; }
END{
  printf "employment_type,avg_savings_ratio\n";
  for(e in sum) if(count[e]>0)
    printf "%s,%.3f\n",e,sum[e]/count[e];
}' dataset.csv | sort -t',' -k2,2nr > "$OUTPUT/signal_avg_savings_by_employment.csv"

awk -F',' 'NR>1 && $7!="NA"{sum+=$7;sum2+=$7*$7;count++}
END{
  mean=sum/count; sd=sqrt(sum2/count - mean*mean);
  print mean > "logs/mean.txt"; print sd > "logs/sd.txt";
  printf "mean=%.2f sd=%.2f\n",mean,sd > "logs/income_stats.log";
}' dataset.csv

mean=$(awk '{print $1}' logs/mean.txt)
sd=$(awk '{print $1}' logs/sd.txt)

awk -v m="$mean" -v s="$sd" -F',' 'NR>1 && $7!="NA" {
  z=($7-m)/s; flag=(z>2?"OUTLIER":"NORMAL");
    printf "%s,%.2f,%s\n",$1,z,flag;
}' dataset.csv | { printf "user_id,zscore_income,flag\n"; cat; } > "$OUTPUT/income_outliers.csv"



