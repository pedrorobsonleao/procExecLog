@echo off
::--------------------------------------------------------------------------------
:: procExecLog - proccess executer logger
::
:: author: pedro.leao@gmail.com - 2020/10/18
::
:: Run your process with full traceability.
:: Its execution with event view, text logs and slack notifications
::--------------------------------------------------------------------------------
setlocal EnableDelayedExpansion

:: set variable environment
set application_label=%1
set application=%2
set program_home=%~dp0

set program=%~nx0
set program=%program:~0,-4%

set errormessage=

set logdir=%program_home%\log

:: read slack configuration
call :slack_config

:: create log dir
mkdir %logdir% 2> NUL

:: parse parameters
shift
	
set "args="
:parse
if "%~1" neq "" (
	set args=%args% %1
	shift
	goto :parse
)

if defined args set args=%args:~1%

:: validate parameters
if "%slack_channel%" neq "" (
	if "%args%" neq "" (
		call :run
		exit /b %error%
	)
)
call :usage
goto :eof

::-------------------------
:: Aux Functions
::-------------------------

:: time format function
:timef
set hour=%time:~0,2%
if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
set min=%time:~3,2%
if "%min:~0,1%" == " " set min=0%min:~1,1%
set secs=%time:~6,2%
if "%secs:~0,1%" == " " set secs=0%secs:~1,1%

set timef=%hour%%min%%secs%
goto :eof

:: date format function
:datef
set year=%date:~-4%
set month=%date:~3,2%
if "%month:~0,1%" == " " set month=0%month:~1,1%
set day=%date:~0,2%
if "%day:~0,1%" == " " set day=0%day:~1,1%

set datef=%year%%month%%day%
goto :eof

:: run command function
:run	
call :timef
call :datef

set startTime=%time: =0%
set start_time=%datef% %timef%
set aut_start_time=%date% %time%
set error_file=%logdir%\%application%-ERROR-%datef%-%timef%.log

%args% > NUL 2>> %error_file%

set error=%errorlevel%

set /p errormessage= < %error_file%
	
call :timef
call :datef
set endTime=%time: =0%
set end_time=%datef% %timef%
set aut_end_time=%date% %time%

call :Elapsed
call :logger
goto :eof

:: read slack config	
:slack_config
set slack_conf=%program_home%\config-slack.bat
if exist  %slack_conf% (
	call %slack_conf%
)
goto :eof

:: logger
:logger
if %error% NEQ 0 (
	set status=ERROR
	set http_status=500
	set message=%SLACK_ERROR%
	EVENTCREATE /T ERROR /L APPLICATION /ID 100 /D "command:[%args%] logfile:[%error_file%] error:[%errormessage%]" > NUL 2>&1
) else (
	set status=SUCCESS
	set http_status=200
	set message=%SLACK_SUCCESS%
)

set log_file=%logdir%\access-%datef%.log

REM set log_line=%start_time% %end_time% %Elapsed% %status% %error% %application% %application_label% %USERNAME% "%args%" "%errormessage%"

call :Elapsed_seconds
set log_line=127.0.0.1 - %USERNAME% [%aut_start_time%] "POST http://command/%application% HTTP/1.1" %http_status% %Elapsed_seconds% cmd=%args: =+% - %Elapsed_seconds% "-" "%aut_end_time% %Elapsed% %status% %error% %application_label% [%args%] [%errormessage%]"

echo %log_line%
echo %log_line% >> %log_file%

set message=%message% *_%application%_* start:`%aut_start_time%` end:`%aut_end_time%` elapsed:`%Elapsed%` user:`%USERNAME%` *%COMPUTERNAME%* `%args:\=\\%` `%error%` _%errormessage%_

goto :post_slack
goto :eof

:: Elapsed
:Elapsed

rem Get elapsed time:
set "end=!endTime:%time:~8,1%=%%100)*100+1!"  &  set "start=!startTime:%time:~8,1%=%%100)*100+1!"
set /A "elap=((((10!end:%time:~2,1%=%%100)*60+1!%%100)-((((10!start:%time:~2,1%=%%100)*60+1!%%100), elap-=(elap>>31)*24*60*60*100"

rem Convert elapsed time to HH:MM:SS:CC format:
set /A "cc=elap%%100+100,elap/=100,ss=elap%%60+100,elap/=60,mm=elap%%60+100,hh=elap/60+100"

set Elapsed=%hh:~1%%time:~2,1%%mm:~1%%time:~2,1%%ss:~1%%time:~8,1%%cc:~1%
goto :eof

:: sent to slack
:post_slack
set curl=%program_home%\curl\bin\curl.exe

if %SLACK_URL% NEQ "" (
	if exist %curl% (
		%curl% -H "Content-type: application/json" --data "{\"text\":\"%message%\",\"channel\":\"%SLACK_CHANNEL%\",\"username\":\"%application_label:"=%\",\"icon_emoji\":\"%SLACK_ICON%\"}" %SLACK_URL% > NUL 2>&1
	)
)

goto :eof

:: usage
:usage
echo Use: %program% [slack label] [command and parameters]
goto :eof

:: Elapsed_seconds
:Elapsed_seconds

set h=%Elapsed:~0,2%
set m=%Elapsed:~3,2%
set s=%Elapsed:~6,2%

set /A Elapsed_seconds=(s+(m*60)+(h*(60*60)))*1000
goto :eof
