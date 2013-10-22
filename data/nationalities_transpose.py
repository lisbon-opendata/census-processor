#!/usr/bin/python
# -*- coding: UTF-8 -*-

import csv
import sys

#Create/open a CSV file
f = open(sys.argv[1], 'a')

with open(sys.argv[2], 'rb') as ifile:
    reader = csv.reader(ifile)
    freg_id = 0
    for row in reader:

    	#If the freguesia ID of the row = the same as the previous
        if (freg_id) == (row[1]):
        	#We write the data to the CSV
        	f.write(',' + row[3])
        else:
        	#Otherwise we start a new line, add the ID and add the first bit of data
        	freg_id = row[1]
        	f.write('\n' + row[1] + ',' + row[3])

#Done. Close the file.
f.close()