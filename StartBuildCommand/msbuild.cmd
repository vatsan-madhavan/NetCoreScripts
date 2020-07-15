@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0msbuild.ps1""" %*"
exit /b %ErrorLevel%