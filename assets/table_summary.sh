#!/bin/bash

# Script assumes you are in the pipeline output directory

# Directories
DEPTH_DIR="./samtools/depth"
FLAGSTAT_DIR="./samtools/flagstat"
STATS_DIR="./samtools/stats" 
VARIANTS_DIR="./variants"
NEXTCLADE_DIR="./nextclade/run" # Directory for Nextclade outputs
OUTPUT_DIR="./summary_stats"

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Output table file
TABLE_FILE="$OUTPUT_DIR/summary_table.tsv"

# Add table headers
echo -e "Sample Name\tTotal Reads\tMapped Reads\tAverage Coverage\tAverage Read Length\tMutation Details\tClade\tCoverage\tCoverage Mutation" > $TABLE_FILE

# Calculate average coverage from samtools depth output and read counts from flagstat output
echo "Processing samples for summary statistics..."

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
        COVERAGE_MUTATION=0
        MUTATION_DETAILS=""
        CLADE="N/A"
        COVERAGE="N/A"

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
            AVG_READ_LENGTH=$(grep '^SN' $STATS_FILE | grep 'average length' | awk '{print $4}')
        fi

        # Extract mutation data from ivar variants file
        VARIANTS_FILE="$VARIANTS_DIR/$SAMPLE.tsv"
        if [[ -f $VARIANTS_FILE ]]; then
            while IFS=$'\t' read -r REGION POS REF ALT REF_DP REF_RV REF_QUAL ALT_DP ALT_RV ALT_QUAL ALT_FREQ TOTAL_DP PVAL PASS GFF_FEATURE REF_CODON REF_AA ALT_CODON ALT_AA POS_AA; do
                MUTATION_DETAILS+="\t$REF$POS$ALT\t$ALT_AA\t$ALT_FREQ\t$TOTAL_DP"
            done < <(awk '$4 !~ /[+-]/ || $11 > 0.5' "$VARIANTS_FILE" | sort -k11,11nr)
        else
            # If no ivar variants file, check for Nextclade output
            NEXTCLADE_FILE="$NEXTCLADE_DIR/$SAMPLE.csv"
            if [[ -f $NEXTCLADE_FILE ]]; then
                # Extract amino acid substitutions and deletions
                MUTATION_DETAILS=$(awk -F ";" 'NR==2 {print $28, $29}' "$NEXTCLADE_FILE" | tr ';' ', ')
                CLADE=$(awk -F ";" 'NR==2 {print $3}' "$NEXTCLADE_FILE") # Extract clade
                COVERAGE=$(awk -F ";" 'NR==2 {print $21}' "$NEXTCLADE_FILE") # Extract coverage
            else
                MUTATION_DETAILS="No mutation data available"
            fi
        fi

        # Extract coverage mutation data
        COVERAGE_MUTATION=$(awk '{sum+=$3} END {print sum}' $DEPTH_FILE)

        # Output the summary to a table
        echo -e "$SAMPLE\t$TOTAL_READS\t$MAPPED_READS\t$AVG_COVERAGE\t$AVG_READ_LENGTH\t$MUTATION_DETAILS\t$CLADE\t$COVERAGE\t$COVERAGE_MUTATION" >> $TABLE_FILE

        echo "Summary written to table for sample $SAMPLE"
    fi
done
