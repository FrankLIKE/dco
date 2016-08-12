///	
// Written in the D programming language.
/**
This is a build tool,compile *.d to exe or lib,and help to build dgui,dfl2 gui (or other you like).
now default DC is dmd ,default platform is windows.

If your DC is dmd, dco can start only 'dco.ini' config file. 

Compiler dco.d :dmd dco.d -release,and dco ↓,

Usage:
Config some info to 'dco.ini' file,';' or '#' means you can do as it.Then copy dco.ini to your PATH: such as dmd's config file:sc.ini.
And dco.exe can auto copy itsself to EnvPath,that also is  dmd.exe 's path: dmd2\window\bin.
After that,you can run the 'dco.exe'  anywhere.
If not found 'dco.ini',run: dco -ini,please.

For example:
to get the debug version( -release to get another)

build some *.d to lib or exe 			 : dco ↓
build some *.d to lib or exe for 64 bit	 : dco -m64 ↓
build  one app.d in many *.d    		 : dco app or  dco app.d
build for libs 	such as dfl,dgui         : dco  -lib
build for app.d use dgui,dfl2			 : dco  -gui
build app.d use dfl2 for console		 : dco  -con
build lib and copy to libs				 : dco -lib -copy
build by custom	and copy to libs         : dco -arg -addlib -lib -copy

if your exe's file works on console,you should add '-con' or '-console'. 

Copyright: Copyright FrankLIKE 2014-.

License:   $(LGPL-3.0).

Authors:   FrankLIKE

Source: $(dco.d)

Created Time:2014-10-27
Modify Time:2014-10-31~2016-08-12
*/
module dcoexe;
/// dco 
import dco.all;

void main(string[] args)
{
	if(!findDCEnv()) return;
	// readInJson();
	
	if(!checkArgs(args))
	{
		if(bHelp)
		{
			ShowUsage();
			return;
		}
		
		if(bVersion)
		{
			ShowVersion();
			return;
		}

		if(bInitINI)
		{
			initNewConfigFile();
			return;
		}

		if(!findFiles())
		{
			ShowUsage();
			return;
		}
	}
	if(args.length ==1)
	{
		if(!CheckBinFolderAndCopy()) return;
    }
 
	if(strPackageName =="")
	{
		strPackageName = strTargetName;
	}

	buildExe(args);
}
