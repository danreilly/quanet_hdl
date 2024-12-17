@echo off

for /F "TOKENS=2 DELIMS=/ " %%A in ('date /T') do set M=%%A
for /F "TOKENS=3 DELIMS=/ " %%A in ('date /T') do set D=%%A
for /F "TOKENS=4 DELIMS=/ " %%A in ('date /T') do set YY=%%A
for /F "TOKENS=2 DELIMS=0" %%A in ( "%YY%" ) do set Y=%%A
set DIR=log\d%Y%%M%%D%

if not exist %DIR% (
  echo making %DIR% 
  mkdir %DIR%
)
set CTRF=%DIR%\ctr.txt
if not exist %CTRF% (
  echo "0"> %CTRF%
)

rem echo reading %CTRF%
set /p CTR=<%CTRF%
set /A CTR=CTR+1
echo %CTR% > %CTRF%

set F=%DIR%
scp -i "C:/reilly/proj/quanet/matlab/analog.txt.pub" -r analog@analog:/home/analog/ech/out %F%
rem scp -i "analog.txt" -r analog@analog:/home/analog/ech/out %F%

move %DIR%\out\r.txt %DIR%
move %DIR%\out\d.raw %DIR%
rename %DIR%\r.txt r_%CTR%.txt
rename %DIR%\d.raw d_%CTR%.raw

echo got %F%\d_%CTR%.raw and %F%\r_%CTR%.txt
