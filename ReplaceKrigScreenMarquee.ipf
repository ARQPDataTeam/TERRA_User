#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


///Draw a marquee around the area you would like to replace (on ScreenU). 
///Right click and choose "Replace Selection" or choose from the "ReplaceKrigScreen" menu
///Enter the value you would like to replace this region with (you can use the Find Average Selection button
////in advance to get a value if you want)
///The screen will update and you can choose to keep the changes or revert to the original
///If you change your mind later you can reset ScreenU=Screen_Orig (Screen_Orig will be whatever screen was input when the function was called)
///Or to revert changes just re-load the krigged screens
///The region and value you used (and previous average) will be printed to the command line
///Use wisely


Menu "ReplaceKrigScreen"
	"Replace Selection", ReplaceKrigScreen()
End

Menu "GraphMarquee"
	"Replace Selection", ReplaceKrigScreen()
End

Function ReplaceKrigScreen()
ReplaceSelection()
DoUpdate
KeepChanges()
End

///Note that you can also revert to the original screen (screen before running function) by resetting ScreenU=Screen_Orig after the script has finished

Function ReplaceSelection()

Variable V_flag, V_left, V_top, V_bottom

GetMarquee /Z left, bottom
print "Relacing Selection"

print "s goes from", V_left, "to", V_right, " and z goes from", V_bottom, "to", V_top 

	Variable sst, zst, send, zend
	String ilist, image
	
	if (strlen(S_marqueeWin) > 0)
		ilist = ImageNameList(S_marqueeWin, ";") //ImageNameList returns a string containing a list of image names in the graph window
	else
		ilist = ImageNameList("", ";") 
	endif
	image = StringFromList(0, ilist)  //Sets image to the name of the active window
	Wave screenWv = $image
	Duplicate /O screenWv screen_orig

Variable repl_val
Prompt repl_val, "Enter replacement value: "
DoPrompt "Screen replacement", repl_val
if (V_flag !=0)  //if user hits cancel, exit function
	return -1
endif


sst=V_left
send=V_right
zst=V_bottom
zend=V_top
	
	
	Variable nsi, nzi, ns, nz
	Variable s, z
	Variable cSum = 0
	Variable nmPts = 0
	Variable cAvg = 0
	SVAR unitStr
	NVAR ds, dz  //ds=40 and dz=20

	nsi = round(send/ds)
	nzi = round(zend/dz)
	ns = round(sst/ds)
	nz = round(zst/dz)

Print "nsi = ", nsi
Print "nzi = ", nzi
Print "ns = ", ns
Print "nz = ", nz

	
	if (nsi > dimSize(ScreenWv,0))
		nsi = dimSize(ScreenWv,0)
	endif
	
	if (nzi > dimSize(ScreenWv,1))
		nzi = dimSize(ScreenWv,1)
	endif

	for (s = ns; s < nsi ; s += 1)
		for (z = nz; z < nzi; z += 1)
			if (numtype(ScreenWv[s][z]) == 0)
				cSum = cSum + ScreenWv[s][z]
				nmPts = nmPts + 1
			endif
		endfor
	endfor
	
	cAvg = cSum/nmPts
	Print "Average concentration before replacement was", cAvg, unitStr
	Print "Replacement concentration is", Repl_val, unitStr

for (s = ns; s < nsi ; s += 1)
		for (z = nz; z < nzi ; z += 1)
			if (numtype(ScreenWv[s][z]) == 0)
				ScreenWv[s][z]=repl_val
				
			endif
		endfor
	endfor



End
Function KeepChanges()

String YesNo
Prompt YesNo, "Do you want to keep changes? Y/N "
DoPrompt "Keep changes?", YesNo
if (V_flag !=0)  //if user hits cancel, exit function
	return -1
endif


WAVE ScreenU, Screen_Orig

	if (CmpStr(YesNo, "Y", 0)==0)
	else
	ScreenU=Screen_Orig
	endif

End

