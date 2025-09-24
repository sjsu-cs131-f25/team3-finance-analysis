#!/usr/bin/bash
#Sample data path is /mnt/scratch/CS131_jelenag/projects/team03_sec3/surabhi/data/samples/sample_1k.txt
#Delimiter is comma ‘,’ 
#One assumption which was made in the command dealing with the top table. We did not exclude the header line because we were sure that would not show up in the output. The skinny table was also sampled to show the top twenty lines only 
mkdir -p data/samples
unzip -p personal-finance-ml-dataset.zip | head -n 1 > data/samples/sample_1k.txt
unzip -p personal-finance-ml-dataset.zip | tail -n +2 | shuf -n 1000 >> data/samples/sample_1k.txt
mkdir -p out
unzip -p personal-finance-ml-dataset.zip | tail -n +2 | cut -d',' -f3 | sort | uniq -c | sort -nr 2>&1 | tee out/freq_gender.txt
unzip -p personal-finance-ml-dataset.zip | tail -n +2 | cut -d',' -f5 | sort | uniq -c | sort -nr 2>&1 | tee out/freq_employment.txt
unzip -p personal-finance-ml-dataset.zip | cut -d',' -f2 | sort | uniq -c | sort -nr | head -n 10 | tee out/top_age.txt
unzip -p personal-finance-ml-dataset.zip | tail -n +2 | cut -d',' -f2,3,5 | sort -u 2>&1 | head -20 | tee out/skinny_table.txt
unzip -p personal-finance-ml-dataset.zip | grep -i "failed" > out/failed_records.txt
unzip -p personal-finance-ml-dataset.zip | grep -v "completed" > out/not_completed.txt
unzip -p personal-finance-ml-dataset.zip | grep -i "19"| wc -l > out/results.txt 2> out/error.txt
exit

