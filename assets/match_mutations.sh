#!/bin/bash

# This script cross-references Nextclade AA Substitutions from the summary table
# against a provided mutation database.

# Directories and files
ASSETS_DIR="../../Mpox_AmpSeq/assets" # Path to your assets directory, modify as needed. Must run script within your output nextflow directory
SUMMARY_TABLE_FILE="./summary_stats/summary_table.tsv"
MUTATION_DB_FILE="$ASSETS_DIR/mutation_database.tsv"
OUTPUT_REPORT_FILE="./summary_stats/matched_mutations_report.tsv"

# Check if summary table exists
if [[ ! -f "$SUMMARY_TABLE_FILE" ]]; then
    echo "Error: Summary table not found at $SUMMARY_TABLE_FILE. Please run table_summary.sh first."
    exit 1
fi

# Check if mutation database exists
if [[ ! -f "$MUTATION_DB_FILE" ]]; then
    echo "Error: Mutation database not found at $MUTATION_DB_FILE. Please create it as specified."
    exit 1
fi

echo "Matching Nextclade AA Substitutions against mutation database..."

# Use awk to process both files
# FNR is current record number in current file
# NR is total record number across all files
# FS is field separator, OFS is output field separator
awk -F'\t' '
    BEGIN { OFS="\t" }

    # --- Part 1: Load Mutation Database ---
    # Process the mutation database file (first file provided)
    FILENAME == ARGV[1] {
        if (FNR == 1) { next } # Skip database header

        db_mutation = $1;
        db_aminoacid = $2;
        db_totalcount = $3;
        db_apobec = $4;

        # Ensure AminoAcid field is not empty and TotalCount is numeric
        if (db_aminoacid != "" && db_totalcount ~ /^[0-9]+$/) {
            # Store database entries, using AminoAcid as key.
            # If multiple DB entries map to the same AminoAcid, we store them all
            # as a semicolon-separated string for later iteration.
            # Using \x1e as an internal separator within each database entry.
            if (db_data[db_aminoacid] != "") {
                db_data[db_aminoacid] = db_data[db_aminoacid] ";" db_mutation "\x1e" db_totalcount "\x1e" db_apobec;
            } else {
                db_data[db_aminoacid] = db_mutation "\x1e" db_totalcount "\x1e" db_apobec;
            }
        }
        next # Move to the next line in the database file
    }

    # --- Part 2: Process Summary Table ---
    # Process the summary table file (second file provided)
    FILENAME == ARGV[2] {
        if (FNR == 1) { # Summary table header
            # Find column index for "Nextclade AA Subs"
            for (i=1; i<=NF; i++) {
                if ($i == "Nextclade AA Subs") {
                    aa_subs_col = i;
                    break;
                }
            }
            if (!aa_subs_col) {
                print "Error: '\''Nextclade AA Subs'\'' column not found in summary table." > "/dev/stderr";
                exit 1;
            }
            # Print header for the output report
            print "Sample Name\tNextclade_AA_Sub\tDB_Mutation\tDB_AminoAcid\tDB_TotalCount\tDB_APOBEC3_Context";
            next;
        }

        sample_name = $1;
        nextclade_aa_subs_str = $(aa_subs_col);

        # Handle N/A or empty Nextclade AA Subs
        if (nextclade_aa_subs_str == "N/A" || nextclade_aa_subs_str == "No Nextclade file" || nextclade_aa_subs_str == "") {
            next; # Skip if no AA substitutions are reported
        }

        # Split Nextclade AA Subs string by comma (e.g., "OPG057:E353K,OPG057:I372N")
        num_nextclade_subs = split(nextclade_aa_subs_str, nextclade_aa_subs_arr, ",");

        for (i=1; i<=num_nextclade_subs; i++) {
            current_nextclade_aa_full = nextclade_aa_subs_arr[i];

            # Extract only the AA_CHANGE part (e.g., "E353K" from "OPG057:E353K")
            current_nextclade_aa_change = current_nextclade_aa_full; # Default to full string
            if (current_nextclade_aa_full ~ /:/) {
                split(current_nextclade_aa_full, parts, ":");
                current_nextclade_aa_change = parts[2];
            }

            # Lookup the extracted AA change in the database
            if (current_nextclade_aa_change in db_data) {
                # Iterate through all potential matches if multiple database entries exist for one AminoAcid
                num_db_matches = split(db_data[current_nextclade_aa_change], db_match_arr, ";");

                for (j=1; j<=num_db_matches; j++) {
                    # Split the internal string of database fields
                    split(db_match_arr[j], db_fields, "\x1e");
                    db_mutation = db_fields[1];
                    db_totalcount = db_fields[2];
                    db_apobec = db_fields[3];

                    # Output the matched information for this sample
                    print sample_name "\t" current_nextclade_aa_full "\t" db_mutation "\t" current_nextclade_aa_change "\t" db_totalcount "\t" db_apobec;
                }
            }
        }
    }
' "$MUTATION_DB_FILE" "$SUMMARY_TABLE_FILE" > "$OUTPUT_REPORT_FILE"

echo "Matched mutations report generated: $OUTPUT_REPORT_FILE"