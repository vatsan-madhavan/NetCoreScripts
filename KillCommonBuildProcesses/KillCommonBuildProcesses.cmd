@echo off
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0KillCommonBuildProcesses.ps1""" -AdditionalBuildProcesses git,sh,wish %*"
