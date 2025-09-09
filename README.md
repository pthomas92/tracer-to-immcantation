# Running TraCeR and Immcantation on scRNA-seq Data

## About

This repository provides instructions for running the TCR annotation pipeline using **[TraCeR](https://github.com/Teichlab/tracer)** followed by **[Immcantation](https://immcantation.readthedocs.io/en/stable/)** (specifically ChangeO).  

The workflow reconstructs TCR sequences from single-cell RNA sequencing (scRNA-seq) data and performs downstream annotations using **IgBLAST**, enabling extraction of **CDR3B amino acid sequences** for further analysis such as metaclonotyping.  

The repository is configured for use on the **UCL Myriad HPC cluster** with **SGE array jobs**.

---

## References

- **TraCeR**
  - Source: https://github.com/Teichlab/tracer/tree/master  
  - Citation: [Nature Methods 2016](https://www.nature.com/articles/nmeth.3800)  

- **Immcantation (ChangeO)**
  - Source: https://immcantation.readthedocs.io/en/stable/  
  - Citation: [Gupta et al. 2015](https://pubmed.ncbi.nlm.nih.gov/26069265/)  

---

## Requirements

- **TraCeR Docker image**: https://hub.docker.com/r/teichlab/tracer/  
- **Immcantation Docker image**: https://hub.docker.com/r/immcantation/suite  
  - Example (Singularity build):
    ```bash
    # Pull release version 4.6.0
    IMAGE="immcantation_suite-4.6.0.sif"
    singularity build $IMAGE docker://immcantation/suite:4.6.0
    ```
- **Linux operating system** (tested on UCL Myriad)  
- **Python 3.9.10** with:
  - pandas 1.4  
  - numpy 1.21.5  

---

## Repository Setup

Run `setup_script.sh` to create and move the repository files into the required locations.  
Before running, ensure the following directories exist:

### Directory structure

- `fastqs/` — contains raw FASTQ files for processing.  
  - Naming convention (unless regexes in `tracer-array.sh` are modified):  
    ```
    <DONOR_ID>_<PLATE>_<WELL>_<REMAINING_IDENTIFIERS>.fastq.gz
    ```
    - `CELL_NAME` is derived as `<DONOR_ID>_<PLATE>_<WELL>`.
- `tracer_out/` — initially empty, stores TraCeR outputs.  
- `jobscripts/` — initially empty, stores array job scripts (useful for debugging).  
- `logs/` — initially empty, stores log files.  

### Provided scripts and files

- **array-params-complete.txt**  
  Tab-delimited file with 3 fields describing files to process:  
  1. Row index (for logging, not read by scripts)  
  2. Read 1 file name  
  3. Read 2 file name  

- **tracer-array.sh** — Runs TraCeR using an SGE array job.  
- **changeo_igblast.sh** — Runs ChangeO on TraCeR FASTA outputs.  
- **findcompletedjobs.sh** — Identifies completed jobs with specific exit codes (useful for finding OOM errors).  
- **geterror137jobs.sh** — Rebuilds a new `array-params-complete.txt` file containing only OOM-failed jobs for resubmission.  
- **processDB.py** — Annotates and summarizes `tracer_out` results.  
  - Requires setting the default path with `-p/--path`.  
- **tracerconfig.conf** — Example configuration file for TraCeR with file paths enabled.  
- **TRD.fasta**, **TRJ.fasta**, **TRV.fasta** — IMGT germline D, J, and V gene annotations.  

---

## Workflow Instructions

### 1. Prepare containers
Download Docker/Singularity containers as described in the official TraCeR and Immcantation documentation.

---

### 2. Set up job parameters
Create/modify `array-params-complete.txt`.  
Ensure all FASTQ files are in the `fastqs/` folder.  

---

### 3. Run TraCeR
Submit the array job with:

```bash
qsub -t <ARRAY_RANGE> -N <RUN_NAME> tracer-array.sh
```

- Output: results saved in `tracer_out/`  
- Each cell receives its own folder, even if no TCR is identified.  
- Relevant output folders for downstream analysis:
  - `filtered_TCR_seqs/`  
  - `expression_quantification/`  

---

### 4. Run Immcantation (ChangeO)
Execute:

```bash
./changeo_igblast.sh
```

- Typically very fast due to small input files.  
- Queries: `<CELL_NAME>/filtered_TCR_seqs/<CELL_NAME>_TCRseqs.fa`  
- Creates a new `igblast/` subfolder within each cell’s `filtered_TCR_seqs/`.  

**Outputs:**
- `<CELL_NAME>_igblast.fmt7` — raw IgBLAST output (used by ChangeO).  
- `<CELL_NAME>_igblast_db-pass.tsv` — database built from IgBLAST (≤2 entries per chain).  

---

### 5. Process results
Run:

```bash
processDB.py
```

- **Input:** `<CELL_NAME>_igblast_db-pass.tsv`  
- **Outputs:**  
  - `<CELL_NAME>_igblast_processed.tsv` — slimmed file with donor info and TPM per sequence.  
    - Manual handling required for cases with 2 productive TCRs (assigning a dominant sequence using TPM column during your downstream data analysis pipeline).
  - Per-cell summary file (similar to `tracer summarise`), containing:  
    - Dominant productive/unproductive TCR identifiers  
    - CDR3A/B amino acid sequences  

These summary files can be concatenated with `pandas` or `bash` for downstream analysis.

---

## Troubleshooting

- **Out-of-memory (OOM) errors**  
  - Use `findcompletedjobs.sh` to identify failed jobs (exit code 137).  
  - Create a new array-params-complete file using `geterror137jobs.sh`.  

- **Running ChangeO on login node**  
  - Works due to small input size, but avoid on shared systems — request a lightweight interactive job instead.  

---
