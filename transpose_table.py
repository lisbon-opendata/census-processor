#!/usr/bin/python
# -*- coding: UTF-8 -*-

import csv
import sys

# Open the CSV file
f = open(sys.argv[1], 'a')

with open(sys.argv[2], 'rb') as ifile:
    reader = csv.reader(ifile)
    admin_area_id = 0
    for row in reader:

    	# If the ID of the administrative area = the same as the previous
        if (admin_area_id) == (row[1]):
        	# we write the data to the CSV
        	f.write(',' + row[3])
        # Else, we're dealing with a new administrative area that needs to go 
        # to a new line
        else:
            # Except for the very first admin area, a new line is needed
            if (admin_area_id) != 0:
                f.write('\n')
            # Add the ID and add the first bit of data
        	f.write(row[1] + ',' + row[3])
            admin_area_id = row[1]   

# Done. Close the file.
f.close()