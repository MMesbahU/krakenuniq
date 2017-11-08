#!/bin/bash

set -eu

#[[ "$#" -ne 1 ]] && DIR=`pwd` || DIR=$1
DIR=`pwd`
[[ `uname` == "Darwin" ]] && THREADS=4 || THREADS=10


build_db() {
  local K=$1; shift
  local MIN=$1; shift
  local NAM=$1; shift

  local DB_NAM=refseq-$NAM-k$K
  DB_DIR=$DIR/dbs/$DB_NAM

  mkdir -p $DB_DIR
  CMD="krakenu-build --kmer-len $K --minimizer-len $MIN --threads $THREADS --db $DB_DIR --build --taxids-for-genomes --taxids-for-sequences --taxonomy-dir=$DIR/data/taxonomy --uid-database"
  for L in $@; do
    CMD="$CMD  --library-dir=$DIR/data/library/$L"
  done
  if [[ ! -f "$DB_DIR/is.busy" ]]; then
    echo "EXECUTING $CMD"
    touch $DB_DIR/is.busy
    $CMD 2>&1 | tee $DIR/dbs/$DB_NAM/build.log
    if [[ ! -f "$DB_DIR/taxonomy/nodes.dmp" ]]; then
      mkdir -p $DB_DIR/taxonomy
      echo "EXECUTING dump_taxdb $DB_DIR/taxDB $DB_DIR/taxonomy/names.dmp $DB_DIR/nodes.dmp"
      dump_taxdb $DB_DIR/taxDB $DB_DIR/taxonomy/names.dmp $DB_DIR/nodes.dmp
    fi
    rm $DB_DIR/is.busy
  else 
    echo "$DB_DIR/is.busy exists, ignoring directory."
  fi
}

K=$1; shift;

for VAR in $@; do
  case "$VAR" in
    viral)     build_db $K 12 viral viral ;;
    all-viral) build_db $K 12 all-viral viral viral-neighbors  ;;
    prok)      build_db $K 15 prok archaea-dusted bacteria-dusted ;;
    oct2017)   build_db $K 15 oct2017 archaea-dusted bacteria-dusted viral-dusted viral-neighbors-dusted \
                               vertebrate_mammalian contaminants ;;
    euk-oct2017)
      EUKD=$DIR/dbs/refseq-euk-oct2017-k31
      [[ -d $EUKD ]] || mkdir -p $EUKD
      [[ -f $EUKD/taxDB ]] || cp -v $DB_DIR/taxDB $EUKD
      build_db $K euk-oct2017 fungi protozoa ;;
  *) echo "Usage: $0 K {viral|all-viral|prok|oct2017|euk-oct2017}"
     exit 1 ;;
  esac
done

