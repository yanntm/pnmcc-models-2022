#! /bin/bash

set -x

mkdir website
cd website

# grab the vmdk file image for all inputs
mkdir INPUTS
wget --no-check-certificate --progress=dot:mega https://mcc.lip6.fr/2022/archives/mcc2022-input.tar.gz
tar xvzf mcc2022-input.tar.gz
../7z e mcc2022-input.vmdk
../ext2rd 0.img ./:INPUTS
# for some reason there are a few decompressed examples
rm -rf INPUTS/RERS2020-PT-pb101 INPUTS/RERS2020-PT-pb102 INPUTS/RERS2020-PT-pb103 INPUTS/RERS2020-PT-pb104 INPUTS/RERS2020-PT-pb105 INPUTS/RERS2020-PT-pb106 INPUTS/RERS2020-PT-pb107 INPUTS/RERS2020-PT-pb108 INPUTS/RERS2020-PT-pb109 
# cleanup
rm -f *.vmdk 0.img *.gz 1

# remove strange MacOS specific stuff 'LIBARCHIVE.xattr.com.apple.quarantine'
echo "Patching tgz archives"
set +x
cd INPUTS
for i in *.tgz ;
do
	tar xzf $i
	model=$(echo $i | sed 's/.tgz//g')
#	echo "Treating : $model"
	rm $i
	tar czf $i $model/
	rm -rf $model/
done
cd ..
set -x

if [ ! -f raw-result-analysis.csv ] 
then
	# grab the raw results file from MCC website
	wget --no-check-certificate --progress=dot:mega https://mcc.lip6.fr/2022/archives/raw-result-analysis.csv.zip
	unzip raw-result-analysis.csv.zip
fi

# create oracle files
mkdir oracle
# all results available
cat raw-result-analysis.csv | grep -v StateSpace | grep -v UpperBound | cut -d ',' -f2,3,16 | sed 's/\s//g' | sort | uniq | ../csv_to_control.pl
# UpperBounds => do not remove whitespace
cat raw-result-analysis.csv | grep UpperBound | cut -d ',' -f2,3,16 | sort | uniq | ../csv_to_control.pl

 
# Patching bad consensus

# this series is due to errors in ITS-Tools + reinforced by being Gold21 (sorry !)
sed -i -e "s/QuasiLiveness TRUE/QuasiLiveness FALSE/" SieveSingleMsgMbox-PT-d1m06-QL.out
sed -i -e "s/QuasiLiveness TRUE/QuasiLiveness FALSE/" SieveSingleMsgMbox-PT-d1m18-QL.out
sed -i -e "s/QuasiLiveness TRUE/QuasiLiveness FALSE/" SieveSingleMsgMbox-PT-d1m36-QL.out
sed -i -e "s/QuasiLiveness TRUE/QuasiLiveness FALSE/" SieveSingleMsgMbox-PT-d1m64-QL.out
sed -i -e "s/QuasiLiveness TRUE/QuasiLiveness FALSE/" SieveSingleMsgMbox-PT-d1m96-QL.out

# these points agree with Gold2021 (ITSTools) and current ITSTools 2022-09
# but disagree with consensus that is based on ITSTools 2022-05 answer (possibly a bug in SMT solver interaction ? not reproduced so far)
# no other tool provided an answer on these formulas.
# We currently believe ITSTools2021+2022-09 is right.
sed -i -e "s/StigmergyCommit-PT-11a-ReachabilityCardinality-06 TRUE/StigmergyCommit-PT-11a-ReachabilityCardinality-06 FALSE/" StigmergyCommit-PT-11a-RC.out
sed -i -e "s/StigmergyCommit-PT-11a-ReachabilityCardinality-13 FALSE/StigmergyCommit-PT-11a-ReachabilityCardinality-13 TRUE/" StigmergyCommit-PT-11a-RC.out
sed -i -e "s/StigmergyCommit-PT-11a-ReachabilityCardinality-14 TRUE/StigmergyCommit-PT-11a-ReachabilityCardinality-14 FALSE/" StigmergyCommit-PT-11a-RC.out
sed -i -e "s/StigmergyCommit-PT-11a-ReachabilityCardinality-15 FALSE/StigmergyCommit-PT-11a-ReachabilityCardinality-15 TRUE/" StigmergyCommit-PT-11a-RC.out

# this point is an error from Tapaal22 that got consensus from Gold21=Tapaal
# confirmed manually, formula reduces to true trivially (markings are >= 0)
sed -i -e "s/RERS17pb115-PT-5-LTLCardinality-04 FALSE/RERS17pb115-PT-5-LTLCardinality-04 TRUE/" RERS17pb115-PT-5-LTLC.out


mv *.out oracle/

#rm -f raw-result-analysis.csv*

cd oracle
tar xzf ../../oracleSS.tar.gz
cd ..
tar czf oracle.tar.gz  oracle/
rm -rf oracle/

tree -H "." > index.html

cd ..
