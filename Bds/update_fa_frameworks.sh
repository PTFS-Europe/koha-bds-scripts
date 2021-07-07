#!/bin/bash
:
echo "UPDATE biblio SET frameworkcode = 'BKFA' WHERE frameworkcode = 'FA';" | mysql
