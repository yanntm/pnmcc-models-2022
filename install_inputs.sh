#! /bin/bash

set -x

mkdir website
cd website

# grab the vmdk file image for all inputs
mkdir INPUTS
wget --no-check-certificate --progress=dot:mega http://mcc.lip6.fr/2020/archives/mcc2020-input.vmdk.tar.bz2
tar xvjf mcc2020-input.vmdk.tar.bz2
../7z e mcc2020-input.vmdk
../ext2rd 0.img ./:INPUTS
rm -f *.vmdk 0.img *.bz2 1

# create oracle files
mkdir oracle
wget --no-check-certificate --progress=dot:mega https://mcc.lip6.fr/2020/archives/raw-result-analysis.csv.zip
unzip raw-result-analysis.csv.zip
cat raw-result-analysis.csv | cut -d ',' -f2,3,16 | grep -v "?" | sort | uniq | ../csv_to_control.pl
mv *.out oracle/

# Due to parse errors of ITS-Tools+ITS-Lola that were not always interpreted as such in 2020
# consensus, and thus oracles on this model are unreliable.
rm oracle/Sudoku-COL*

# after manual examination, this consensus verdict (with weak support) is also wrong
# formula is reduced to true by e.g. Spot : https://spot.lrde.epita.fr/app/
# try it : X !X !(X G "k38" | F !X "k38")
sed -i -e "s/Angiogenesis-PT-15-14 FALSE/Angiogenesis-PT-15-14 TRUE/" oracle/Angiogenesis-PT-15-LTLF.out

#rm -f raw-result-analysis.csv*

cd oracle
tar xvzf ../../oracleSS.tar.gz
cd ..
tar cvzf oracle.tar.gz  oracle/
#rm -rf oracle/

cd ..



