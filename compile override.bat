echo off
cls
del %~n1.smx
spcomp.exe %~n1.sp
pause