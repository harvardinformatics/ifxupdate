#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o xtrace

# see https://ftp.ncbi.nlm.nih.gov/blast/db/v5/blastdbv5.pdf
nr() {
  update_blastdb.pl --blastdb_version 5 --decompress nr_v5
}

nt() {
  update_blastdb.pl --blastdb_version 5 --decompress nt_v5
}

pfam() {
  curl -fO ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam.version.gz
  gzip -d Pfam.version.gz

  # Per HMMER 3.2.1 User Guid: "running hmmpress on a standard input stream rather than a file is not allowed"
  curl -f ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz | gzip -dc > Pfam-A.hmm
  hmmpress Pfam-A.hmm
  rm Pfam-A.hmm
}

uniref90() (
  aria2c --dir=/tmp ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/uniref/uniref90/uniref90.release_note
  title=$(grep Release: /tmp/uniref90.release_note)
  title="UniRef90 ${title// /}" # trim whitespace from Release:...

  # download metalink file
  aria2c --dir=/tmp --follow-metalink=false ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/uniref/uniref90/RELEASE.metalink
  # get index of uniref.fasta.gz in RELEASE.metalink. Using int() to strip the whitespace.
  file_index=$(aria2c --show-files=true --metalink-file=/tmp/RELEASE.metalink | awk -F '|' '$2 == "uniref90.fasta.gz" {print int($1)}')
  
  # Download only uniref.fasta.gz, and not, e.g., the larger uniref90.xml.gz file
  # NOTE: --file-allocation=falloc (posix_fallocate()) is apparently not supported on Lustre?
  # (at least, an "operation not supported" error results on scratchlfs)
  aria2c --check-integrity --metalink-file=/tmp/RELEASE.metalink --select-file=${file_index} --file-allocation=none
  
  # -max_file_sz : Default is 1GB; bump this to 4GB to reduce # of files for tiny metadata optimization.
  #                makeblastdb apparently doesn't support -max_file_sz > 4GB:
  #                https://www.ncbi.nlm.nih.gov/books/NBK131777/
  #
  #                    BLAST+ 2.8.0: March 28, 2018
  #                    ...
  #                    * The 2GB output file size limit for makeblastdb has been increased to 4 GB.
  # -taxid_map
  #  See: https://www.ncbi.nlm.nih.gov/sites/books/NBK279688/

  gzip -dc uniref90.fasta.gz |
    makeblastdb -dbtype prot \
                -max_file_sz 4GB \
                -parse_seqids \
                -taxid_map <(gzip -dc uniref90.fasta.gz | sed -n 's/>\(UniRef[^ ]*\) .*TaxID=\([0-9]*\).*/\1 \2/p') \
                -blastdb_version 5 \
                -title "${title}" \
                -out uniref90
  
  rm uniref90.fasta.gz
)

while [ $# -ge 1 ]
do
  case $1 in
    nr|nt|uniref90|pfam)
      mkdir -p ${DIR:=$(date '+%YQ%q')}
      cd ${DIR}
      eval $1
      shift ;;
    *) printf 'ERROR: unknown database: %s (must be in [nr|nt|uniref90|pfam])\n' "$1" 1>&2
       exit 1 ;;
  esac
done
