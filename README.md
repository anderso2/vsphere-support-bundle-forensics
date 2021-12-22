# vsphere-support-bundle-forensics
Two Windows CMD scripts that unpack, merge and import the most important log files from a vCenter/ESXi Support Bundle to vRealize Log Insight instance. 

Also contains Log Insight dashboards to illustrate the most important events.

Instructions/prereqs are in the script comments. 

# Requirements:
 1. For importing to Log Insight: The Log Insight Importer utility installed and the IMPORTER path variable set below.
 2. The LISERVER variable needs to be populated with the FQDN or IP address of the Log Insight server
 3. 7-zip files need to be placed in the ZIP variable path below
 4. The log bundles to extract from (esx-*.tgz and/or vc-*.tgz) need to be placed in the 'Bundles' folder

Feel free to contribute.
