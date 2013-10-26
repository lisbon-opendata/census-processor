#!/usr/bin/python
# -*- coding: UTF-8 -*-

# This script takes 

import csv
import sys

# Open the CSV file
f = open(sys.argv[1], 'a')

with open(sys.argv[2], 'rb') as ifile:
    reader = csv.reader(ifile)
    rows = list(reader)
    aaid = int(rows[0][2])

    # Determine what structure we're dealing with. Possibilites: 
    # 1. One sub-category (100)
    # 2. Two sub-categories (1)
    # 3. No sub-category (anything else)

    compare_id = int(rows[1][0]) - int(rows[0][0])
    
    # First column is always admin_area_id
    f.write('admin_area_id')

    first_cat = True

	# 1. One sub-category
    if compare_id == 100:
    	for row in rows:
    		# We only need the structure of one administrative area
    		if int(row[2]) != aaid:
    			break
    		# On the first row, the category name will always be 'Total'
    		if first_cat:
    			f.write(', total')
    			first_cat = False
    		else:
    			# Write each category to a column
    			f.write(', "' + row[3].strip() + '"')
    
    # 2. Two sub-categories
    elif compare_id == 1:

    	for row in rows:
    		
    		# We only need the structure of one administrative area
    		if int(row[2]) != aaid:
    			break
    		# Last number of 'ordem' indicates which level we're dealing with
    		last_no = (row[0])[-1:]
    		
    		# On the first two rows, the category name will always be 'Total'
    		if first_cat:
    			category_name = 'total'
    			first_cat = False
    		# Otherwise, if the 'ordem' finishes with one, we're dealing 
    		# with a top-level category and need to store it.
    		elif last_no == "1":
    			category_name = row[3].rsplit(' ', 1)[0].strip()
    		
    		# The sub-category is the last word of the string
    		sub_cat = (row[3].rsplit(' ', 1)[1])
    		
    		f.write(', "' + category_name + ' - ' + sub_cat + '"')

	# 3. No sub-category
    else:
    	# In this case we just print a header 'Total'
    	f.write(', Total')

    # Add a line ending
    f.write('\n')

# Done. Close the file.
f.close