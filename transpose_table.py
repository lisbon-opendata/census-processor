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

    	# If the ID of the administrative area is different from the previous
        # we're dealing with a new area
        if (admin_area_id) != int(row[2]):
            # Add the ID and the first bit of data
            f.write('\n' + row[2] + ',' + row[4])
            
            admin_area_id = int(row[2])
        # Else, we're dealing with the same administrative area
        else:
            # we write the data to the same line
            f.write(',' + row[4])

# Done. Close the file.
f.close()