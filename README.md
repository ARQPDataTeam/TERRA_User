## TERRA (Top-down Emission Rate Retrieval Algorithm)

written by Andrea Darlington, ECCC

Calculates the emission rate of a pollutant or the flux of the pollutant through a screen.
This repo contains files for users of TERRA that can be used after flights have been setup using the code in TERRA_setup repo: https://github.com/ARQPDataTeam/TERRA_Setup 

![](/TERRA.jpg)

## Install Requirements
You must install git to install TERRA.  This can be done by downloading the file here and running the installation (leave all options in the installer as the default):
https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe

## Installing TERRA
TERRA can be installed by running the TERRAInstall_UserOnly.cmd file located here (for ECCC users):
\\econl0lwpfsp001.ncr.int.ec.gc.ca\arqp_data\Resources\Software\Windows\Igor\Tool_Installers\
And in this repo for external users.

Ensure that all instances of Igor have been closed before running the installation file and if you encounter any errors please contact a member of the Data team at Équipe de données / Data Team (ECCC) equipededonnees-datateam@ec.gc.ca to assist with installation. 
Once installation is complete, open Igor Pro and choose Load TERRA from the Analysis menu.  TERRA will check for updates upon loading into an experiment file.  If any are available, they will be updated at this time.

## Instructions for Use
Instructions for using TERRA are available in the TERRA Instructions.docx file.

## Updating this Repo - For Developers Only
This repo exists also as a submodule of the TERRA_Setup repo.  When updates are made to these functions and pushed, it is necessary to update the TERRA_Setup repo using the command:
git submodule update --remote --merge
Then follow normal procedures to commit and push this update within TERRA_Setup.
