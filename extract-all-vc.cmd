@echo off

REM TODO: Fix hostname issue when importing from hosts with - in their name
REM TODO: Add more log sources from https://williamlam.com/2019/04/enhanced-vcenter-server-audit-event-logging-in-vsphere-6-7-update-2.html

REM This script is only for vCenter bundles. Use the separate script for ESXi bundles.

REM Requirements:
REM 1. For importing to Log Insight is the Log Insight Importer utility installed and the IMPORTER variable set below.
REM 2. 7-zip files need to be placed in the ZIP variable path below
REM 3. The log bundles to extract from (esx-*.tgz and/or vc-*.tgz) need to be placed in the 'bundles' folder

SET BASEPATH=C:\Temp\log_extraction\bundles
SET ZIP=C:\Temp\log_extraction\7zip\7z.exe
SET IMPORTER=C:\Program Files (x86)\VMware\Log Insight Importer\loginsight-importer.exe
SET LISERVER=ENTER-IP-ADDRESS-OR-FQDN-HERE
REM SET LIPWSTRING=--password ENTERPASSWORDHERE

REM If the Log Insight admin password string above is blank (default), you will get prompted on import, 
REM which is more secure than typing it in cleartext here. You can also set it yourself at the command line.

cd /d "%BASEPATH%"

echo.
echo =================================
echo Unpacking vCenter support bundles 
echo =================================

for /f "tokens=*" %%d in ('dir /b "%BASEPATH%\vc-*.tgz"') do (
	echo %%d
	tar -xf %%d
)


echo.
echo ===========================================================================
echo Looping through each unpacked vc- folder for additional unpacking of files
echo ===========================================================================

for /f "tokens=*" %%d in ('dir /b /a:d "%BASEPATH%\vc-*"') do (

	SET LFOLDER=opt\vmware\var\log\lighttpd\
	echo.
	echo =============================================================
	echo Unpacking and appending all *.gz log files in %%d\%LFOLDER%
	echo =============================================================

	cd /d "%BASEPATH%\%%d\opt\vmware\var\log\lighttpd\"

	for /f "tokens=*" %%f in ('dir /b *.gz') do (

		echo Unpacking \opt\vmware\var\log\lighttpd\%%f
		"%ZIP%" e %%f -bso0

		for /f "tokens=1-3 delims=\." %%n in ("%%f") do (
			echo Appending \opt\vmware\var\log\lighttpd\%%n.%%o to %%n.log
			type %%n.%%o >> %%n.log
			del %%n.%%o.gz
			del %%n.%%o
		)
		
	)

	SET LFOLDER=var\log\vmware\rhttpproxy\
	echo.
	echo =============================================================
	echo Unpacking and appending all *.gz log files in %%d\%LFOLDER%
	echo =============================================================

	cd /d "%BASEPATH%\%%d\var\log\vmware\rhttpproxy\"

	type rhttpproxy-*.log >> rhttpproxy.log

	for /f "tokens=*" %%f in ('dir /b *.gz') do (

		echo Unpacking \var\log\vmware\rhttpproxy\%%f
		"%ZIP%" e %%f -bso0

		for /f "tokens=1-3 delims=\." %%n in ("%%f") do (
			echo Appending \var\log\vmware\rhttpproxy\%%n.%%o to rhttpproxy.log
			type %%n.%%o >> rhttpproxy.log
			del %%n.%%o.gz
			del %%n.%%o
	 	)
	)
	
	echo Appending and deleting the unpacked log file..
	type rhttpproxy-*.log  >> rhttpproxy.log 
	del rhttpproxy-*.log

	echo.
	echo ==================================================
	echo Copying websso.log to a folder for later importing
	echo ==================================================

	SET LFOLDER=var\log\vmware\sso\
	cd /d "%BASEPATH%\%%d\var\log\vmware\sso\"
	
	for /f "tokens=*" %%f in ('dir /b websso-*') do (

		for /f "tokens=1-3 delims=\." %%n in ("%%f") do (
			echo Appending \var\log\vmware\sso\%%n.%%o to websso.log
			type %%n.%%o >> websso.log
			del %%n.%%o		
	 	)	
	)	

	REM Copy the websso.log file to the utils folder, which will get imported later
	move websso.log utils\


	echo.
	echo ==================================================
	echo Renaming and appending messages.log for later importing
	echo ==================================================

	SET LFOLDER=var\log\vmware\
	cd /d "%BASEPATH%\%%d\var\log\vmware\"
	
	for /f "tokens=*" %%f in ('dir /b messages.*') do (

		for /f "tokens=1-3 delims=\." %%n in ("%%f") do (
			echo Appending \var\log\vmware\%%n.%%o to messages.log
			type %%n.%%o >> messages.log
			del %%n.%%o		
	 	)	
	)
	
	REM Copy the messages.log file to the sso\utils folder, which will get imported later
	move messages.log sso\utils


	echo.
	echo ==================================================
	echo Moving vpxd-svcs files to separate folder for later importing
	echo ==================================================
	
	cd /d "%BASEPATH%\%%d\var\log\vmware\vpxd-svcs"

	mkdir import
	move authz-event.log import

	cd /d "%BASEPATH%\%%d\var\log\vmware\vpxd-svcs"


	echo.
	echo ===========================================================================
	echo Importing each folder containing the unpacked log bundles to Log Insight
	echo ===========================================================================

	REM Also tagging each import with the correct hostname using 'hostname' tag
	REM Authentication to Log Insight is needed in order to import the correct time stamps
	REM The files in the 'commands' folder, if included, do not contain time stamps, so they will all get the same time stamp

	cd /d "%BASEPATH%\%%d"

	for /f "tokens=2 delims=-" %%h in ("%%d") do (
	
		"%IMPORTER%" --source .\opt\vmware\var\log\lighttpd  --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\log\vmware\rhttpproxy --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\log\vmware\vsphere-client\logs\access --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\log\vmware\sso\utils --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\log\vmware\vpxd-svcs\import --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\log\vmware\vsphere-client\logs\access --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		

		REM Populate the LIPWSTRING variable at the top of this script if you don't want to be prompted for every folder import.
		REM The lines above can be re-run with more paths if needed. The current selection are the most relevant ones.

	)
)

cd /d "%BASEPATH%\.."
