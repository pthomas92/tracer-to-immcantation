# Running TraCeR and immcantation on scRNA-seq data

### About

Repository describes how to run the annotation pipeline TraCeR, followed by immcantation (specifically ChangeO) to reconstruct TCR sequences from scRNA sequencing data, and perform the downstream annotations on the data using IgBLAST, as required to extract CDR3B amino acid sequences for further analysis such as metaclonotyping. Repository was created to run on the UCL Myriad HPC cluster, using array jobs on the SGE system.

__Tracer:__

* Source instructions: https://github.com/Teichlab/tracer/tree/master
* Citation: https://www.nature.com/articles/nmeth.3800

__Immcantation:__

* Source instructions: https://immcantation.readthedocs.io/en/stable/
* Citation (ChangeO): https://pubmed.ncbi.nlm.nih.gov/26069265/

### Requirements:
* TraCeR docker image (https://hub.docker.com/r/teichlab/tracer/)
* Immcantation docker image (https://hub.docker.com/r/immcantation/suite)
  * From https://immcantation.readthedocs.io/en/stable/docker/intro.html
    ```
    # Pull release version 4.6.0
    IMAGE="immcantation_suite-4.6.0.sif"
    singularity build $IMAGE docker://immcantation/suite:4.6.0
    ```
* Linux operating system (e.g., UCL Myriad)
* python3 (3.9.10)
  * pandas (1.4)
  * numpy (1.21.5)

### Repository setup:
Run ```setup_script.sh``` to create and move the repo files into the locations required for the script. Before running the script, the following directories should be in place:

#### Directories:
* fastqs: directory containing the fastqs for processing
  * data should be named like so, to fit with the script layout (unless the regexes are altered in tracer-array.sh):
    * ```<DONOR_ID>_<PLATE>_<WELL>_<REMAINING_IDENTIFIERS>.fastq.gz```
    * ```CELL_NAME``` will be set from the above value, taking ```<DONOR_ID>_<PLATE>_<WELL>``` for use in the script.
* tracer_out: empty directory (initially) to hold the output.
* jobscripts: empty directory (initially) to hold the array jobscript outputs (needed for debugging/checking progress)
* logs: empty directory (initially) to hold the log files (needed for debugging/checking progress)

#### Files & scripts:
* **array-params-complete.txt**: text file containing 3 fields (tab separated) describing the files to process.
  * Field 1: row index (useful for logging how many threads to request for the job, but not read by any scripts).
  * Field 2: Read 1 file name
  * Field 3: Read 2 file name
  
* **tracer-array.sh**: Script set up to run the tracer part of the pipeline using an SGE array job. Please see SGE documentation for editing the job size requests (for example) if unclear.

* **changeo_igblast.sh**: Script to run the changeo portion of immcantation on the output fasta files from tracer

* **findcompletedjobs.sh**: Searches the job history from a set number of hours previous to identify completed jobs with a specific exit code. Useful for finding 137 errors, so that they can be resubmitted with more memory

* **geterror137jobs.sh**: Loop through findcompletedjobs.sh output and assemble a new array-params-complete file for resubmission (containing only the OOM failed files)

* **processDB.py**: Annotates and summarises tracer_out results files. Version of for the summarised clonotypes file from tracer.
  * Will need to change the default path to "tracer output folder list" (```-p``` or ```--path```) command line argument.

* **tracerconfig.conf:** Configuration file for tracer, set up as I had it. Base tracer.conf file does not have all file paths enabled. Either use this new one or set up the original.

* **TRD.fasta:** IMGT germline D gene annotations and nucleotide sequences

* **TRJ.fasta:** IMGT germline J gene annotations and nucleotide sequences

* **TRV.fasta:** IMGT germline V gene annotations and nucleotide sequences

### Instructions:
1. Download docker containers and set up as instructed in the source documentation.

2. Create/modify the array-params-complete.txt script (ensure this file name is reflected in tracer-array.sh)
  * ensure files are all in the fastq folder

3. Submit the job to the scheduler using ```qsub -t <NUMBER_OF_THREADS_REQUIRED_IF_CHANGING_FROM_DEFAULT> -N <RUN_NAME> tracer-array.sh```
  * Results will be saved in the folder 'tracer_out'
  * Each cell will be granted its own folder, regardless of if the job completes (i.e., if a TCR is identified).
    * See tracer documentation for full explanation of the results, however only the **filtered_TCR_seqs** and **expression_quantification** folders are needed for running **immcantation** and **processDB.py** downstream.
    
4. Run immcantation using ```./changeo_igblast.sh```.
  * Files are very small, so finish very quickly. Therefore I either used the login node (not advised, HPC staff may get mad) or used a low memory requirement interactive job.
  * Script queries the ```<CELL_NAME>/filtered_TCR_seqs/<CELL_NAME>_TCRseqs.fa``` file, and inputs it to changeo. It creates a new folder within 'filtered_TCR_seqs' folder called 'igblast'.
    * Output files are:
      * ```<CELL_NAME>_igblast.fmt7```: Direct IgBLAST output, not very interpretable, but needed for MakeDb.py (ChangeO).
      * ```<CELL_NAME>_igblast_db-pass.tsv```: Database constructed from above .fmt7 file. At most 2 entries per chain.
  
5. Run ```processDB.py```.
  * Processes ```<CELL_NAME>_igblast_db-pass.tsv``` into a ```<CELL_NAME>_igblast_processed.tsv```slimmed file fewer columns, and adding in the donor information and tpm per sequence (if a case of 2 productive TCRs, can be used for assigning a dominant sequence).
  * Also creates a summary file (similar to ```tracer summarise```), containing dominant productive/unproductive TCR identifiers. Also contains CDR3A/B AA sequence, rather than just tracer id (genes + CDR3 nucleotide motif).
    * Outputs a summary file per cell, therefore join together via pandas or bash.




