**General disclaimer** This repository was created for use by CDC programs to collaborate on public health related projects in support of the [CDC mission](https://www.cdc.gov/about/divisions-offices/index.html).  GitHub is not hosted by the CDC, but is a third party website used by CDC and its partners to share information and collaborate on software. CDC use of GitHub does not imply an endorsement of any one particular service, product, or enterprise. 

## Privacy Standard Notice
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](DISCLAIMER.md)
and [Code of Conduct](code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

Full disclaimer can be found at the end of this file.


[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/Mpox_AmpSeq)

## Introduction

**Mpox_AmpSeq** is a bioinformatics analysis [`nf-core`](https://nf-co.re/) style pipeline designed for F13L amplicon sequencing of mpox. The versatile tool generates reference-assisted consensus sequences, sequencing statistics, comprehensive ['NextClade'](https://github.com/nextstrain/nextclade) outputs, including clade identification and relevant variant information., and multiple quality control metrics. Below is a schematic representation of the key processes involved: 

<!-- Include the pipeline visualization graphic here -->
![Pipeline Visualization](/assets/visualization.svg)

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

General Pipeline Steps:
1. Read QC via [`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).
2. Trim primers with ['SEQTK'](https://github.com/lh3/seqtk).
3. Trim and filter raw reads with ['TRIMMOMATIC'](https://github.com/usadellab/Trimmomatic).
4. Map raw reads to reference using ['Minimap2'](https://github.com/lh3/minimap2) to generate a reference-based consensus with ['IVAR consensus'](https://github.com/andersen-lab/ivar).  
5. Generate alignment files and coverage information with ['SAMTOOLS'](https://github.com/samtools/samtools). 
6. Optional: Polish ['IVAR consensus'](https://github.com/andersen-lab/ivar) with ['MEDAKA'](https://github.com/nanoporetech/medaka). 
7. Optional: Generate a variant table with ['IVAR variants'](https://github.com/andersen-lab/ivar).
8. Generate clade assignment, variant information, phylogenetic placement, and additional quality control statistics with ['NextClade'](https://github.com/nextstrain/nextclade).
2. Generate QC for raw reads [`MultiQC`](http://multiqc.info/).

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

Repository can be cloned using `git clone`.

	git clone https://github.com/CDCgov/Mpox_AmpSeq.git 


 Prepare a samplesheet with your input data containing single-end ONT fastq files:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
SAMPLE_NAME_1,RANDOM_NAME_S1_L002_R1_001.fastq.gz,
```
A script is available to concatenate barcoded FASTQ files in a directory and generate a samplesheet in the required input format. You can find this script in `/assets/ont_fastq_concat_and_samplesheet_create.sh`. Ensure you’re in the working directory where you’d like the files merged and saved, as the script will automatically create a directory to store the resulting files, placing the samplesheet file in the same directory. Make sure to enter the path to the directory with the FASTQ files, ending with a "/" symbol.

If your FASTQ files are already concatenated by barcode, you can generate only the samplesheet by running `/assets/create_samplesheet_only.sh`. Enter the path to the directory with concatenated FASTQ files, ending with a "/", and ensure you are in the working directory where you want to save the samplesheet.

>[!WARNING]
Avoid using special characters (parentheses, commas, asterisks, hashes, etc.) in FASTQ file names. Only use letters, numbers, underscores (_), and hyphens (-) for better compatibility with the workflow and to avoid unexpected crashes of the runs.


Now, you can run the pipeline using:


```bash
nextflow run nf-core/Mpox_AmpSeq \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --resume <#if applicable> \
   --fasta <reference_fasta_path> \
   --bed_file <bed_path> \
   --fai_file <fai_path> \
   --gff_file <gff_path> \
   --mmi_file <mmi_path> \
   --nextclade_dataset_name 'nextstrain/mpox/all-clades'
```

Reference MT903344.1 is provided in `/assets/genome/`.

> [!WARNING]
> NextClade clade and lineage assignments may vary in accuracy when compared to whole-genome sequencing. The target region alone does not provide sufficient resolution to reliably differentiate clades and lineages.


An additional script `/assets/table_summary.sh` can be ran in the Nextflow output directory to generate a comprehensive summary table of sequencing metrics and mutations. The script integrates outputs from ['SAMTOOLS'](https://github.com/samtools/samtools), ['NextClade'](https://github.com/nextstrain/nextclade), and ['IVAR variants'](https://github.com/andersen-lab/ivar), if available, to output a table with read statistics (total reads, mapped reads, average coverage, and average read length) and mutations (amino acid substitutions and indels) per sample. Final table is output in `/summary_stats` directory.
Please note, clade assignments might not be fully accurate as the targetted amplicon region does not provide complete genomic information. 

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/TPOXX_AmpSeq/usage) and the [parameter documentation](https://nf-co.re/TPOXX_AmpSeq/parameters).


## Credits

Mpox_AmpSeq was originally written by Daisy McGrath.

We thank the following people for their extensive assistance in the development of this pipeline:

1. Crystal Gigante, PhD
2. Luis Haddock, PhD


## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

# CDCgov GitHub Organization Open Source Project 

**General disclaimer** This repository was created for use by CDC programs to collaborate on public health related projects in support of the [CDC mission](https://www.cdc.gov/about/divisions-offices/index.html). GitHub is not hosted by the CDC, but is a third party website used by CDC and its partners to share information and collaborate on software. CDC use of GitHub does not imply an endorsement of any one particular service, product, or enterprise. 

## Access Request, Repo Creation Request

* [CDC GitHub Open Project Request Form](https://forms.office.com/Pages/ResponsePage.aspx?id=aQjnnNtg_USr6NJ2cHf8j44WSiOI6uNOvdWse4I-C2NUNk43NzMwODJTRzA4NFpCUk1RRU83RTFNVi4u) _[Requires a CDC Office365 login, if you do not have a CDC Office365 please ask a friend who does to submit the request on your behalf. If you're looking for access to the CDCEnt private organization, please use the [GitHub Enterprise Cloud Access Request form](https://forms.office.com/Pages/ResponsePage.aspx?id=aQjnnNtg_USr6NJ2cHf8j44WSiOI6uNOvdWse4I-C2NUQjVJVDlKS1c0SlhQSUxLNVBaOEZCNUczVS4u).]_

## Related documents

* [Open Practices](open_practices.md)
* [Rules of Behavior](rules_of_behavior.md)
* [Thanks and Acknowledgements](thanks.md)
* [Disclaimer](DISCLAIMER.md)
* [Contribution Notice](CONTRIBUTING.md)
* [Code of Conduct](code-of-conduct.md)

## Overview

This NextFlow pipeline was designed to generate and analyze consensus sequences of two targetted amplicon regions. Each region correlates to primers designed to differentiate mpox clade designations. This analysis gives an alternate to whole genome sequencing while maintaining a high level of confidence to efficient clade assignment. 
 
## Public Domain Standard Notice
This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is in
the public domain within the United States, and copyright and related rights in
the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License Standard Notice
The repository utilizes code licensed under the terms of the Apache Software
License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under
the terms of the Apache Software License version 2, or (at your option) any
later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy Standard Notice
This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](DISCLAIMER.md)
and [Code of Conduct](code-of-conduct.md).
For more information about CDC's privacy policy, please visit [http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

## Contributing Standard Notice
Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo)
and submitting a pull request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records Management Standard Notice
This repository is not a source of government records, but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).

## Additional Standard Notices
Please refer to [CDC's Template Repository](https://github.com/CDCgov/template) for more information about [contributing to this repository](https://github.com/CDCgov/template/blob/main/CONTRIBUTING.md), [public domain notices and disclaimers](https://github.com/CDCgov/template/blob/main/DISCLAIMER.md), and [code of conduct](https://github.com/CDCgov/template/blob/main/code-of-conduct.md).