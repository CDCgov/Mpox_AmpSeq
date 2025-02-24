#!/bin/bash

# Directories
DEPTH_DIR="./samtools/depth"
FLAGSTAT_DIR="./samtools"
BAM_DIR="./samtools/sort"
OUTPUT_DIR="./samtools/summary_stats"
STATS_DIR="./samtools/stats" # Directory containing existing stats files

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Calculate average coverage from samtools depth output and read counts from flagstat output
echo "Calculating average coverage, extracting read counts, and read lengths..."

for DEPTH_FILE in $DEPTH_DIR/*.tsv; do
    if [[ -f $DEPTH_FILE ]]; then
        # Extract sample name from file name
        SAMPLE=$(basename $DEPTH_FILE .tsv)
        
        # Initialize variables
        TOTAL_DEPTH=0
        COUNT=0
        TOTAL_READS=0
        MAPPED_READS=0
        AVG_READ_LENGTH=0
        MAX_READ_LENGTH=0
        AVERAGE_QUALITY=0
        TOTAL_SEQUENCES=0

        # Calculate average coverage
        TOTAL_DEPTH=$(awk '{sum+=$3} END {print sum}' $DEPTH_FILE)
        COUNT=$(awk 'END {print NR}' $DEPTH_FILE)
        if [[ $COUNT -gt 0 ]]; then
            AVG_COVERAGE=$(echo "scale=2; $TOTAL_DEPTH / $COUNT" | bc)
        else
            AVG_COVERAGE=0
        fi

        # Find corresponding flagstat file
        FLAGSTAT_FILE="$FLAGSTAT_DIR/$SAMPLE.flagstat"
        if [[ -f $FLAGSTAT_FILE ]]; then
            TOTAL_READS=$(grep ' in total (QC-passed reads + QC-failed reads)' $FLAGSTAT_FILE | awk '{print $1}')
            MAPPED_READS=$(grep ' mapped (' $FLAGSTAT_FILE | head -n 1 | awk '{print $1}')
        fi

        # Extract statistics from the existing stats file
        STATS_FILE="$STATS_DIR/$SAMPLE.stats"
        if [[ -f $STATS_FILE ]]; then
            TOTAL_SEQUENCES=$(grep '^SN' $STATS_FILE | grep 'sequences:' | awk '{print $3}')
            TOTAL_BASES=$(grep '^SN' $STATS_FILE | grep 'total length' | awk '{print $4}')
            AVG_READ_LENGTH=$(grep '^SN' $STATS_FILE | grep 'average length' | awk '{print $4}')
            MAX_READ_LENGTH=$(grep '^SN' $STATS_FILE | grep 'maximum length' | awk '{print $4}')
            AVERAGE_QUALITY=$(grep '^SN' $STATS_FILE | grep 'average quality' | awk '{print $4}')
        fi

        # Output the summary to a file named after the sample
        OUTPUT_FILE="$OUTPUT_DIR/${SAMPLE}_coverage_summary.txt"
        {
            echo "Sample: $SAMPLE Coverage Summary"
            echo "========================"
            echo "Total Reads: $TOTAL_READS"
            echo "Mapped Reads: $MAPPED_READS"
            echo "Average Coverage: $AVG_COVERAGE"
            echo "Total Sequences: $TOTAL_SEQUENCES"
            echo "Total Bases: $TOTAL_BASES"
            echo "Average Read Length: $AVG_READ_LENGTH"
            echo "Maximum Read Length: $MAX_READ_LENGTH"
            echo "Average Quality: $AVERAGE_QUALITY"
        } > $OUTPUT_FILE

        echo "Summary written to $OUTPUT_FILE for sample $SAMPLE"
    fi
done
