dco
====
dco is a build tool, it can build any projects on Windows,especially DFL2,now based on D2.071.1.
 
The latest features:
---
1、dfl or dgui can be build by dco,and auto copy files to lib or lib64 or bin folder.

2、dco can be used in Visual Studio .net (here VS 2010 and VS2015).

3、dco can be used by DUB:

 
How to get the libs or exe files:
---
1、 Double click the 'build.bat',to get them in the 'source' folder(now,auto copy to the '$(DMDInstallDir)windows\bin' folder ,with dco.ini).

2、dub fetch dco --local and run the build.bat in the path, to get them in this folder.
   or 
     dub fetch dco,and run the dubbuild.bat in the path(C:\Users\[yourUserName]\AppData\Roaming\dub\packages\dco-0.0.7)

3、Open the dco.sln, and run the projects to get them in 'debug' or 'release' folder(Now,auto copy to the '$(DMDInstallDir)windows\bin' folder ).
	 


dco.exe
---
'dco.exe' can create the batch processing info :

How to use the 'dco':
--- 
  dco ↓（Enter Key）

  dco -m64 ↓（Enter Key）

  dco app.d

  dco app.d -gui (for dfl or dgui)
  
if you build a bigger project,please config the local.ini(get it by 'dco -ini').

more help 
---

  Screenshot:
---
   build dco:

  ![build dco](https://raw.githubusercontent.com/FrankLIKE/dco/master/dco/Images/dco.png)

   dco help:

  ![dco help](https://raw.githubusercontent.com/FrankLIKE/dco/master/dco/Images/dco_help.png)
   
  

