# LRLeastPriv 
 
  ![Logo](https://www.coterie.global/uploads/2/4/8/8/24884661/logrhythm_orig.png)
  
This script will automatically configure Windows permissions for a LogRhythm system monitor agent running in least privilege mode. 
 
 
Before running the script be sure to add your serivce account to the `settings` section. 
 
 ```
################################# SETTINGS ########################################

#Set the name of your least privilage service account here
$ServiceAccount = "domain\username"

#If you agent is installed to non-standard location change these variables to match. 
$InstallDir = "C:\Program Files\LogRhythm\LogRhythm System Monitor"
$InstallReg = "HKLM:\SYSTEM\CurrentControlSet\services\scsm"

#################################################################################
 ```
 
After the script has run you must manually add your service account to the LogRhythm System Monitor serivce as normal.


@piratematerial on LR Forum
