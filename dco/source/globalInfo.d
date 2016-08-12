module dco.globalInfo;

import	std.datetime;

__gshared bool bGetLocal = false;

//DC
__gshared string strDCEnv,strDCEnvFile;

//build
__gshared string strConsole= " -L-su:console:4 ",strWindows = " -L-Subsystem:Windows ",strWindows64 = " -L-Subsystem:Windows -L-ENTRY:mainCRTStartup ",strAddArgs,strAddArgsdfl = " -de -w ",buildMode,strDebugDefault= " -debug",strImportDefault = " -I$(DMDInstallDir)windows/import ",targetTypeDefault = "lib",targetTypeShared = "shared";

__gshared string strTargetLib,SpecialLib = "",strWinLibs = " ole32.lib oleAut32.lib gdi32.lib Comctl32.lib Comdlg32.lib advapi32.lib uuid.lib ws2_32.lib kernel32.lib ",strWinLibs64 = " user32.lib "; 
	
__gshared string strOtherArgs,strAddLib,strTargetFileName,strTargetTypeSwitch,compileType;

__gshared bool	bUseSpecialLib = false,bDebug = true,bBuildSpecialLib = false,bCopy = false,bDisplayBuildStr = false,bDisplayCopyInfo = true,bForce = false;

__gshared SysTime sourceLastUpdateTime,targetTime;
//ini args
__gshared string strPackageName,strArgs,strTargetName,strTargetType = "exe",strDC = "dmd",strDCStandardEnvBin = "dmd2\\windows\\bin",strLibs ,strImport,strLflags,strDflags,strTargetLflags,strTargetPath,strObjPath;

__gshared bool	bInitINI = false,bAssignTarget = false;

__gshared string separator = "\\";

//readFile
__gshared string strDFile;

//help
__gshared bHelp =false,bVersion = false;