@cls
 
@echo  will get the  dco release version.....

cd source
dmd dco.d -release
dco
cd..
@echo you can continue to get the 64 bit version...
@pause
cd source
dmd dco.d -release -m64
dco
cd..
@pause
