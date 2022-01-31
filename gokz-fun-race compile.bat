@echo off
set file=%~nx0
set file=%file:~0,-11%.sp
"compile override.bat" %file%