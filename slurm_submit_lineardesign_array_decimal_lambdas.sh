#!/bin/bash
#SBATCH --account=BORODAVKA-SL3-CPU	# (-A)
#SBATCH --partition=cclake	# (-p)
#SBATCH --nodes=1 # (-N)
#SBATCH --ntasks=1  # (-n)
#SBATCH --cpus-per-task=2	# (-c)
#SBATCH --time=01:00:00	# (-t)
#SBATCH --mem=5GB
#SBATCH --array=1-151 # (-a)

FASTA_AA=$1
CODON_TABLE=$2
LAMBDA_FILE=$3
UTR_5P=$4
UTR_3P=$5
OUTDIR=$6

RNA_NAME=$(grep ">" ${FASTA_AA} | sed 's/^>//')
LAMBDA=$(head -n ${SLURM_ARRAY_TASK_ID} ${LAMBDA_FILE} | tail -n1)

OUTPUT_CDS_FASTA=${RNA_NAME}_lineardesign_lambda${LAMBDA}.fa
OUTPUT_CDS_UTRS_FASTA=${RNA_NAME}_lineardesign_lambda${LAMBDA}_withUTRs.fa

# run lineardesign in container
apptainer exec lineardesign.sif ./lineardesign --lambda ${LAMBDA} --codonusage ${CODON_TABLE} < ${FASTA_AA} \
> ${RNA_NAME}_lineardesign_${LAMBDA}_output.txt

# extract sequence
CDS=$(grep -oP 'mRNA sequence:\s+\K.*' ${RNA_NAME}_lineardesign_${LAMBDA}_output.txt)

# write fasta file (CDS only)
echo ">${RNA_NAME}_lineardesign_lambda${LAMBDA}" > ${OUTPUT_CDS_FASTA}
echo $CDS >> ${OUTPUT_CDS_FASTA}

# write fasta file (with UTRs)
echo ">${RNA_NAME}_lineardesign_lambda${LAMBDA}_UTRs" > ${OUTPUT_CDS_UTRS_FASTA}
echo ${UTR_5P}${CDS}${UTR_3P} >> ${OUTPUT_CDS_UTRS_FASTA}

# make outdir & clean up
mkdir -p ${OUTDIR}/logs/lambda${LAMBDA}/
mv ${OUTPUT_CDS_FASTA} ${OUTDIR} && mv ${OUTPUT_CDS_UTRS_FASTA} ${OUTDIR}
mv slurm-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out ${OUTDIR}/logs/lambda${LAMBDA}/
mv ${RNA_NAME}_lineardesign_${LAMBDA}_output.txt ${OUTDIR}/logs/lambda${LAMBDA}/
