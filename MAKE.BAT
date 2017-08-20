@echo off
echo actions...
copy %1 asd.exe > nul
unp asd.exe > nul
check > nul
if not errorlevel 1 goto next
unp x asd.exe > nul
echo convetred to exe
:next
echo decoded
copy tail.org tail.com > nul
trace.com > nul
echo patched
encrypt.com > nul
echo crypted
com2end asd.exe tail.com > nul
del tail.com > nul
dcrypt asd.exe > nul
del asd.bak > nul
echo ok
echo debug protected
copy asd.exe %1 > nul
del asd.exe > nul
echo complete
 
