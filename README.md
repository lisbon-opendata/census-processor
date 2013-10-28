Census processor

===

## Background
The Portuguese census data is published on the [INE website](http://censos.ine.pt/xportal/xmain?xpid=CENSOS&xpgid=censos_quadros) in a series of Excel files. Though it is rather detailed - aggregated to the freguesia (parish) level - the format is not machine readable. This script will take any question from the census and processes it into a denormalized CSV. It will also produce the datapackage.json to describe the dataset.

This script was initially built for the [Views on Lisbon](https://github.com/lisbon-opendata/views-on-lisbon) project, but then made more general to be able to use it with any census issue.

## Limitations
The first version only processes the totals of each indicator. Any sub-totals included in columns are not taken into account for the time being.

## Usage
The script needs one argument to work: the question ID.

```bash xxx.sh -i [3-digit number] -o [output file-name]```

for example:

```bash xxx.sh -i 605 -i data-605.csv```