#!/bin/bash --posix

# Script to process data from the Portuguese 2011 Census.

# INSTRUCTIONS
# $ bash process_census.sh -i [indicator] -o [output file]
# Example: bash process_census.sh -i 204 -o data.csv

# OUTPUT
# A de-normalized CSV file with totals of the indicator per administrative
# area.

# TODO
# Improve the source_zip + souce_file vars (not hard-coded)
# review //TEMP

set -u

typeset -r start_time=$SECONDS

error()
{
	echo >&2 $*
	exit 1
}

usage()
{
	cat >&2 <<-EOF
		Usage : $0 -i 605 -o nationalities_portugal.csv
			-i indicator
			-o output file
			-h help
	EOF
}

typeset var_indicator=""
typeset var_output=""

while getopts "i:o:h" option
do
	case $option in
	i)
		var_indicator="$OPTARG"
		;;
	o)
		var_output="$OPTARG"
		;;
	h)
		usage
		exit 0
		;;
	*)
		usage
		exit 1
		;;
	esac
done

# check that args not empty
# //TEMP we could make better checks
[[ $var_indicator != "" ]] || { usage; exit 1;}
[[ $var_output != "" ]] || { usage; exit 1;}

# check that transpose_table.py is available
typeset -r cmd_transpose_table="transpose_table.py"
[[ -f $cmd_transpose_table ]] || error "This script needs $cmd_transpose_table"

# check that transpose_table.py is available
typeset -r cmd_generate_header="generate_header.py"
[[ -f $cmd_generate_header ]] || error "This script needs $cmd_generate_header"

# The folder should not contain the final file already
[[ ! -f $var_output ]] || error "It seems you already have a $var_output in this folder. Remove it and run this script again."

# constructing the URL based on the indicator
typeset -r base_url=http://www.ine.pt/investigadores/Quadros/Q${var_indicator}.zip
# getting base file name from URL (//TEMP see if it is not better to put it on argument)
typeset -r base_zip_file_name=Q${var_indicator}.zip
typeset -r base_file_name=${base_zip_file_name%%.*}

#The sheets in the Excel that need to be processed
typeset -r sheets=(Q${var_indicator}_NORTE Q${var_indicator}_CENTRO Q${var_indicator}_LISBOA Q${var_indicator}_ALENTEJO Q${var_indicator}_ALGARVE Q${var_indicator}_ACORES Q${var_indicator}_MADEIRA)

#Change Internal Field Separator to new line. Otherwise, it will think spaces in filenames are field separators
typeset -r IFS=$'\n'

#Checking if the dependencies are met.
#Some of the tools used are part of csvkit, like in2csv, csvjoin, csvstack, etc
#Based on: http://www.snabelb.net/content/bash_support_function_check_dependencies

# for portability and just in case which is not available
typeset -r cmd_which="/usr/bin/which"
[[ -x $cmd_which ]] || error "$cmd_which command not found"

# check that every command is available and executable
for command in in2csv csvcut python wget unzip sed
do
	if [[ $command == "in2csv" ]]
	then
		typeset -r cmd_in2csv=$($cmd_which in2csv)
		if [[ ! -x $cmd_in2csv ]]
		then
			# but keep initial echo
			echo -e "\nThis script requires a couple of tools that are provided by csvkit."
			echo -e "You might be able to install csvkit by using:"
			echo -e "\t$ sudo pip install csvkit"
			echo -e "More info: http://csvkit.readthedocs.org/en/latest/index.html#installation"
			exit 1
		fi
	else
		typeset -r cmd_$command=$($cmd_which $command)
		[[ -x $(eval echo \$cmd_$command) ]] || error "$cmd_$command command not found"
	fi
done

download_and_unzip()
{
	echo "Downloading and unzipping the file..."
	$cmd_wget "$base_url" || error "$cmd_wget "$base_url""
	$cmd_unzip -q $base_file_name.zip || error "$cmd_unzip -q $base_file_name.zip"
	# //TEMP see if not better to put a clean option
	# (if for test we do not want to download everytime the archive)
	rm $base_file_name.zip || error "ERROR :rm $base_file_name.zip"
}

# Check if the folder already contains a local copy of the xlsx file
[[ ! -f $base_file_name.xlsx ]] || error "It seems you already have a $base_file_name.xslx in this folder. Remove it and run this script again."

# Check if the folder already contains a local copy of the zip file
if [[ -f $base_file_name.zip ]]
then
	echo "We found a local copy of the $base_file_name. Should we download it anyway? (If not, the local copy will be used)"
	select yn in "Yes" "No"; do
		case $yn in
		Yes)
				download_and_unzip
				break
				;;
		No) 
				break
				;;
		esac
	done
else
	#If none found, download anyway
	download_and_unzip
fi

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. Converting the relevant sheets of the Excel file to CSV format (this will take a while)..."

#Convert each relevant sheet in the Excel file to its own CSV file
# //TEMP add multiprocessing 
for sheet in ${sheets[*]}
do
	echo "Starting $sheet"
	#in2csv on the sheet that matters
	$cmd_in2csv --sheet $sheet -f xlsx $base_file_name.xlsx > $sheet.csv
	elapsed_time=$(($SECONDS - $start_time))
	echo "$elapsed_time seconds. done"
done

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. Cleaning up the CSV files by removing the cruft..."

# Clean up each of the CSV files
for sheet in ${sheets[*]}
do
	#csvcut removes the columns with age-specific data. We only need the totals per administrative area
	#csvgrep removes all the rows that are not related to a freguesia (Identified by a 6 in column 2)
	$cmd_csvcut -c 1,2,3,4,5 $sheet.csv | csvgrep -c 2 -m "6" > $sheet-tmp.csv
	#Remove first line that's empty
	$cmd_sed -i "1,1d" $sheet-tmp.csv
	#Do some housekeeping by removing the tmp files.
	rm $sheet.csv || error "rm $sheet.csv"
	mv $sheet-tmp.csv $sheet.csv || error "mv $sheet-tmp.csv $sheet.csv"
done

#Create the file with the final data
touch $var_output || error "touch $var_output"

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. Building the header of the CSV..."

#Build the header of the CSV based on the first sheet in the sheets array
$cmd_python $cmd_generate_header $var_output $sheets.csv || error "$cmd_python $cmd_generate_header $var_output $sheets.csv"

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. About to transpose the data and add it to the final table..."

for sheet in ${sheets[*]}
do
	#For every sheet, a python script is called that transposes the data and adds it to the final file
	$cmd_python $cmd_transpose_table $var_output $sheet.csv || error "$cmd_python $cmd_transpose_table $var_output $sheet.csv"
	rm $sheet.csv || error "rm $sheet.csv"
done

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. Done!"

exit 0

# EOF