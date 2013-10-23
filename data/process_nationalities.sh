#!/bin/bash --posix

# Script for the Views on Lisbon project, processing

# INSTRUCTIONS
# $ bash process_nationalities.sh

# OUTPUT
# A de-normalized CSV file with data about nationalities per freguesia in Portugal

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
		Usage : $0: -u http://www.ine.pt/investigadores/Quadros/Q605.zip -o nationalities_portugal.csv
			-u source URL
			-o output file
			-h help
	EOF
}

typeset var_url=""
typeset var_output=""

while getopts "u:o:h" option
do
	case $option in
	u)
		var_url="$OPTARG"
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
[[ $var_url != "" ]] || { usage; exit 1;}
[[ $var_output != "" ]] || { usage; exit 1;}

# The folder should not contain the final file already
[[ ! -f $var_output ]] || error "It seems you already have a $var_output in this folder. Remove it and run this script again."

# getting base file name from URL (//TEMP see if it is not better to put it on argument)
typeset -r base_zip_file_name=${var_url##*/}
typeset -r base_file_name=${base_zip_file_name%%.*}

#The sheets in the Excel that need to be processed
typeset -r sheets=(Q605_NORTE Q605_CENTRO Q605_LISBOA Q605_ALENTEJO Q605_ALGARVE Q605_ACORES Q605_MADEIRA)

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
	$cmd_wget "$var_url" || error "$cmd_wget "$var_url""
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
echo "$elapsed_time seconds. Converting the relevant sheets of the Excel file to CSV format \(this will take a while\)..."

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
	$cmd_csvcut -c 2,3,4,5 $sheet.csv | csvgrep -c 1 -m "6" > $sheet-tmp.csv
	#Remove first line that's empty
	$cmd_sed -i "1,1d" $sheet-tmp.csv
	#Do some housekeeping by removing the tmp files.
	rm $sheet.csv || error "rm $sheet.csv"
	mv $sheet-tmp.csv $sheet.csv || error "mv $sheet-tmp.csv $sheet.csv"
done

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. About to transpose the data and add it to the final table..."

#Create the file with the final data
touch $var_output || error "touch $var_output"
echo 'id,"Total HM", "Total H", "Portugal HM", "Portugal H", "Estrangeira HM", "Estrangeira H", "Europa HM", "Europa H", "União Europeia 27 (S/PT) HM", "União Europeia 27 (S/PT) H", "França HM", "França H", "Países Baixos (Holanda) HM", "Países Baixos (Holanda) H", "Alemanha HM", "Alemanha H", "Itália HM", "Itália H", "Reino Unido HM", "Reino Unido H", "Irlanda HM", "Irlanda H", "Dinamarca HM", "Dinamarca H", "Grécia HM", "Grécia H", "Espanha HM", "Espanha H", "Bélgica HM", "Bélgica H", "Luxemburgo HM", "Luxemburgo H", "Suécia HM", "Suécia H", "Finlândia HM", "Finlândia H", "Áustria HM", "Áustria H", "Malta HM", "Malta H", "Estónia HM", "Estónia H", "Letónia HM", "Letónia H", "Lituânia HM", "Lituânia H", "Polónia HM", "Polónia H", "República Checa HM", "República Checa H", "Eslováquia HM", "Eslováquia H", "Hungria HM", "Hungria H", "Roménia HM", "Roménia H", "Bulgária HM", "Bulgária H", "Eslovénia HM", "Eslovénia H", "Chipre HM", "Chipre H", "Outros países (parcial) HM", "Outros países (parcial) H", "Noruega HM", "Noruega H", "Suíça HM", "Suíça H", "Rússia (Federação da) HM", "Rússia (Federação da) H", "Outros países - Europa HM", "Outros países - Europa H", "África HM", "África H", "África do Sul HM", "África do Sul H", "Angola HM", "Angola H", "Cabo Verde HM", "Cabo Verde H", "Guiné-Bissau HM", "Guiné-Bissau H", "Moçambique HM", "Moçambique H", "São Tomé e Príncipe HM", "São Tomé e Príncipe H", "Outros países - África HM", "Outros países - África H", "América HM", "América H", "Argentina HM", "Argentina H", "Brasil HM", "Brasil H", "Canadá HM", "Canadá H", "Estados Unidos da América HM", "Estados Unidos da América H", "Venezuela, República Bolivariana da HM", "Venezuela, República Bolivariana da H", "Outros país - América HM", "Outros país - América H", "Ásia HM", "Ásia H", "China HM", "China H", "Índia HM", "Índia H", "Japão HM", "Japão H", "Macau HM", "Macau H", "Paquistão HM", "Paquistão H", "Timor Leste HM", "Timor Leste H", "Outros países - Ásia HM", "Outros países - Ásia H", "Oceânia HM", "Oceânia H", "Austrália HM", "Austrália H", "Outros países da Oceânia HM", "Outros países da Oceânia H", "Outros países HM", "Outros países H", "Dupla nacionalidade HM", "Dupla nacionalidade H", "Dupla nacionalidade portuguesa e outra HM", "Dupla nacionalidade portuguesa e outra H", "Dupla nacionalidade estrangeira HM", "Dupla nacionalidade estrangeira H", "Dupla nacionalidade estrangeira, sendo uma da União Europeia HM", "Dupla nacionalidade estrangeira, sendo uma da União Europeia H", "Dupla nacionalidade estrangeira, nenhuma da União Europeia HM", "Dupla nacionalidade estrangeira, nenhuma da União Europeia H", "Apátrida HM", "Apátrida H"' > $var_output
for sheet in ${sheets[*]}
do
	#For every sheet, a python script is called that transposes the data and adds it to the final file
	$cmd_python nationalities_transpose.py $var_output $sheet.csv || error "$cmd_python nationalities_transpose.py $var_output $sheet.csv"
	rm $sheet.csv || error "rm $sheet.csv"
done

elapsed_time=$(($SECONDS - $start_time))
echo "$elapsed_time seconds. Done!"

exit 0

# EOF