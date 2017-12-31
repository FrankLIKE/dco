@cls
 
@echo  will get the  dco release version.....

cd source
dmd -ofdco.exe dco.d all.d buildExes.d checkInfo.d findDC.d globalInfo.d helpInfo.d operateFile.d readConfig.d -release
dco
cd..
@echo you can continue to get the 64 bit version...
@pause
cd source
dmd -ofdco.exe dco.d all.d buildExes.d checkInfo.d findDC.d globalInfo.d helpInfo.d operateFile.d readConfig.d -release -m64
dco
cd..
@pause
