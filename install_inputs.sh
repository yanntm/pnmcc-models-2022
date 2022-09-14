#! /bin/bash

set -x

mkdir website
cd website

# grab the vmdk file image for all inputs
mkdir INPUTS
wget --no-check-certificate --progress=dot:mega https://mcc.lip6.fr/archives/mcc2022-input.tar.gz
tar xvzf mcc2022-input.tar.gz
../7z e mcc2022-input.vmdk
../ext2rd 0.img ./:INPUTS
# for some reason there are a few decompressed examples
rm -rf INPUTS/RERS2020-PT-pb10*/
# cleanup
rm -f *.vmdk 0.img *.gz 1

# patch formula names
# this step seems no longer necessary in 2022, see relveant script in 2021 repo.

if [ ! -f raw-result-analysis.csv ] 
then
	# grab the raw results file from MCC website
	wget --no-check-certificate --progress=dot:mega https://mcc.lip6.fr/archives/raw-result-analysis.csv.zip
	unzip raw-result-analysis.csv.zip
fi

# create oracle files
mkdir oracle
# all results available
cat raw-result-analysis.csv | grep -v StateSpace | grep -v UpperBound | cut -d ',' -f2,3,16 | sed 's/\s//g' | sort | uniq | ../csv_to_control.pl
# UpperBounds => do not remove whitespace
cat raw-result-analysis.csv | grep UpperBound | cut -d ',' -f2,3,16 | sort | uniq | ../csv_to_control.pl

 
# Patching bad consensus
# sed -i -e "s/UtilityControlRoom-COL-Z2T3N06-LTLCardinality-08 TRUE/UtilityControlRoom-COL-Z2T3N06-LTLCardinality-08 FALSE/" UtilityControlRoom-COL-Z2T3N06-LTLC.out

mv *.out oracle/

#rm -f raw-result-analysis.csv*

cd oracle
tar xzf ../../oracleSS.tar.gz
cd ..
tar czf oracle.tar.gz  oracle/
rm -rf oracle/

tree -H "." > index.html

cd ..
