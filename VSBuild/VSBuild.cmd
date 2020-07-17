@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0VSBuild.ps1""" -Command %*"
exit /b %ErrorLevel%