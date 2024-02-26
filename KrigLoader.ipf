#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Analysis"
	"Load TERRA", /Q, LoadKrig()
End

Function LoadKrig()
	checkUpdates_TERRA()
	Execute/P/Q/Z "INSERTINCLUDE \"KrigData\" "
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

Function checkUpdates_TERRA()
	Variable yr, mon, day
	String upd
	String updateString, userDir
	
	//If user does setup of flights they will have a TERRA_Setup folder on their machine with TERRA_User as a submodule
	//In this case run TERRAUpdate.cmd from within the TERRA_Setup folder
	//If they do not setup flights they will not have a TERRA_Setup folder, only a TERRA_User folder
	//TERRAUpdate_UserOnly.cmd will be in the TERRA_User folder on the user's machine	
	userDir = SpecialDirPath("Igor Pro User Files", 0, 1, 0) + "User Procedures:TERRA_Setup:"
	NewPath/O/Q/Z userPath, userDir 
	
	//If path for setup folder was not found, look for the TERRA_User directory 
	if (V_flag)
		userDir = SpecialDirPath("Igor Pro User Files", 0, 1, 0) + "User Procedures:TERRA_User:"
		NewPath/O/Q/Z userPath, userDir 
		if (V_flag)
			Abort
		else
			updateString = "\"" + userDir + "TERRAUpdate_UserOnly.cmd\""
		endif
	
	else
		updateString = "\"" + userDir + "TERRAUpdate.cmd\""	
	
	endif
	
	//Replace colons with slash - the string must be split to do this as we don't want to replace the colon after the C directory, only in the rest of the file
	Variable length = strlen(updateString)
	String pathr = ReplaceString(":", updateString[3,length], "\\")
	String pathFinal = "\"C:" + pathr

	//Run the updater script
	ExecuteScriptText pathFinal

End

// OLD VERSION
//Function checkUpdates_TERRA()
//	Variable yr, mon, day
//	String upd
//	
//	String userDir = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + "User Procedures:terra:"
//	NewPath/O/Q/Z userPath, userDir 
//	if (V_flag)
//		Abort
//	endif
//	OpenNotebook/P=userPath/N=UpdateDate "TERRA_updateDate.txt"
//	Notebook UpdateDate, getData=2
//	sscanf S_value, "%4f-%2f-%2f", yr, mon, day
//	Variable userDate = date2secs(yr, mon, day)
//	DoWindow/K UpdateDate
//	
//	String updateDir = "\\\\wto-science-nas.to.on.ec.gc.ca\\arqp_data:Resources:Software:Windows:Igor:TERRA:"
//	NewPath/O/Q/Z updatePath, updateDir 
//	if (V_flag)
//		Execute/P/Q/Z "INSERTINCLUDE \"KrigData\" "
//		Execute/P/Q/Z "COMPILEPROCEDURES "
//		Abort
//	endif
//	OpenNotebook/P=updatePath/N=UpdateDate "TERRA_updateDate.txt"
//	Notebook UpdateDate, getData=2
//	sscanf S_value, "%4f-%2f-%2f", yr, mon, day
//	Variable updateDate = date2secs(yr, mon, day)	
//	DoWindow/K UpdateDate
//	
//	if (updateDate > userDate)
//		Prompt upd, "A new version of TERRA is available.  Do you want to update?", popup, "Yes;No"
//		DoPrompt "Update TERRA", upd
//		
//		if (V_flag)
//			Abort
//		endif
//	
//		if (CmpStr(upd, "Yes") == 0)
//			ExecuteScriptText "\"\\\wto-science-nas.to.on.ec.gc.ca\\arqp_data\Resources\Software\Windows\Igor\TERRA\TERRAUpdate.bat\""
//		endif	
//	endif
//
//End