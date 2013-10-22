#!/bin/bash --posix

# Script for the Views on Lisbon project, processing

# INSTRUCTIONS
# $ bash process_nationalities.sh

# OUTPUT
# A de-normalized CSV file with data about nationalities per freguesia in Portugal

# TODO
# Improve the source_zip + souce_file vars (not hard-coded)

start_time=$SECONDS

#Giving the output file a nice name.
output_file=nationalities_portugal.csv
#URL of the source ZIP
source_url=http://www.ine.pt/investigadores/Quadros/Q605.zip
#The file-name of the ZIP
source_zip=Q605.zip
#The original Excel that's in the zip  
source_file=Q605.xlsx
#The sheets in the Excel that need to be processed
sheets=(Q605_NORTE Q605_CENTRO Q605_LISBOA Q605_ALENTEJO Q605_ALGARVE Q605_ACORES Q605_MADEIRA)

#Change Internal Field Separator to new line. Otherwise, it will think spaces in filenames are field separators
IFS=$'\n'

#The folder should not contain the final file already
if [ `ls | grep '$output_file' | wc -l` == 1 ]; then
	echo It seems you already have a $output_file in this folder. Remove it and run this script again.
	exit
fi

#Checking if the dependencies are met.
#Some of the tools used are part of csvkit, like in2csv, csvjoin, csvstack, etc
#Based on: http://www.snabelb.net/content/bash_support_function_check_dependencies

deps_ok="yes"
for dep in in2csv python #in2csv is part of csvkit
do
    if ! which $dep &>/dev/null;  then
        if [[ $dep == "in2csv" ]]; then
        	echo -e "\nThis script requires a couple of tools that are provided by csvkit."
        	echo -e "You might be able to install csvkit by using:"
        	echo -e "\t\tpip install csvkit"
        	echo -e "More info: http://csvkit.readthedocs.org/en/latest/index.html#installation"
        elif [[ $dep != "in2csv" ]]; then
            echo -e "\nThis script requires $dep to run but it is not installed."
            echo -e "If you are running ubuntu or debian you could try"
            echo -e "\t\tsudo apt-get install $dep"
    	fi
	deps_ok="no"
    fi
if [[ "$deps_ok" == "no" ]]; then
	echo -e "Aborting!\n"
	exit
fi
done

#Check if the folder already contains a local copy of the xsls file
if [ `ls | grep $source_file | wc -l` > 0 ]; then
	#If so, ask if we should download the file again
	echo "We found a local copy of the $source_file. Should we download it anyway? (If not, the local copy will be used)"
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes)
				echo Downloading and unzipping the file...
				rm $source_file
				wget $source_url
				unzip -q $source_zip
				rm $source_zip
				break;;
	        No) 
				break;;
	    esac
	done
else
	#If none found, download anyway
	echo Downloading and unzipping the file...
	wget $source_url
	unzip -q $source_zip
	rm $source_zip
fi

elapsed_time=$(($SECONDS - $start_time))
echo $elapsed_time seconds. Converting the relevant sheets of the Excel file to CSV format \(this will take a while\)...

#Convert each relevant sheet in the Excel file to its own CSV file
for sheet in ${sheets[*]}
do
	#in2csv on the sheet that matters
	in2csv --sheet $sheet $source_file > $sheet.csv
done


elapsed_time=$(($SECONDS - $start_time))
echo $elapsed_time seconds. Cleaning up the CSV files by removing the cruft...

#Clean up each of the CSV files
for sheet in ${sheets[*]}
do
	#csvcut removes the columns with age-specific data. We only need the totals per administrative area
	#csvgrep removes all the rows that are not related to a freguesia (Identified by a 6 in column 2)
	csvcut -c 2,3,4,5 $sheet.csv | csvgrep -c 1 -m "6" > $sheet-tmp.csv
	#Remove first line that's empty
	sed -i "1,1d" $sheet-tmp.csv
	#Do some housekeeping by removing the tmp files.
	rm $sheet.csv
	mv $sheet-tmp.csv $sheet.csv
