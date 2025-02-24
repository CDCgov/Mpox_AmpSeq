#!/bin/bash

echo "Ensure you currently are in the working directory where the merged files and samplesheet file will be saved. A directory will be created automatically to store all merged files."
echo ""
echo "Warning: Only use letters, numbers, underscores (_), and hyphens (-) for better compatibility with the workflow and to avoid unexpected crashes of the runs. Avoid the use of special characters (parenthesis, asterisks, etc.)."

read -p "Does your data contain any special characters? (y/n): " answer

if [ "$answer" == "n" ]; then
    echo "Running the script now..."

    # Prompt the user for the path to the data directory
    read -p "Please enter the path to the data directory (ending the path with a \"/\" symbol): " data_dir

    # Step 1: Create a 'data_output' folder in the current working directory
    output_dir="data_output"
    mkdir -p "$output_dir"
    current_dir=$(pwd)

    # Step 2: Loop through the 'data' directory to process already merged FASTQ files
    for fastq_file in "$data_dir"/*.fastq; do
        if [[ -f "$fastq_file" ]]; then
            fastq_name=$(basename "$fastq_file")
            sample_name="${fastq_name%.*}"

            # Creating a subdirectory inside 'data_output' for each sample
            mkdir -p "$output_dir/$sample_name"

            # Compress and rename the file to .fastq.gz
            gzip -c "$fastq_file" > "$output_dir/$sample_name/${sample_name}.fastq.gz"
            echo "Compressed and renamed $fastq_file to ${sample_name}.fastq.gz at $(date '+%Y-%m-%d %H:%M:%S')"
        fi
    done

    # Step 3: Create samplesheet.csv
    samplesheet="samplesheet.csv"
    printf "sample,fastq_1,fastq_2\n" > "$samplesheet"

    # Loop through the output directory to create the samplesheet
    for sample_dir in "$output_dir"/*; do
        if [[ -d "$sample_dir" ]]; then
            sample_name=$(basename "$sample_dir")
            sample_name_cl=$(basename "$sample_dir" | sed 's/-/_/g')
            fastq_gz_file="$current_dir/$sample_dir/${sample_name}.fastq.gz"

            # Append the sample name and the path to the fastq file to the CSV file
            if [[ -f "$fastq_gz_file" ]]; then
                printf "%s,%s,\n" "$sample_name_cl" "$fastq_gz_file" >> "$samplesheet"
            else
                echo "FASTQ file not found for $sample_name: $fastq_gz_file"
            fi
        fi
    done

    # Replace hyphens and parenthesis with underscores in only the first column (sample_name)
    sed -i 's/^\([^,]*\)[-()]/\1_/g; t; s/^\([^,]*\)[-()]/\1_/g' "$samplesheet" 

    echo "Samplesheet created: $samplesheet at $(date '+%Y-%m-%d %H:%M:%S')"

elif [ "$answer" == "y" ]; then
    echo "Aborting the script. Please remove any special characters from your file names before running."
else
    echo "Invalid input. Please enter 'y' or 'n'. Aborting the script."
fi
