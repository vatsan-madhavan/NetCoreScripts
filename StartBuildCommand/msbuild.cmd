@echo off 
powershell -ExecutionPolicy ByPass -NoProfile -Command "& """%~dp0msbuild.ps1""" %*"
exit /b %ErrorLevel%