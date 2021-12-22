@echo off

REM This script is only for ESXi bundles. Use the separate script for vCenter bundles.

REM TODO: Handle esxi host names with - better when importing and setting 'hostname' tag

REM Requirements:
REM 1. For importing to Log Insight is the Log Insight Importer utility installed and the IMPORTER variable set below.
REM 2. 7-zip files need to be placed in the ZIP variable path below
REM 3. The log bundles to extract from (esx-*.tgz and/or vc-*.tgz) need to be placed in the 'bundles' folder


SET BASEPATH=C:\Temp\Log_extraction\bundles
SET ZIP=%BASEPATH%\..\7zip\7z.exe
SET IMPORTER=C:\Program Files (x86)\VMware\Log Insight Importer\loginsight-importer.exe
SET LISERVER=ENTER-IP-ADDRESS-OR-FQDN-HERE
REM SET LIPWSTRING=--password ENTERPASSWORDHERE

REM If the Log Insight admin password string above is blank (default), you will get prompted on import, 
REM which is more secure than typing it in cleartext here. You can also set it yourself at the command line.

cd /d "%BASEPATH%"

echo.
echo ===============================
echo Unpacking ESXi support bundles 
echo ===============================

for /f "tokens=*" %%d in ('dir /b "%BASEPATH%\esx-*.tgz"') do (
	echo %%d
	tar -xf %%d
)


echo.
echo ===========================================================================
echo Looping through each unpacked esx- folder for additional unpacking of files
echo ===========================================================================

for /f "tokens=*" %%d in ('dir /b /a:d "%BASEPATH%\esx-*"') do (

	echo.
	echo =============================================================
	echo Unpacking and appending all *.gz log files in %%d\var\run\log
	echo =============================================================

	cd /d "%BASEPATH%\%%d\var\run\log\"

	for /f "tokens=*" %%f in ('dir /b *.gz') do (

		echo Unpacking \var\run\log\%%f
		"%ZIP%" e %%f -bso0

		for /f "tokens=1-3 delims=\." %%n in ("%%f") do (
			echo Appending \var\run\log\%%n.%%o to %%n.log
			type %%n.%%o >> %%n.log
			del %%n.%%o.gz
			del %%n.%%o
		)
		
	)

	cd /d "%BASEPATH%\%%d"

	echo.
	echo ===========================================================================
	echo Importing each folder containing the unpacked log bundles to Log Insight
	echo ===========================================================================

	REM Also tagging each import with the correct hostname using 'hostname' tag
	REM Authentication to Log Insight is needed in order to import the correct time stamps
	REM The files in the 'commands' folder, if included, do not contain time stamps, so they will all get the same time stamp
		
	for /f "tokens=1 delims=." %%h in ("%%d") do (
	
		"%IMPORTER%" --source .\var\log --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"
		"%IMPORTER%" --source .\var\run\log --server %LISERVER% --honor_timestamp --username admin %LIPWSTRING% --tags "{ \"hostname\" : \"%%h\"}"

		REM Populate the LIPWSTRING variable at the top of this script if you don't want to be prompted for every folder import.
		REM The lines above can be re-run with more paths if needed. The current selection are the most relevant ones.

	)
)


cd /d "%BASEPATH%\.."
