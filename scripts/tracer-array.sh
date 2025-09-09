#!/bin/bash
#$ -N tracer_assemble
#$ -cwd
#$ -V
#$ -t 1-1624                    # Adjust to match number of cell folders
#$ -tc 100
#$ -pe smp 16                    # Use 16 threads per job (adjust as needed)
#$ -l mem=24G                 # Memory per slot

# --- CONFIG ---
APPTAINER_IMG=$HOME/Scratch/HBV-sc-rnaseq/tracer.sif
DATA_DIR=$HOME/Scratch/HBV-sc-rnaseq/fastqs
OUTPUT_DIR=$HOME/Scratch/HBV-sc-rnaseq/tracer_out
THREADS=$NSLOTS

# Parse parameter file to get variables.
paramfile="$HOME/Scratch/HBV-sc-rnaseq/array-params-complete_ERROR-137.txt"
number=$SGE_TASK_ID

index=$(sed -n "${number}p" "$paramfile" | awk '{print $1}')
R1=$(sed -n "${number}p" "$paramfile" | awk '{print $2}' | sed "s|^\$HOME|$HOME|")
R2=$(sed -n "${number}p" "$paramfile" | awk '{print $3}' | sed "s|^\$HOME|$HOME|")
CELL_NAME=$(echo $R1 | cut -d'_' -f1-3)

R1=$DATA_DIR/$R1
R2=$DATA_DIR/$R2

echo "Read 1: $R1"
echo "Read 2: $R2"
echo "Cell name: $CELL_NAME"

# Make output directory
mkdir -p "$OUTPUT_DIR"

# Run Tracer inside Apptainer
apptainer exec \
  --bind "${DATA_DIR},${OUTPUT_DIR}" \
  --env IGDATA=/ncbi-igblast-1.7.0/bin \
  "$APPTAINER_IMG" \
  tracer assemble "$R1" "$R2" "$CELL_NAME" "$OUTPUT_DIR" \
  -p "$THREADS" \
  -c "$HOME/Scratch/HBV-sc-rnaseq/tracerconfig.conf" -s Hsap



