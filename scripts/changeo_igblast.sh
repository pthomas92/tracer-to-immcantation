#!/bin/bash -l

DATA_DIR=$HOME/Scratch/HBV-sc-rnaseq
SAMPLE_NAME=$(ls -d $DATA_DIR/tracer_out/*erf*/)
BASE_OUT=$HOME/Scratch/HBV-sc-rnaseq/tracer_out
NPROC=1

module load python3/recommended

for sn in $SAMPLE_NAME; do
        sn=$(basename $sn)
	OUT_DIR=${BASE_OUT}/${sn}/filtered_TCR_seqs/igblast
	READS=${DATA_DIR}/tracer_out/${sn}/filtered_TCR_seqs/*.fa
	# Singularity command
	apptainer exec -B $DATA_DIR:/data $DATA_DIR/immcantation_suite-4.6.0.sif \
	    changeo-igblast -s $READS -n $sn -o $OUT_DIR -p $NPROC \
	    -t tr
	apptainer exec -B $DATA_DIR:/data $DATA_DIR/immcantation_suite-4.6.0.sif \
		MakeDb.py igblast -i "${OUT_DIR}/${sn}_igblast.fmt7" -s $READS \
		-r $DATA_DIR/TRV.fasta $DATA_DIR/TRD.fasta $DATA_DIR/TRJ.fasta \
	    --extended 

	python3 $DATA_DIR/processDB.py --path $BASE_OUT --cellname $sn
done
