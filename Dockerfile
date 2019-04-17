FROM debian:9.8-slim

# NOTE: debian 9.8's curl and wget packages do not support metalink.
#       Using aria2 instead.
# Dependencies:
# * aria2 - to download UniRef90 (with metalink) https://www.uniprot.org/help/metalink
# * curl - used by update_blastdb.pl
# * ca-certificates - for curl; to avoid the error "error setting certificate verify locations"
# * libencode-perl - for update_blastdb.pl
# * perl-doc - for Pod::Usage in update_blastdb.pl

RUN apt update \
    && apt install -y --no-install-recommends aria2 curl hmmer perl-modules-5.24 perl-doc libencode-perl libjson-perl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Need BLAST >= 2.8.0 to make BLAST DB v5
#     https://ftp.ncbi.nlm.nih.gov/blast/db/v5/blastdbv5.pdf

ENV BLAST_VERSION 2.9.0
 
RUN curl -Lf https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/${BLAST_VERSION}/ncbi-blast-${BLAST_VERSION}+-x64-linux.tar.gz \
    | tar -C /usr/local --occurrence=1 --strip-components=1 -xzvf - --wildcards '*/bin/makeblastdb' '*/bin/update_blastdb.pl'

COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR /mnt
