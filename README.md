# ifxupdate

Utility for downloading/creating quarterly FAS Informatics reference databases.

Currently supported:

* BLAST: **nr nt uniref90**
  * formatted as [version 5](https://ftp.ncbi.nlm.nih.gov/blast/db/v5/blastdbv5.pdf), requiring NCBI BLAST >= 2.8.0 to use.
* HMMER profile database: **pfam**

## Docker

Bind mount the host directory to populate to /mnt in the container.

ifxupdate will create a subdirectory based on the current date of the form:

* YYYYMM-stable, if there does not exist a -stable directory with the same YYYY
* YYYYMM, otherwise (i.e., non-"stable")

Upon successful completion:
1. A symbolic link "latest" is created that points to YYYYMM or YYYYMM-stable
2. If the third most-recent directory is non-stable (YYYYMM), it is removed

### Example

e.g., if BLASTDB_ROOT and HMMERDB_ROOT are set to directories that will contain containing quarterly subdirectories of BLAST and HMMER profile databases, respectively:

```
docker run --rm ifxupdate -v ${BLASTDB_ROOT}:/mnt nt nr uniref90
docker run --rm ifxupdate -v ${HMMERDB_ROOT}:/mnt pfam
```

### Example (Singularity)

```
singularity run --no-home --contain --cleanenv --pwd /mnt --bind ${BLASTDB_ROOT}:/mnt \
            ifxdbupdate.simg nt nr uniref90
singularity run --no-home --contain --cleanenv --pwd /mnt --bind ${HMMERDB_ROOT}:/mnt \
            ifxdbupdate.simg pfam
```
