#!/usr/bin/env python

import pandas as pd
import os
import numpy as np
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-p', '--path', help = 'path to tracer output folder list', default = '/home/ucbtpt0/Scratch/HBV-sc-rnaseq/tracer_out')
parser.add_argument('-cn', '--cellname', help = 'name of the cell to process')

args = parser.parse_args()

def get_value(df, col):
	return df[col].iloc[0] if not df.empty else np.nan

cell_name = args.cellname
path = args.path

igblast_infile = os.path.join(path, cell_name, 'filtered_TCR_seqs', 'igblast', f'{cell_name}_igblast_db-pass.tsv')
kallisto_infile =os.path.join(path, cell_name, 'expression_quantification', 'abundance.tsv')

cell_df = pd.read_csv(igblast_infile, sep = '\t')
cell_df = cell_df[['sequence_id', 'sequence', 'productive', 'locus',
				   'v_call', 'd_call', 'j_call', 'sequence_alignment',
				   'germline_alignment', 'junction', 'junction_aa']]
cell_df['donor'] = cell_name

kallisto = pd.read_csv(kallisto_infile,
					   sep = '\t').tail(10)
kallisto = kallisto.rename(columns={'target_id': 'sequence_id'})[['sequence_id', 'tpm']]

cell_df = cell_df.merge(kallisto, 'left')
cell_df['sequence_id'] = [i.split('|')[4] for i in cell_df.sequence_id]

cell_df.to_csv(os.path.join(path, cell_name, 'filtered_TCR_seqs', 'igblast', f'{cell_name}_igblast_processed.tsv'), sep = '\t', index = False)

cell_df = (cell_df.sort_values('tpm', ascending = False).groupby(['locus', 'productive'], as_index = False).head(1))

try:
	A1 = cell_df[(cell_df['locus'] == 'TRA') & (cell_df['productive'] == 'F')]
except:
	A1 = pd.DataFrame(columns = cell_df.columns)

try:
	A2 = cell_df[(cell_df['locus'] == 'TRA') & (cell_df['productive'] == 'T')]
except:
	A2 = pd.DataFrame(columns = cell_df.columns)

try:
	B1 = cell_df[(cell_df['locus'] == 'TRB') & (cell_df['productive'] == 'F')]
except:
	B1 = pd.DataFrame(columns = cell_df.columns)

try:
	B2 = cell_df[(cell_df['locus'] == 'TRB') & (cell_df['productive'] == 'T')]
except:
	B2 = pd.DataFrame(columns = cell_df.columns)


summary_df = pd.DataFrame({
    'A_unproductive': [get_value(A1, 'sequence_id')],
    'A_productive': [get_value(A2, 'sequence_id')],
    'A_unproductive_CDR3AA': [get_value(A1, 'sequence_id')],
    'A_productive_CDR3AA': [get_value(A2, 'junction_aa')],
    'B_unproductive': [get_value(B1, 'sequence_id')],
    'B_productive': [get_value(B2, 'sequence_id')],
    'B_unproductive_CDR3AA': [get_value(B2, 'junction_aa')],
    'B_productive_CDR3AA': [get_value(B2, 'junction_aa')]})

summary_df.index = [cell_name]

summary_df.to_csv(os.path.join(path, cell_name, 'filtered_TCR_seqs', 'igblast', f'{cell_name}_igblast_summary.tsv'), sep = '\t')