done

elapsed_time=$(($SECONDS - $start_time))
echo $elapsed_time seconds. About to transpose the data and add it to the final table...

#Create the file with the final data
touch $output_file
echo 'id,"Total HM", "Total H", "Portugal HM", "Portugal H", "Estrangeira HM", "Estrangeira H", "Europa HM", "Europa H", "União Europeia 27 (S/PT) HM", "União Europeia 27 (S/PT) H", "França HM", "França H", "Países Baixos (Holanda) HM", "Países Baixos (Holanda) H", "Alemanha HM", "Alemanha H", "Itália HM", "Itália H", "Reino Unido HM", "Reino Unido H", "Irlanda HM", "Irlanda H", "Dinamarca HM", "Dinamarca H", "Grécia HM", "Grécia H", "Espanha HM", "Espanha H", "Bélgica HM", "Bélgica H", "Luxemburgo HM", "Luxemburgo H", "Suécia HM", "Suécia H", "Finlândia HM", "Finlândia H", "Áustria HM", "Áustria H", "Malta HM", "Malta H", "Estónia HM", "Estónia H", "Letónia HM", "Letónia H", "Lituânia HM", "Lituânia H", "Polónia HM", "Polónia H", "República Checa HM", "República Checa H", "Eslováquia HM", "Eslováquia H", "Hungria HM", "Hungria H", "Roménia HM", "Roménia H", "Bulgária HM", "Bulgária H", "Eslovénia HM", "Eslovénia H", "Chipre HM", "Chipre H", "Outros países (parcial) HM", "Outros países (parcial) H", "Noruega HM", "Noruega H", "Suíça HM", "Suíça H", "Rússia (Federação da) HM", "Rússia (Federação da) H", "Outros países - Europa HM", "Outros países - Europa H", "África HM", "África H", "África do Sul HM", "África do Sul H", "Angola HM", "Angola H", "Cabo Verde HM", "Cabo Verde H", "Guiné-Bissau HM", "Guiné-Bissau H", "Moçambique HM", "Moçambique H", "São Tomé e Príncipe HM", "São Tomé e Príncipe H", "Outros países - África HM", "Outros países - África H", "América HM", "América H", "Argentina HM", "Argentina H", "Brasil HM", "Brasil H", "Canadá HM", "Canadá H", "Estados Unidos da América HM", "Estados Unidos da América H", "Venezuela, República Bolivariana da HM", "Venezuela, República Bolivariana da H", "Outros país - América HM", "Outros país - América H", "Ásia HM", "Ásia H", "China HM", "China H", "Índia HM", "Índia H", "Japão HM", "Japão H", "Macau HM", "Macau H", "Paquistão HM", "Paquistão H", "Timor Leste HM", "Timor Leste H", "Outros países - Ásia HM", "Outros países - Ásia H", "Oceânia HM", "Oceânia H", "Austrália HM", "Austrália H", "Outros países da Oceânia HM", "Outros países da Oceânia H", "Outros países HM", "Outros países H", "Dupla nacionalidade HM", "Dupla nacionalidade H", "Dupla nacionalidade portuguesa e outra HM", "Dupla nacionalidade portuguesa e outra H", "Dupla nacionalidade estrangeira HM", "Dupla nacionalidade estrangeira H", "Dupla nacionalidade estrangeira, sendo uma da União Europeia HM", "Dupla nacionalidade estrangeira, sendo uma da União Europeia H", "Dupla nacionalidade estrangeira, nenhuma da União Europeia HM", "Dupla nacionalidade estrangeira, nenhuma da União Europeia H", "Apátrida HM", "Apátrida H"' > $output_file
for sheet in ${sheets[*]}
do
	#For every sheet, a python script is called that transposes the data and adds it to the final file
	python nationalities_transpose.py $output_file $sheet.csv
	rm $sheet.csv
done

elapsed_time=$(($SECONDS - $start_time))
echo $elapsed_time seconds. Done!
	
exit