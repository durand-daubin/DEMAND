#!/bin/bash 

# Job requirements
#PBS -l walltime=00:00:00 
 
# Linux commands
echo "Hello $USER"

# use -v to get some feedback
module -v unload stata

module -v load stata/11.0

# this should activate stata 11 instead of stata 9
module -v switch stata stata/11.0

# stata version
echo "Stata version about to be run:"
which stata

stata -b "do ~/do_files/DEMAND-HPC-test-UKDA-6583-1-min-res-data.do"

echo "Done, goodbye $USER"