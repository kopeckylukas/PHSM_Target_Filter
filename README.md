# PHSM_Target_Filter
This repository contains a 'target filter' script used within the WHO's [Public Health and Social Measures](https://phsm.euro.who.int) project to validate data inputs. This script was developed at the [London School of Hygiene and Tropical Medicine](https://www.lshtm.ac.uk), University of London (LSHTM).
[Repository](https://github.com/lshtm-gis/WHO-PHSM) that contains the script to generate Severity Index/Stringency Indicator. 

## Introduction
Prior to producing the ‘Stringency Indicator’ using the concatenated ‘Mistress’ file, we filter out and correct misspelled and invalid target inputs to prevent bias in the SI file.

The target filter iterates through all records and searches WHO codes. If the codes are of interest, the script pulls out all targets for the given record and compares them to the taxonomy. Targets that match the taxonomy are passed as valid records (Fig 1). Targets that do not match the taxonomy are compared to our look-up table of misspelled/invalid targets that contain two columns – original and corrected. If the target matches the lookup table, it is corrected otherwise it is pulled out as an invalid target. 

List of invalid targets and their codes are retrieved as a CSV file for manual revision and correction. Corrected targets are added to the look-up table for future data runs.


<p align="center">
  <img width="460" height="400" src="https://github.com/kopeckylukas/PHSM_Target_Filter/blob/484d6e1df02ae954cf0053c69f2b58b760725a7a/diagram.png">
</p>



## Guide 
Run code line by line, code is commented to separate different sections. 

1.	Load libraries necessary 
2.	Load data necessary (change mistress’s file name if necessary)
3.	Load Functions
4.	Run ‘Clean Data’ Section - Run check_targets function. This might take up to 30 minutes, progress bar is shown below as an output.
5.	(Optional) Check for new invalid – Retrieves file of target that do not match taxonomy or look-up table. These files need to be manually corrected and added to ‘Data_CSV/lookup_dictionary.csv’ file.
  * NB to add files to lookup dictionary, add misspelled and corrected to a correct column
  * Add only one single target per record. In cases where generated file of new misspelled retrieves two or more targets per record, these targets must be corrected as separate records 
6.	Save data – This process transfers valid data to ‘targetted’ column and saves the filtered mistress as a CSV file. (NB filename accordingly)
7.	(Optional) To transfer filtered data permanently, use the ‘Transfer process’ section.    
