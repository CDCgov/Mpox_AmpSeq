#!/bin/bash

# Script assumes you are in the pipeline output directory

# Directories
DEPTH_DIR="./samtools/depth"
FLAGSTAT_DIR="./samtools/flagstat" # Corrected path
STATS_DIR="./samtools/stats"
NEXTCLADE_DIR="./nextclade/run" # Directory for Nextclade outputs
OUTPUT_DIR="./summary_stats"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Output table file
TABLE_FILE="$OUTPUT_DIR/summary_table.tsv"

# Add table headers (including Nextclade Deletions and AA Deletions)
echo -e "Sample Name\tTotal Reads\tMapped Reads\tAverage Coverage\tAverage Read Length\tNextclade Nuc Subs\tNextclade AA Subs\tNextclade Deletions\tNextclade AA Deletions\tClade\tCoverage\tCoverage Mutation" > "$TABLE_FILE"

echo "Processing samples for summary statistics..."

for DEPTH_FILE in "$DEPTH_DIR"/*.tsv; do
    if [[ -f "$DEPTH_FILE" ]]; then
        # Extract sample name from file name
        SAMPLE=$(basename "$DEPTH_FILE" .tsv)

        # Initialize variables for each sample
        TOTAL_DEPTH=0
        COUNT=0
        TOTAL_READS=0
        MAPPED_READS=0
        AVG_READ_LENGTH=0
        COVERAGE_MUTATION=0 # This will be the total depth
        NEXTCLADE_NUC_SUBS="N/A"
        NEXTCLADE_AA_SUBS="N/A"
        NEXTCLADE_DELETIONS="N/A"   # New variable for Nextclade Deletions
        NEXTCLADE_AA_DELETIONS="N/A" # New variable for Nextclade AA Deletions
        CLADE="N/A"
        COVERAGE="N/A" # Nextclade's coverage value

        # Calculate average coverage from depth file
        TOTAL_DEPTH=$(awk '{sum+=$3} END {print sum}' "$DEPTH_FILE")
        COUNT=$(awk 'END {print NR}' "$DEPTH_FILE")
        if [[ "$COUNT" -gt 0 ]]; then
            AVG_COVERAGE=$(echo "scale=2; $TOTAL_DEPTH / $COUNT" | bc)
        else
            AVG_COVERAGE=0
        fi

        # Find corresponding flagstat file for total and mapped reads
        FLAGSTAT_FILE="$FLAGSTAT_DIR/$SAMPLE.flagstat"
        if [[ -f "$FLAGSTAT_FILE" ]]; then
            TOTAL_READS=$(grep ' in total (QC-passed reads + QC-failed reads)' "$FLAGSTAT_FILE" | awk '{print $1}')
            MAPPED_READS=$(grep ' mapped (' "$FLAGSTAT_FILE" | head -n 1 | awk '{print $1}')
        fi

        # Extract average read length from the existing stats file
        STATS_FILE="$STATS_DIR/$SAMPLE.stats"
        if [[ -f "$STATS_FILE" ]]; then
            AVG_READ_LENGTH=$(grep '^SN' "$STATS_FILE" | grep 'average length' | awk '{print $4}')
        fi

        # --- Nextclade data extraction ---
        NEXTCLADE_FILE="$NEXTCLADE_DIR/$SAMPLE.csv"
        if [[ -f "$NEXTCLADE_FILE" ]]; then
            # Read the second line (data row) from Nextclade CSV (semicolon-separated)
            NEXTCLADE_LINE=$(tail -n +2 "$NEXTCLADE_FILE" | head -n 1)
            if [[ -n "$NEXTCLADE_LINE" ]]; then
                # Extract requested fields using awk with semicolon as delimiter
                # Columns: substitutions (23), aaSubstitutions (27), deletions (24), aaDeletions (28), clade (3), coverage (21)
                NEXTCLADE_NUC_SUBS=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $23}')
                NEXTCLADE_AA_SUBS=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $27}')
                NEXTCLADE_DELETIONS=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $24}')   # Pulling deletions
                NEXTCLADE_AA_DELETIONS=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $28}') # Pulling aaDeletions
                CLADE=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $3}')
                COVERAGE=$(echo "$NEXTCLADE_LINE" | awk -F ";" '{print $21}')
            fi
            # If extracted fields are empty, set to N/A
            [[ -z "$NEXTCLADE_NUC_SUBS" ]] && NEXTCLADE_NUC_SUBS="N/A"
            [[ -z "$NEXTCLADE_AA_SUBS" ]] && NEXTCLADE_AA_SUBS="N/A"
            [[ -z "$NEXTCLADE_DELETIONS" ]] && NEXTCLADE_DELETIONS="N/A"
            [[ -z "$NEXTCLADE_AA_DELETIONS" ]] && NEXTCLADE_AA_DELETIONS="N/A"
            [[ -z "$CLADE" ]] && CLADE="N/A"
            [[ -z "$COVERAGE" ]] && COVERAGE="N/A"
        else
            # If Nextclade file not found, mark relevant fields
            NEXTCLADE_NUC_SUBS="No Nextclade file"
            NEXTCLADE_AA_SUBS="No Nextclade file"
            NEXTCLADE_DELETIONS="No Nextclade file"
            NEXTCLADE_AA_DELETIONS="No Nextclade file"
            CLADE="No Nextclade file"
            COVERAGE="No Nextclade file"
        fi

        # Coverage Mutation (total depth from depth file)
        COVERAGE_MUTATION=$(awk '{sum+=$3} END {print sum}' "$DEPTH_FILE")

        # Output the summary to a table
        echo -e "$SAMPLE\t$TOTAL_READS\t$MAPPED_READS\t$AVG_COVERAGE\t$AVG_READ_LENGTH\t$NEXTCLADE_NUC_SUBS\t$NEXTCLADE_AA_SUBS\t$NEXTCLADE_DELETIONS\t$NEXTCLADE_AA_DELETIONS\t$CLADE\t$COVERAGE\t$COVERAGE_MUTATION" >> "$TABLE_FILE"

        echo "Summary written to table for sample $SAMPLE"
    fi
done

echo "Summary table generation complete: $TABLE_FILE"