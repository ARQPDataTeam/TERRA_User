#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Covariance_Kriging"
#include "ExtrapolateUp"
#include "PlumeEmission"
#include "KrigData_2013"
#include <CustomControl Definitions>

// TERRA: Top-down Emission Rate Retrieval Algorithm
// Version 5.0
// Updated 2019-06-26

Menu "Analysis"
	Submenu "TERRA"
		//Use premade weights and no variogram (range = 300, nugget = 0, sill = 1)
		"Run quick kriging: box flights", quickKrig()	
		"Run quick kriging: screen flights", quickKrigScreen()	
		//Choose range, nugget and sill from variogram, then run full kriging	
		"Run variogram and full kriging: box flights", fullKrig()
		"Run variogram and full kriging: screen flights", fullKrigScreen()
		//Display history
		"Show kriging history", TableHistory()
		//Display plots
		"Show plots", reloadGraphs()
		"Show plots: screen flights", reloadGraphsScreen()
	End
End


//Use premade weights and no variogram (range = 300, nugget = 0, sill = 1)
Function quickKrig ()
	String fltNum, flight, fltF
	String cont
	Variable fitType, i
	Variable/G height = 300
	Variable/G maxC = 2
	String/G fltName, dtNm, dataNm, betwPts, dataType, location, unitStr
	Variable/G units = -9
	Variable/G fltItem
	Variable/G totLat = NaN, totTop = NaN, massEm = NaN
	String/G unitlist = "ppm;ppb;ppt"
	String ellNum, filePre, fileSuf, year, month, day
	
	if (exists("smpInt") == 0)
		Variable/G smpInt = 1
	else
		NVAR smpInt
	endif
	
	if (exists("Mc") == 0)
		Variable/G Mc = 28.97
	else
		NVAR Mc
	endif
	
	if (exists("background") == 0)
		Variable/G background = 0
	else
		NVAR background
	endif	
	
	if (CmpStr(dataType,"Particles") == 0)
		unitlist = "ug/m^3"
	endif
	
	if (exists("bs") == 0)
		String/G bs = "box"
	else
		SVAR bs
		if (CmpStr(bs,"screen") == 0)
			fltName = ""
			bs = "box"
		endif
	endif
	
	if (exists("projNm") == 0)
		String/G projNm = "2013"
	else
		SVAR projNm
	endif
	
	//Close any open graph windows if they exist
	String graphlist = WinList("GraphSurface1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphSurface1
	endif
	graphlist = WinList("GraphProfiles1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphProfiles1
	endif
	graphlist = WinList("PanelEmissions*", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow/Z PanelEmissions
		KillWindow/Z PanelEmissionsScreen
	endif
	String origList = WaveList("*original*",";","")
	for (i = 0; i < ItemsInList(origList); i += 1)
		KillWaves/Z $StringFromList(i, origList)
	endfor

	if (CmpStr(projNm,"2013") == 0)
		String/G fltList = "Flight 02;Flight 05;Flight 08;Flight 09;Flight 10;Flight 12 First Box;Flight 12 Second Box;Flight 12 Both Boxes;Flight 13 Full Facility;Flight 13 West Box;Flight 14;"
		fltList = fltList + "Flight 15 Syncrude Aurora;Flight 15 Shell;Flight 15 Suncor;Flight 17 First Box;Flight 17 Second Box;Flight 17 Both Boxes;Flight 18;Flight 21 Shell;Flight 21 Imperial;Flight 22"
		fltList = fltList + ";Flight 25 West Circle;Flight 25 East Circle;Flight 25 North Circle;Flight 26 South Circle;Flight 26 North Circle" 
		String/G fltCode = ""
	else
		String/G fltList = "Flight 03 Nexen;Flight 04 CNRL;Flight 04 Imperial;Flight 04 Firebag;Flight 06 CNRL;Flight 07 CNRL;Flight 08 CNRL;Flight 08 Fort Hills;"
		fltList = fltList + "Flight 08 Aurora;Flight 09 Firebag;Flight 09 Suncor;Flight 10 Syncrude;Flight 11 Suncor;Flight 12 Jackfish;Flight 12 MEG Christina Lake;"
		fltList = fltList + "Flight 12 Cenovus Christina Lake;Flight 13 Muskeg;Flight 15 Devon2;Flight 15 Devon1;Flight 15 SK4;Flight 15 SK3;Flight 15 SK2;Flight 15 SK1;"
		fltList = fltList + "Flight 15 SK5;Flight 16 Husky1;Flight 16 CNRL2;Flight 17 CNRL;Flight 17 YAJP Balloon;Flight 17 Syncrude Plume;Flight 18 Cenovus Foster Creek;"
		fltList = fltList + "Flight 18 Imperial Cold Lake;Flight 19 Syncrude;Flight 19 Suncor Mackay;Flight 20 Brion Energy;Flight 20 Syncrude;Flight 21 Imperial;Flight 21 Suncor;"
		fltList = fltList + "Flight 23 Imperial;Flight 23 Firebag;Flight 23 Brion Energy;Flight 28 Cenovus Foster Creek;Flight 28 Imperial Cold Lake;Flight 28 CNRL3;Flight 28 Husky2"
		String/G fltCode = "F03_Nexen;F04_CNRL;F04_Imperial;F04_Firebag;F06_CNRL;F07_CNRL;F08_CNRL;F08_FortHills;F08_Aurora;F09_Firebag;F09_Suncor;F10_Syncrude;F11_Suncor;F12_Jackfish;"
		fltCode = fltCode + "F12_MEGCL;F12_CenovusCL;F13_Muskeg;F15_Devon2;F15_Devon1;F15_SK4;F15_SK3;F15_SK2;F15_SK1;F15_SK5;F16_Husky1;F16_CNRL2;F17_CNRL;F17_Balloon;"
		fltCode = fltCode + "F17_SMLPlume;F18_Foster;F18_ICL;F19_Syncrude;F19_Mackay;F20_Brion;F20_Syncrude;F21_Imperial;F21_Suncor;F23_Imperial;F23_Firebag;"
		fltCode = fltCode + "F23_Brion;F28_Foster;F28_ICL;F28_CNRL3;F28_Husky2"
	endif
	
	//Prompt user for information
	NewPanel/N=Data /W=(700,158,1330,700)
	PopupMenu popupdt,pos={65,40},size={235,21},title="Choose date/time column: "
	PopupMenu popupdt,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dtNm
	PopupMenu popupdata,pos={65,80},size={211,21},title="Choose data column: "
	PopupMenu popupdata,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dataNm
	PopupMenu popupproj,pos={65,120},size={135,21},title="Choose project: "
	PopupMenu popupproj,mode=1,value="2013;2018",proc=PopupProj,popvalue=projNm
	PopupMenu popupflt,pos={65,160},size={135,21},title="Choose flight: "
	PopupMenu popupflt,mode=1,value= #"fltList",popvalue=fltName
	SetVariable setvarsmp,pos={65,200},size={200,16},title="Enter sampling interval (in s): "
	SetVariable setvarsmp,limits={1,inf,1},value= smpInt, proc=SetVarSampInt
	PopupMenu popupfill,disable=1,pos={500,240},size={47,21}
	PopupMenu popupfill,mode=1,value= "NaN;Value",popvalue=betwPts
	if (smpInt > 1)
		PopupMenu popupfill,disable=0
		SetDrawLayer UserBack
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,245,"Between the points recorded by the instrument, do you want to insert NaNs or assume "
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,260,"that the instrument read value continues to be valid until the subsequent reading? "
	endif
	PopupMenu popuptype,pos={65,280},size={240,12},mode=1,value="Gas;Particles",proc=PopupGP,title="What type of data is being loaded? ",popvalue=dataType	
	SetVariable setvarmass,pos={65,320},size={300,16},title="Enter the molar mass of the quantity (g/mol): "
	SetVariable setvarmass,limits={0,inf,1},value= Mc
	SetVariable setvarbg,pos={65,360},size={350,16},title="Enter the background value (enter 0 if this is unknown): ",limits={0,inf,1},value=background
	PopupMenu popupunit,mode=1,pos={65,400},size={300,16},title="What units are your data in? ", value=#"unitlist",popvalue=unitStr
	PopupMenu popuploc,pos={65,440},mode=1,size={300,16},title="Where do you want to load weights from?", value="Online;Local",popvalue=location
	Button buttonOK,pos={100,490},size={50,20},proc=ButtonPanOK,title="OK"
	Button buttonCanc,pos={435,490},size={50,20},proc=ButtonPanCanc,title="Cancel"
	PauseForUser Data
	
	Wave dt = $dtNm
	Wave data = $dataNm
	
	//If the sampling interval is not 1 then run the function to create a 1 second time series for that data
	if (smpInt < 1)
		Abort "Sampling interval is too small."
	elseif (smpInt > 1)		
		if (CmpStr(betwPts, "Value") == 0)
			createNewTimeSeries(dtNm, dataNm, smpInt)
			Wave dt = dt1sec
			Wave data = data1sec
		endif
	endif	
	
	String flightNumber, format, desc
	
	//2013 Campaign
	if (CmpStr(projNm,"2013") == 0)			
		//Get the flight number
		format = "%s %s"
		sscanf fltName, format, flight, fltNum
		
		flightNumber = "Flight" + num2str(str2num(fltNum))
		
		if (str2num(fltNum) == 13)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "West") == 0)
				fltNum = "13C"
			elseif (CmpStr(fltF, "East") == 0)
				fltNum = "13B"
			else
				fltNum = "13A"
			endif
		elseif (str2num(fltNum) == 15)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Suncor") == 0)
				fltNum = "15C"
			elseif (CmpStr(fltF, "Shell") == 0)
				fltNum = "15B"
			else
				fltNum = "15A"
			endif
		elseif (str2num(fltNum) == 21)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Imperial") == 0)
				fltNum = "21B"
			else
				fltNum = "21A"
			endif
		elseif (str2num(fltNum) == 17)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Both") == 0)
				fltNum = "17C"
			elseif (CmpStr(fltF, "Second") == 0)
				fltNum = "17B"
			else
				fltNum = "17A"
			endif
		elseif (str2num(fltNum) == 12)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Both") == 0)
				fltNum = "12C"
			elseif (CmpStr(fltF, "Second") == 0)
				fltNum = "12B"
			else
				fltNum = "12A"
			endif
		elseif (str2num(fltNum) == 25)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "West") == 0)
				ellNum = "01"
			elseif (CmpStr(fltF, "East") == 0)
				ellNum = "02"
			elseif (CmpStr(fltF, "North") == 0)
				ellNum = "03"
			else
				ellNum = "04"
			endif
		elseif (str2num(fltNum) == 26)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "North") == 0)
				ellNum = "01"
			else
				ellNum = "02"
			endif
		endif
	
		//Load in the premade Igor binary files
		if (CmpStr(fltNum, "25") == 0 || CmpStr(fltNum, "26") == 0)
			filePre = "F" + fltNum
			fileSuf = "E" + ellNum
		else
			filePre = "F" + fltNum
			fileSuf = "F" + fltNum
		endif
	//	print ":" + filePre + ":timestamp_" + fileSuf + ".ibw"
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Frame_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirFM_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":massInfo_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":weights_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":weightsLoc_" + fileSuf + ".ibw")
		
	//2018 Campaign
	elseif (CmpStr(projNm,"2018") == 0)
		fltItem = WhichListItem(fltName,fltList)
		filePre = StringFromList(fltItem,fltCode)
		fileSuf = filePre
		
		format = "%3s_%s"
		sscanf filePre, format, fltNum, desc		
		flightNumber = fltNum
		
		//Load in the premade Igor binary files
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirFM_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":massInfo_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
		LoadData/O/Q/P=OS (":" + filePre + ":weights_" + fileSuf + ".pxp")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Frame_" + fileSuf + ".ibw")
	endif

	//Move ScreenFlux to ScreenAirFlux
	Wave ScreenFlux
	Duplicate/O ScreenFlux, ScreenAirFlux
	KillWaves/Z ScreenFlux
//	PT_FlightTimes()
	
	//Load varValues values into the appropriate variables
	Wave varValues
	Variable/G ns = varValues[0]
	Variable/G nz = varValues[1] 
	Variable/G ds = varValues[2]
	Variable/G dz = varValues[3]
	Variable/G index = floor(ns/ds) 
	Variable/G indmax = floor(ns/ds)
	
	//Create the PositionSZC wave (consists of position and concentration during the flight)
	createConcWv (dt, data)
	Wave PositionSZC, Concentration, timestamp
	WaveStats/Q Concentration
	if (V_numNaNs != 0)
		fillNaNsTS(timestamp, Concentration)
	endif
	
	//If there are no points then the times did not match up and the wrong flight has been chosen
	Duplicate/O/R=(0,dimSize(PositionSZC,0))(2,2) PositionSZC, quantTemp
	WaveStats/Q quantTemp
	if (V_npnts == 0)
		Abort "You have selected the wrong flight number"
	endif
	KillWaves/Z quantTemp
	
	//Create link to flight path for PanelEmissions
	Wave timestamp
	String dateSt = date2str(timestamp[0])
	format = "%4s-%2s-%2s"
	sscanf dateSt, format, year, month, day
	String/G flightPathLoc
	
	if (CmpStr(projNm, "2013") == 0)
		if (CmpStr(month, "08") == 0)
			month = "Aug"
		else
			month = "Sep"
		endif
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM\\Level_0_RAW\\AIRCRAFT\\Plots\\OS2013_" + month + day + "_" + flightNumber + "_Map.jpg"
	elseif (CmpStr(projNm, "2018") == 0)
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM_2018\\AIRCRAFT\\Metadata\\Maps\\" + flightNumber + "_FlightTrack.jpg"
	endif	
	
	//Run the kriging routine and create a screen of the results
	runInterpNoPrompt ()
	Wave intVal
	Wave fltGridPts
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
	Redimension/N=-1 xWv, yWv
	Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
	Wave ScreenKrig, ScreenWindEf, ScreenWindNf, ScreenAirf, Frame
	
	//If there is an extra line, delete it
	if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
		DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
	endif

	UnfillAboveData()
	Unfill()												//Unfill the screen above and below the flight path
	Wave ScreenU
	SVAR unitStr
	
	if (CmpStr(unitStr, "ug/m^3") == 0)	
		Duplicate/O PositionSZC, PositionSZC_oldUnits
		Duplicate/O ScreenU, ScreenU_ugm3
		convertP_Units()
		runInterpNoPrompt()
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
		Redimension/N=-1 xWv, yWv
		Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
		if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
			DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
		endif
		UnfillAboveData()
		Unfill()
		Duplicate/O ScreenU, ScreenU_ppb
		Duplicate/O ScreenU_ugm3, ScreenU
	endif
	
	KillWaves/Z weights, weightsLoc
	
	Variable num = dimSize(ScreenKrig,0)
	
	Wave ScreenPosZ
	
	if (CmpStr(projNm,"2018") == 0)				//2018 campaign
	
		ProfilesOther()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C			
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp(height)									//Calculate the exponential fits
		ResetProfiles()										//Go to the previous point
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")	
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR	
		
		FillAboveData()
		TopValue()											//Get values for top of the screen
		Fill()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface
		
	else												//2013 campaign
	
		ProfilesOther_2013()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine_2013(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C			
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp_2013(height)									//Calculate the exponential fits
		ResetProfiles_2013()										//Go to the previous point
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")	
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR	
		
		FillAboveData()
		TopValue()											//Get values for top of the screen
		Fill_2013()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface	
		
	endif
	
	Make/D/O/N=(floor(ns/ds)) UserBase = NaN	
	SetScale/P x 0,40,"", UserBase
	Make/T/O/N=(floor(ns/ds)) Fit_Flag = ""
	Execute "GraphSurface()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	createRatios("GraphSurface1")
	Wave widRatio, heiRatio, vPosRatio, hPosRatio
	Duplicate/O widRatio, GraphSurface1_sR
	Duplicate/O heiRatio, GraphSurface1_zR
	Duplicate/O hPosRatio, GraphSurface1_hR
	Duplicate/O vPosRatio, GraphSurface1_vR
	if (str2num(fltNum) == 25 || str2num(fltNum) == 26 || cmpstr(fltNum,"F15") == 0 || cmpstr(filePre,"F17_Balloon") == 0 || cmpstr(filePre,"F17_SMLPlume") == 0  || cmpstr(filePre,"F28_CNRL3") == 0 || cmpstr(filePre,"F28_Husky2") == 0)		//Calculate label locations
		Make/O/N=4 labelLoc
		for (i = 0; i < 4; i += 1)
			labelLoc[i] = Frame[i][0]
		endfor
		Tag/C/N=text2/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text5/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[3], "South"
	elseif (dimSize(Frame,0) == 5)							
		Make/O/N=4 labelLoc
		for (i = 0; i < 4; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "South"
	elseif (dimSize(Frame,0) == 6)
		Make/O/N=5 labelLoc
		for (i = 0; i < 5; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text6/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "SouthWest"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[4], "South"		
	endif
	Execute "PanelEmissions()"

End

//Display a variogram and allow the user to choose range, sill and nugget, then krig data
Function fullKrig()
	String fltNum, flight, fltF
	String cont
	Variable fitType, i
	Variable/G height = 300
	Variable/G maxC = 2
	String/G fltName, dtNm, dataNm, betwPts, dataType, location, unitStr
	Variable/G units = -9
	Variable/G totLat = NaN, totTop = NaN, massEm = NaN
	String/G unitlist = "ppm;ppb;ppt"
	String ellNum, filePre, fileSuf, year, month, day
	
	if (exists("smpInt") == 0)
		Variable/G smpInt = 1
	else
		NVAR smpInt
	endif
	
	if (exists("Mc") == 0)
		Variable/G Mc = 28.97
	else
		NVAR Mc
	endif
	
	if (exists("background") == 0)
		Variable/G background = 0
	else
		NVAR background
	endif	
	
	if (CmpStr(dataType,"Particles") == 0)
		unitlist = "ug/m^3"
	endif

	if (exists("bs") == 0)
		String/G bs = "box"
	else
		SVAR bs
		if (CmpStr(bs,"screen") == 0)
			fltName = ""
			bs = "box"
		endif
	endif
	
	if (exists("projNm") == 0)
		String/G projNm = "2013"
	else
		SVAR projNm
	endif	
	
	//Close any open graph windows if they exist
	String graphlist = WinList("GraphSurface1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphSurface1
	endif
	graphlist = WinList("GraphProfiles1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphProfiles1
	endif
	graphlist = WinList("PanelEmissions*", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow/Z PanelEmissions
		KillWindow/Z PanelEmissionsScreen
	endif
	String origList = WaveList("*original*",";","")
	for (i = 0; i < ItemsInList(origList); i += 1)
		KillWaves/Z $StringFromList(i, origList)
	endfor

	String/G fltList = "Flight 02;Flight 05;Flight 08;Flight 09;Flight 10;Flight 12 First Box;Flight 12 Second Box;Flight 12 Both Boxes;Flight 13 Full Facility;Flight 13 West Box;Flight 14;"
	fltList = fltList + "Flight 15 Syncrude Aurora;Flight 15 Shell;Flight 15 Suncor;Flight 17 First Box;Flight 17 Second Box;Flight 17 Both Boxes;Flight 18;Flight 21 Shell;Flight 21 Imperial;Flight 22"
	fltList = fltList + ";Flight 25 West Circle;Flight 25 East Circle;Flight 25 North Circle;Flight 26 South Circle;Flight 26 North Circle" 
	String/G fltCode = ""
	
	//Prompt user for information
	NewPanel/N=Data /W=(700,158,1330,700)
	PopupMenu popupdt,pos={65,40},size={235,21},title="Choose date/time column: "
	PopupMenu popupdt,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dtNm
	PopupMenu popupdata,pos={65,80},size={211,21},title="Choose data column: "
	PopupMenu popupdata,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dataNm
	PopupMenu popupproj,pos={65,120},size={135,21},title="Choose project: "
	PopupMenu popupproj,mode=1,value="2013;2018",proc=PopupProj,popvalue=projNm
	PopupMenu popupflt,pos={65,160},size={135,21},title="Choose flight: "
	PopupMenu popupflt,mode=1,value= #"fltList",popvalue=fltName
	PopupMenu popuptype,pos={65,280},size={240,12},mode=1,value="Gas;Particles",proc=PopupGP,title="What type of data is being loaded? ",popvalue=dataType	
	SetVariable setvarmass,pos={65,320},size={300,16},title="Enter the molar mass of the quantity (g/mol): "
	SetVariable setvarmass,limits={0,inf,1},value= Mc
	SetVariable setvarbg,pos={65,360},size={350,16},title="Enter the background value (enter 0 if this is unknown): ",limits={0,inf,1},value=background
	PopupMenu popupunit,mode=1,pos={65,400},size={300,16},title="What units are your data in? ", value=#"unitlist",popvalue=unitStr
	PopupMenu popuploc,pos={65,440},mode=1,size={300,16},title="Where do you want to load weights from?", value="Online;Local",popvalue=location
	Button buttonOK,pos={100,490},size={50,20},proc=ButtonPanOK,title="OK"
	Button buttonCanc,pos={435,490},size={50,20},proc=ButtonPanCanc,title="Cancel"
	PauseForUser Data
	
	Wave dt = $dtNm
	Wave data = $dataNm
	
	//2013 Campaign
	if (CmpStr(projNm,"2013") == 0)	
		//Get the flight number
		String format = "%s %s"
		sscanf fltName, format, flight, fltNum
		
		String flightNumber = "Flight" + num2str(str2num(fltNum))
		
		if (str2num(fltNum) == 13)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "West") == 0)
				fltNum = "13C"
			elseif (CmpStr(fltF, "East") == 0)
				fltNum = "13B"
			else
				fltNum = "13A"
			endif
		elseif (str2num(fltNum) == 15)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Suncor") == 0)
				fltNum = "15C"
			elseif (CmpStr(fltF, "Shell") == 0)
				fltNum = "15B"
			else
				fltNum = "15A"
			endif
		elseif (str2num(fltNum) == 21)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Imperial") == 0)
				fltNum = "21B"
			else
				fltNum = "21A"
			endif
		elseif (str2num(fltNum) == 17)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Both") == 0)
				fltNum = "17C"
			elseif (CmpStr(fltF, "Second") == 0)
				fltNum = "17B"
			else
				fltNum = "17A"
			endif
		elseif (str2num(fltNum) == 12)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "Both") == 0)
				fltNum = "12C"
			elseif (CmpStr(fltF, "Second") == 0)
				fltNum = "12B"
			else
				fltNum = "12A"
			endif
		elseif (str2num(fltNum) == 25)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "West") == 0)
				ellNum = "01"
			elseif (CmpStr(fltF, "East") == 0)
				ellNum = "02"
			elseif (CmpStr(fltF, "North") == 0)
				ellNum = "03"
			else
				ellNum = "04"
			endif
		elseif (str2num(fltNum) == 26)
			format = "%s %s %s"
			sscanf fltName, format, flight, fltNum, fltF
			if (CmpStr(fltF, "North") == 0)
				ellNum = "01"
			else
				ellNum = "02"
			endif
		endif
	
		//Load in the premade Igor binary files
		if (CmpStr(fltNum, "25") == 0 || CmpStr(fltNum, "26") == 0)
			filePre = "F" + fltNum
			fileSuf = "E" + ellNum
		else
			filePre = "F" + fltNum
			fileSuf = "F" + fltNum
		endif
	
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Frame_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirFM_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":massInfo_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
		
	//2018 Campaign
	elseif (CmpStr(projNm,"2018") == 0)
		ControlInfo popupflt
		filePre = StringFromList(V_value,fltCode)
		fileSuf = filePre
		
		//Load in the premade Igor binary files
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Frame_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirFM_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":massInfo_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
	endif
	
	//Move ScreenFlux to ScreenAirFlux
	Wave ScreenFlux
	Duplicate/O ScreenFlux, ScreenAirFlux
	KillWaves/Z ScreenFlux
//	PT_FlightTimes()
	
	//Load varValues values into the appropriate variables
	Wave varValues
	Variable/G ns = varValues[0]
	Variable/G nz = varValues[1] 
	Variable/G ds = varValues[2]
	Variable/G dz = varValues[3]
	Variable/G index = floor(ns/ds) 
	Variable/G indmax = floor(ns/ds)
	
	//Create the PositionSZC wave (consists of position and concentration during the flight)
	createConcWv (dt, data)
	Wave PositionSZC
	
	//If there are no points then the times did not match up and the wrong flight has been chosen
	Duplicate/O/R=(0,dimSize(PositionSZC,0))(2,2) PositionSZC, quantTemp
	WaveStats/Q quantTemp
	if (V_npnts == 0)
		Abort "You have selected the wrong flight number"
	endif
	KillWaves/Z quantTemp
	
	//Create link to flight path for PanelEmissions
	Wave timestamp
	String dateSt = date2str(timestamp[0])
	format = "%4s-%2s-%2s"
	sscanf dateSt, format, year, month, day
	String/G flightPathLoc
	
	if (CmpStr(projNm, "2013") == 0)
		if (CmpStr(month, "08") == 0)
			month = "Aug"
		else
			month = "Sep"
		endif
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM\\Level_0_RAW\\AIRCRAFT\\Plots\\OS2013_" + month + day + "_" + flightNumber + "_Map.jpg"
	elseif (CmpStr(projNm, "2018") == 0)
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM_2018\\AIRCRAFT\\Metadata\\Maps\\" + flightNumber + "_FlightTrack.jpg"
	endif	
	
	//Create the variables with initial values and display the variogram of the data
	createVar()
	graphlist = WinList("VariogramPlot", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow VariogramPlot
	endif	
	variogram(PositionSZC, 30)
	PauseForUser VariogramPlot

	//After variable values have been selected on the plot, run the kriging
	runFullKrig()

	Wave intVal
	Wave fltGridPts
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
	Redimension/N=-1 xWv, yWv
	Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
	Wave ScreenKrig, ScreenWindEf, ScreenWindNf, ScreenAirf, Frame
	
	//If there is an extra line, delete it
	if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
		DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
	endif
	
	UnfillAboveData()
	Unfill()												//Unfill the screen above and below the flight path
	Wave ScreenU
	SVAR unitStr
	
	if (CmpStr(unitStr, "ug/m^3") == 0)	
		Duplicate/O PositionSZC, PositionSZC_oldUnits
		Duplicate/O ScreenU, ScreenU_ugm3
		convertP_Units()
		runInterpNoPrompt()
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
		Redimension/N=-1 xWv, yWv
		Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
		if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
			DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
		endif
		Unfill()
		Duplicate/O ScreenU, ScreenU_ppb
		Duplicate/O ScreenU_ugm3, ScreenU
	endif
	
	KillWaves/Z weights, weightsLoc
	
	Variable num = dimSize(ScreenKrig,0)
	
	Wave ScreenPosZ
	
	if (CmpStr(projNm,"2018") == 0)			//2018 campaign
	
		ProfilesOther()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp(height)									//Calculate the exponential fits
		ResetProfiles()										//Go to the previous point
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		TopValue()
		Fill()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface
		
	else											//2013 campaign
	
		ProfilesOther_2013()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine_2013(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp_2013(height)									//Calculate the exponential fits
		ResetProfiles_2013()										//Go to the previous point
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		TopValue()
		Fill_2013()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface

	endif
	
	Make/D/O/N=(floor(ns/ds)) UserBase = NaN
	SetScale/P x 0,40,"", UserBase
	Make/T/O/N=(floor(ns/ds)) Fit_Flag = ""
	Execute "GraphSurface()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	createRatios("GraphSurface1")
	Wave widRatio, heiRatio, vPosRatio, hPosRatio
	Duplicate/O widRatio, GraphSurface1_sR
	Duplicate/O heiRatio, GraphSurface1_zR
	Duplicate/O hPosRatio, GraphSurface1_hR
	Duplicate/O vPosRatio, GraphSurface1_vR
if (str2num(fltNum) == 25 || str2num(fltNum) == 26 || cmpstr(fltNum,"F15") == 0 || cmpstr(filePre,"F17_Balloon") == 0 || cmpstr(filePre,"F17_SMLPlume") == 0  || cmpstr(filePre,"F28_CNRL3") == 0 || cmpstr(filePre,"F28_Husky2") == 0)		//Calculate label locations
		Make/O/N=4 labelLoc
		for (i = 0; i < 4; i += 1)
			labelLoc[i] = Frame[i][0]
		endfor
		Tag/C/N=text2/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text5/F=0/B=1/X=0/Y=-60/L=0 top, labelLoc[3], "South"
	elseif (dimSize(Frame,0) == 5)							
		Make/O/N=4 labelLoc
		for (i = 0; i < 4; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "South"
	elseif (dimSize(Frame,0) == 6)
		Make/O/N=5 labelLoc
		for (i = 0; i < 5; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text6/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "SouthWest"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[4], "South"		
	endif
	Execute "PanelEmissions()"
	
End

//Create a 1 second time series for the data if the user has indicated that they want one
Function createNewTimeSeries(dtNm, dataNm, smpInt)
	String dtNm, dataNm
	Variable smpInt
	Variable count = 0
	Wave dt = $dtNm
	Wave data = $dataNm
//	Wave timestamp, PositionSZA
	Variable i, j
	
	//Create data and date/time waves
	Variable num = dimSize(dt,0)
	Make/O/N=(num*smpInt) data1sec = NaN
	Make/D/O/N=(num*smpInt) dt1sec = NaN
	
	//For each value in the original date/time wave, copy the data value into all data points between the initial time and 
	//a time one sampling interval after
	for (i = 0; i < num; i += 1)
		for (j = 0; j < smpInt; j += 1)
			if (i < num - 1)
				if (dt[i] + j >= dt[i+1])
					break
				endif
			endif
			data1sec[count] = data[i]
			dt1sec[count] = dt[i] + j
			count = count + 1
		endfor
	endfor
End

//Take date/time and data waves and convert them to a 3 column wave containing position and data value
Function createConcWv (dt, data)
	Wave dt, data
	Wave timestamp, PositionSZA
	Variable i, j
	Variable count = 0
	
	dt = trunc(dt)
	
	Duplicate/O PositionSZA, PositionSZC
	Make/D/O/N=(dimSize(timestamp,0)) Concentration = NaN
	PositionSZC[][2] = NaN
	Variable num = dimSize(dt,0)	
	
	for (i = 0; i < num; i += 1)
		if (count >= dimSize(timestamp,0))
			return 0
		endif
		if (timestamp[count] == dt[i])
			if (numtype(PositionSZC[count][0]) == 0)
				PositionSZC[count][2] = data[i]
			endif
			Concentration[count] = data[i]
			count = count + 1
		elseif (timestamp[count] < dt[i])
			do
				count = count + 1
				if (count >= dimSize(timestamp,0))
					break
				endif
			while (timestamp[count] < dt[i])
			if (count < dimSize(timestamp,0))
				if (numtype(PositionSZC[count][0]) == 0)
					PositionSZC[count][2] = data[i]
				endif
				Concentration[count] = data[i]
			endif
		endif
	endfor		

End

//Calculate the flux leaving the box through the top
Function TopValue()

	variable/g ds, dz, ns, nz
//	Variable ds, dz, ns, nz
	variable/g topbg
	variable s, var, n
	wave ScreenU
  
	make/o/n=(ceil(ns/ds)) TopMR
	SetScale/P x 0,40,"", TopMR
  
	topbg = 0
	var = 0; n = 0
	for(s=0; s<floor(ns/ds); s+=1)
		if (s >= dimSize(ScreenU,0))
			break
		endif
//		print floor(nz/dz)-1, ScreenU[s][floor(nz/dz)-1]
		TopMR[s] = ScreenU[s][dimSize(ScreenU,1) - 1]
		topbg += TopMR[s]
		var += TopMR[s]^2
		n += 1
	endfor
	topbg /= n
	
//	print "bg = ", bg
//	print "S.E. = ", sqrt((var/n - bg^2)/n)
  
End

//Calculate the flux leaving the box laterally and in total
Function FluxCalc()

	variable/g ds, dz
	variable w, s, nsi, z, nzi
	variable ux, uy, vx, vy, ws, zsur
	variable Total, TotalU, avg, rms, totalIn, totalOut, totalInU, totalOutU
	wave ScreenWindNf, ScreenWindEf, ScreenAirf
	wave ScreenF
	wave ScreenPosXY, ScreenPosZ, totalAirF, totalAirFM
	NVAR topbg, Mc, units
	SVAR unitStr
	
	if (exists("ScreenU_ppb_original") == 1)
		Wave ScreenU = ScreenU_ppb_original
	elseif (exists("ScreenU_original") == 1)
		Wave ScreenU = ScreenU_original
	else
		if (CmpStr(unitStr, "ug/m^3") == 0)
			Wave ScreenU = ScreenU_ppb
		else
			Wave ScreenU = ScreenU
		endif
	endif

	nsi = dimsize(ScreenF,0)
	nzi = dimsize(ScreenF,1)
    
	Total = 0
	TotalU = 0
	totalIn = 0
	totalOut = 0
	totalInU = 0
	totalOutU = 0

	make/o/n=(nsi,nzi) ScreenFlux, ScreenFluxU
	make/o/n=(nsi) ScreenFlux_s, ScreenFlux_sU
	make/o/n=(nzi) ScreenFlux_z, ScreenFlux_zc, ScreenFlux_zU, ScreenFlux_zcU
	setscale/p x, 0, ds, ScreenFlux, ScreenFlux_s, ScreenFluxU, ScreenFlux_sU
	setscale/p y, 0, dz, ScreenFlux, ScreenFluxU
	setscale/p x, 0, ds, ScreenFlux_z, ScreenFlux_zU
	ScreenFlux_s = 0
	ScreenFlux_z = 0
	ScreenFlux_zc = 0
	ScreenFlux_sU = 0
	ScreenFlux_zU = 0
	ScreenFlux_zcU = 0	

	for (s=0; s<nsi - 1; s+=1)
		zsur = ScreenPosZ[s*ds]/dz
		for (z=0; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if (s==0 || s==nsi-1)
				if (nsi*ds - 5 < dimSize(ScreenPosXY,1))
					ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi*ds-5][0]) // Lon Difference 
					uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi*ds-5][1]) // Lat Difference
				else
					ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi*ds-6][0]) // Lon Difference 
					uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi*ds-6][1]) // Lat Difference
				endif
			else
				ux = (ScreenPosXY[s*ds+5][0] - ScreenPosXY[s*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s*ds+5][1] - ScreenPosXY[s*ds-5][1]) // Lat Difference
			endif
			vx = ScreenWindEf[s][z]/ws  // East Wind
			vy = ScreenWindNf[s][z]/ws  // North Wind
			ScreenFlux[s][z] = (ux*vy - uy*vx)/sqrt(ux*ux+uy*uy) // normal vector
			ScreenFlux[s][z] *= Mc/28.97*10^(units)*(ScreenF[s][z]) // parts/parts
			ScreenFlux[s][z] *= ScreenAirf[s][z]                  // kg/m3
			ScreenFlux[s][z] *= ws                                // kg/m2/s
			
			if (numtype(ScreenFlux[s][z])==0)
				ScreenFlux_s[s] += ScreenFlux[s][z]
				ScreenFlux_z[floor(z-zsur)] += ScreenFlux[s][z]
				ScreenFlux_zc[floor(z-zsur)] += 1
				Total += (ScreenFlux[s][z]*ds*dz) // kg/s
				if (ScreenFlux[s][z] < 0)
					totalOut += ScreenFlux[s][z]*ds*dz
				else
					totalIn += ScreenFlux[s][z]*ds*dz
				endif
			endif
			
			//Repeat for unfilled screen
			if (z < dimSize(ScreenU,1))
				ScreenFluxU[s][z] = (ux*vy - uy*vx)/sqrt(ux*ux+uy*uy)
				ScreenFluxU[s][z] *= Mc/28.97*10^(units)*(ScreenU[s][z])
				ScreenFluxU[s][z] *= ScreenAirf[s][z] 
				ScreenFluxU[s][z] *= ws  
			
				if (numtype(ScreenFluxU[s][z])==0)
					ScreenFlux_sU[s] += ScreenFluxU[s][z]
					ScreenFlux_zU[floor(z-zsur)] += ScreenFluxU[s][z]
					ScreenFlux_zcU[floor(z-zsur)] += 1
					TotalU += (ScreenFluxU[s][z]*ds*dz) // kg/s
					if (ScreenFluxU[s][z] < 0)
						totalOutU += ScreenFluxU[s][z]*ds*dz
					else
						totalInU += ScreenFluxU[s][z]*ds*dz
					endif
				endif
			endif
		endfor
	endfor

	ScreenFlux_s *= (dz*3600) // kg/m/Hr
	ScreenFlux_z *= (ds*3600)*abs(ScreenFlux_zc)/ScreenFlux_zc // kg/m/Hr
	
	ScreenFlux_sU *= (dz*3600) // kg/m/Hr
	ScreenFlux_zU *= (ds*3600)*abs(ScreenFlux_zcU)/ScreenFlux_zcU // kg/m/Hr
	
	NVAR totLat, totTop
	totLat = Total*3600		//kg/Hr
	totTop = topbg*10^(units)*(-totalAirF[0]*3600 + totalAirFM[0])*Mc/28.97		//kg/Hr
	
	Variable/G massEm = calcECm()
	
	Variable totalInUP = totalInU/totalIn*100
	Variable totalOutUP = totalOutU/totalOut*100
	
	print " "
	print totalIn*3600, "kg/Hr leaves the box through the sides (", totalIn*3600*24/1000, "T/d),", abs(totalOut)*3600, "kg/Hr enters the box through the sides (", abs(totalOut)*3600*24/1000, "T/d)"
	print "~", round(1000 - totalInUP*10)/10, "% of matter entering does so through the extrapolated area outside the flight path, ~", round(1000 - totalOutUP*10)/10, "% of matter leaving does so through the extrapolated area outside the flight path."
	print "Total lateral emission rate is ", totLat, "kg/Hr ", totLat*24/1000, "T/d"
	print "Total emission rate through the top of the box is ", totTop, "kg/Hr ", totTop*24/1000, "T/d"
	print "Total emission rate due to changes in mass is ", massEm, "kg/Hr ", massEm*24/1000, "T/d"
	print "Total emission rate is ", totLat + totTop - massEm, "kg/Hr ", (totLat + totTop - massEm)*24/1000, "T/d"
  
	ScreenFlux *= 10^(units)
	ScreenFluxU *= 10^(units)
  
End   

Function FluxCalcAir(sst, zst, send, zend)
	variable sst, zst, send, zend
	variable/g ds, dz, Total
	variable s, z
	variable ux, uy, vx, vy, ws, zsur
	variable avg, rms, tot_in, tot_out
	wave ScreenWindNf, ScreenWindEf
	wave ScreenAirf
	wave ScreenPosXY, ScreenPosZ
	Variable nsi, nzi, ns, nz

	Total = 0
	
	nsi = round(send/ds)
	nzi = round(zend/dz)
	ns = round(sst/ds)
	nz = round(zst/dz)
	
	if (nsi > dimSize(ScreenWindNf,0))
		nsi = dimSize(ScreenWindNf,0)
	endif
	
	if (nzi > dimSize(ScreenWindNf,1))
		nzi = dimSize(ScreenWindNf,1)
	endif
	
	if (nz < 0 || nzi < 0)
		Abort "You must select an area on the screen."
	endif

	make/o/n=(nsi,nzi) ScreenAirFluxS
	Wave ScreenFlux = ScreenAirFluxS
	make/o/n=(nsi) ScreenFlux_sS
	Wave ScreenFlux_s = ScreenFlux_sS
	make/o/n=(nzi) ScreenFlux_zS, ScreenFlux_zcS
	Wave ScreenFlux_z = ScreenFlux_zS
	Wave ScreenFlux_zc = ScreenFlux_zcS
	setscale/p x, 0, ds, ScreenFlux, ScreenFlux_s
	setscale/p y, 0, dz, ScreenFlux
	setscale/p x, 0, ds, ScreenFlux_z
	ScreenFlux_s = 0
	ScreenFlux_z = 0
	ScreenFlux_zc = 0

	for(s=ns; s<nsi-1; s+=1)
		zsur = ScreenPosZ[s*ds]/dz
		for(z=nz; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if(s==0 || s==nsi-1)
				if (nsi*ds-5 > dimSize(ScreenPosXY,0))
					ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi*ds-5][0]) // Lon Difference 
					uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi*ds-5][1]) // Lat Difference
				endif
			else
				ux = (ScreenPosXY[s*ds+5][0] - ScreenPosXY[s*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s*ds+5][1] - ScreenPosXY[s*ds-5][1]) // Lat Difference
			endif
			vx = ScreenWindEf[s][z]/ws  // East Wind
			vy = ScreenWindNf[s][z]/ws  // North Wind
			ScreenFlux[s][z] = (ux*vy - uy*vx)/sqrt(ux*ux+uy*uy) // normal vector
			ScreenFlux[s][z] *= ScreenAirf[s][z]                 // kg/m3
			ScreenFlux[s][z] *= ws                               // kg/m2/s
			if(numtype(ScreenFlux[s][z])==0)
				ScreenFlux_s[s] += ScreenFlux[s][z]
				if (z > zsur)
					ScreenFlux_z[floor(z-zsur)] += ScreenFlux[s][z]
					ScreenFlux_zc[floor(z-zsur)] += 1
					Total += (ScreenFlux[s][z]*ds*dz) // kg/s
				endif
			endif
		endfor
	endfor

	ScreenFlux_s *= dz // kg/m/s
	ScreenFlux_z *= ds*abs(ScreenFlux_zc)/ScreenFlux_zc // kg/m/s
	print "Integrated air mass flux is", abs(Total*3600), "kg/Hr =", abs(Total*3600*24/1000), "T/d"
  
	make/o/n=2 ScreenFlux_s_avg
	setscale/p x, 0, nsi*ds, ScreenFlux_s_avg
	avg = 0; rms = 0; tot_in = 0; tot_out = 0
	for(s=ns; s<nsi; s+=1)
		avg += ScreenFlux_s[s]
		rms += ScreenFlux_s[s]^2
		if(ScreenFlux_s[s]<0)
			tot_in += -ScreenFlux_s[s]
		else
			tot_out += ScreenFlux_s[s]
		endif
	endfor
	ScreenFlux_s_avg[*] = avg/nsi

	tot_in = 0
	tot_out = 0
	for(s=ns; s<nsi; s+=1)
		for(z=nz; z<nzi; z+=1)
			if(numtype(ScreenFlux[s][z])==0)
				if(ScreenFlux[s][z]<0)
					tot_in += -ScreenFlux[s][z]
				else
					tot_out += ScreenFlux[s][z]
				endif
			endif
		endfor
	endfor

End   

//Interpolate time series to eliminate NaNs
Function fillNaNsTS(dt, data)
	Wave dt, data
	Variable i, j
	Variable sConc, eConc, sTime, eTime, m, b
	Variable count
	Variable start = 0
	Wave PositionSZC
	
	for (i = 0; i < dimSize(dt,0); i += 1)
		if (numtype(data[i]) == 2)
			if (start == 1)
				sConc = data[i-1]
				sTime = dt[i-1]
				count = i
				do
					count = count + 1
					if (count == dimSize(dt,0))
						return 0
					endif
				while (numtype(data[count]) == 2)
				eConc = data[count]
				eTime = dt[count]
				m = (eConc - sConc)/(eTime - sTime)
				b = eConc - m*eTime
			
				for (j = i; j < count; j += 1)
					data[j] = m*dt[j] + b	
					if (numtype(PositionSZC[j][0]) == 0)
						PositionSZC[j][2] = data[j]
					endif
				endfor
			endif
		else
			start = 1
		endif
	endfor

End

//Calculate emissions due to mass change within the box
Function calcECm ()
	Wave PositionSZA, timestamp, massInfo
	Variable z, s, j, startt, endt, startTemp, endTemp, Ar, zdiff, rho, avgC, integral, n, startP, endP, ratioP
	NVAR dz, Mc, units
	Wave ScreenAirf, ScreenF
	Variable first = 0
	
	Variable ns = dimsize(ScreenAirf,0)
	Variable nz = dimsize(ScreenAirf,1) 
	Variable/G ECm = 0
	
	for (j = 0; j < dimSize(PositionSZA,0); j += 1)
		if (numtype(PositionSZA[j][0]) == 0)
			if (first == 0)
				startt = timestamp[j]
				first = 1
			else
				endt = timestamp[j]
			endif
		endif
	endfor
	
	startTemp = massInfo[0]
	endTemp = massInfo[1]
	Ar = massInfo[2]
//	ratioP = massInfo[3]
	startP = massInfo[3]
	endP = massInfo[4]
	
	for (z = 0; z < nz; z += 1)
		rho = 0
		avgC = 0
		n = 0
		for (s = 0; s < ns; s += 1)
			if (numtype(ScreenAirf[s][z]) == 0 && numtype(ScreenF[s][z]) == 0)
				rho = rho + ScreenAirf[s][z]
				avgC = avgC + ScreenF[s][z]*10^(units)
				n = n + 1
			endif
		endfor
		
		if (n > 0)
			rho = rho/n
			avgC = avgC/n
			integral = integral + avgC*rho*dz
		endif
	endfor
	
	ECm = Ar/(endt/3600 - startt/3600)*Mc/28.97*integral*((endP - startP)/(endP + startP)*2 - (endTemp - startTemp)/(endTemp + startTemp)*2)
//	ECm = Ar/(endt/3600 - startt/3600)*Mc/28.97*integral*(startTemp/endTemp*ratioP - 1)
	return ECm

End

//Calculate exponential profiles to fit the data below the flight path
Function ProfilesExp(height)
	Variable height
	variable i, s, z, si, zi, n
	variable/g ds, dz, ns, nz
	variable/g bg
	variable sx, sy, sxx, sxy, syy, xval, yval
	wave ScreenU, ScreenPosZ
	nvar background
	
	bg = background

	Make/D/N=4/O W_coef
	make/o/n=(floor(ns/ds)) FitExpCbg=nan, FitExpA=nan, FitExpB=nan, FitExpC=nan, FitExpR2=nan
	setscale/p x, 0, ds, FitExpCbg, FitExpA, FitExpB, FitExpC, FitExpR2
  
	Make/o/n=1100 fit_Profile_pnts_C
	Make/o/n=1100 fittest
	Make/O/N=(1100,(floor(ns/ds))) fit_Profile_pnts_C_All
	Make/o/n=(80,(floor(ns/ds))) Profile_pnts_z_All, Profile_pnts_C_All = NaN
	Make/O/N=(floor(ns/ds)) Profile_C_max

	for (si=0; si<floor(ns/ds); si+=1)
  
		make/o/n=(80) Profile_pnts_z, Profile_pnts_C = NaN
		n = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		for (zi=0; zi<floor(nz/dz); zi+=1)
			z = zi*dz - ScreenPosZ[si*ds]
			if (numtype(ScreenU[si][zi])==0 && z<height)
				Profile_pnts_z[n] = z
				Profile_pnts_C[n] = ScreenU[si][zi]
				n += 1
			endif
		endfor

		deletepoints (n), (80-n), Profile_pnts_z, Profile_pnts_C
		Variable/G V_fitError = 0
		W_coef = {bg,1,0,300}
		CurveFit/Q/M=2/W=2/H="0010"/L=1100 gauss, kwCWave=W_coef, Profile_pnts_C /X=Profile_pnts_z

		if (W_coef[3] >= 100 && W_coef[3]<2000 && W_coef[1] > 0)
			FitExpCbg[si] = W_coef[0]
 			FitExpA[si] = W_coef[1]
		//	FitExpC[si] = W_coef[2]
			FitExpB[si] = W_coef[3]
		else
			FitExpCbg[si] = W_coef[0]
 			FitExpA[si] = 0
		//	FitExpC[si] = W_coef[2]
			FitExpB[si] = W_coef[3]
		endif
	
		
		fit_Profile_pnts_C = FitExpCbg[si] + FitExpA[si]*exp(-((x)/FitExpB[si])^2)

		sx = 0; sy = 0; sxx = 0; sxy = 0; syy = 0
		for (i=0; i<n; i+=1)
			xval = Profile_pnts_C[i]
			yval = FitExpCbg[si] + FitExpA[si]*exp(-((Profile_pnts_z[i])/FitExpB[si])^2)
			sx += xval
			sy += yval
			sxx += xval^2
			sxy += xval*yval
			syy += yval^2
		endfor
		FitExpR2[si] = (n*sxy - sx*sy)^2/((n*sxx - sx*sx)*(n*syy - sy*sy))
		
		fit_Profile_pnts_C_All[][si] = fit_Profile_pnts_C[p]
		Profile_C_max[si] = wavemax(Profile_pnts_C)
		for (i = 0; i < dimSize(Profile_pnts_C,0); i += 1)
			Profile_pnts_C_All[i][si] = Profile_pnts_C[i]
			Profile_pnts_z_All[i][si] = Profile_pnts_z[i]
		endfor

	endfor	

End


Function FillPoints()

	variable i, np, j, k
	wave FitExpCbg, FitExpA, FitExpB, FitExpR2
  
	np = numpnts(FitExpCbg)
  
	for (i=0; i<np; i+=1)
		if (FitExpB[i]<0 || FitExpR2[i]<0.5 || numtype(FitExpR2[i])!=0)
			FitExpCbg[i] = nan
			FitExpA[i] = nan
			FitExpB[i] = nan
			FitExpR2[i] = nan
		endif
	endfor

	for (i=0; i<np-1; i+=1)
		if (numtype(FitExpCbg[i+1])!=0)
			k = 0
			do
				k += 1
			while (numtype(FitExpCbg[i+k])!=0)
			for (j=i; j<i+k; j+=1)
				FitExpCbg[j] = FitExpCbg[i] + (j-i)/k*(FitExpCbg[i+k]-FitExpCbg[i])
				FitExpA[j] = FitExpA[i] + (j-i)/k*(FitExpA[i+k]-FitExpA[i])
				FitExpB[j] = FitExpB[i] + (j-i)/k*(FitExpB[i+k]-FitExpB[i])
			endfor
		endif        
	endfor

End

//Calculate linear profiles to fit the data below the flight path
Function ProfilesLine(height)
	Variable height
	variable i, s, z, si, zi, n
	variable/g ds, dz, ns, nz
	variable/g bg
	variable sx, sy, sxx, sxy, syy
	wave ScreenU, ScreenPosZ
	
	make/o/n=(floor(ns/ds)) Fita=nan, Fitb=nan, FitR2=nan
	setscale/p x, 0, ds, Fita, Fitb, FitR2
  
	make/o/n=1500 fit_Profile_pnts_C_L
	Make/O/N=(1500,(floor(ns/ds))) fit_Profile_pnts_C_L_All

	for (si=0; si<floor(ns/ds); si+=1)
  
		sx = 0; sy = 0; sxx = 0; sxy = 0; syy = 0; n = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		for(zi=0; zi<floor(nz/dz); zi+=1)
			z = zi*dz - ScreenPosZ[si*ds]
			if (numtype(ScreenU[si][zi])==0 && z<height)
				sx += z
				sy += ScreenU[si][zi]
				sxx += z^2
				sxy += z*ScreenU[si][zi]
				syy += ScreenU[si][zi]^2
				n += 1
			endif
		endfor
		FitR2[si] = (n*sxy - sx*sy)^2/((n*sxx - sx*sx)*(n*syy - sy*sy))
		Fitb[si] = (n*sxy - sx*sy)/(n*sxx - sx*sx)
		Fita[si] = sy/n - Fitb[si]*sx/n
		
		fit_Profile_pnts_C_L = Fita[si] + Fitb[si]*x
		
		fit_Profile_pnts_C_L_All[][si] = fit_Profile_pnts_C_L[p]
	endfor

End

//Calculate zero, constant and linear between background and constant profiles to fit the data below the flight path
Function ProfilesOther()
	NVAR ds, dz, ns, nz, background
	Variable si, uref, zi, slope, zref, zsur, intercept
	Wave ScreenU, ScreenPosZ
	
	Make/o/n=(2,2) fit_Profile_pnts_C_Z
	Make/O/N=(4,(floor(ns/ds))) fit_Profile_pnts_C_Z_All
	Make/o/n=(2,2) fit_Profile_pnts_C_ZC
	Make/O/N=(4,(floor(ns/ds))) fit_Profile_pnts_C_ZC_All	
	Make/o/n=(2,2) fit_Profile_pnts_C_C
	Make/O/N=(4,(floor(ns/ds))) fit_Profile_pnts_C_C_All
	Make/o/n=(2,2) fltHeight
	Make/O/N=(4,(floor(ns/ds))) fltHeight_All
	
	//Constant Value
	for (si=0; si<floor(ns/ds); si+=1)
		zi = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi += 1
		while(numtype(uref)!=0 && zi<nz/dz)
		zsur = ScreenPosZ[si*ds]
		zref = (zi - 1)*dz - zsur
		
		fit_Profile_pnts_C_C[][1] = uref
		fit_Profile_pnts_C_C[0][0] = 0
		fit_Profile_pnts_C_C[1][0] = zref
		fit_Profile_pnts_C_C_All[0][si] = fit_Profile_pnts_C_C[0][0]
		fit_Profile_pnts_C_C_All[1][si] = fit_Profile_pnts_C_C[0][1]
		fit_Profile_pnts_C_C_All[2][si] = fit_Profile_pnts_C_C[1][0]	
		fit_Profile_pnts_C_C_All[3][si] = fit_Profile_pnts_C_C[1][1]	
	
	//Linear Between Constant and Background

		fit_Profile_pnts_C_ZC[0][0] = 0
		fit_Profile_pnts_C_ZC[0][1] = background
		fit_Profile_pnts_C_ZC[1][0] = zref
		fit_Profile_pnts_C_ZC[1][1] = uref
		fit_Profile_pnts_C_ZC_All[0][si] = fit_Profile_pnts_C_ZC[0][0]
		fit_Profile_pnts_C_ZC_All[1][si] = fit_Profile_pnts_C_ZC[0][1]
		fit_Profile_pnts_C_ZC_All[2][si] = fit_Profile_pnts_C_ZC[1][0]	
		fit_Profile_pnts_C_ZC_All[3][si] = fit_Profile_pnts_C_ZC[1][1]		
		
		fltHeight[][0] = zref
		fltHeight[0][1] = 0
		fltHeight[1][1] = 500	
		fltHeight_All[0][si] = fltHeight[0][0]
		fltHeight_All[1][si] = fltHeight[0][1]
		fltHeight_All[2][si] = fltHeight[1][0]	
		fltHeight_All[3][si] = fltHeight[1][1]	
		
	//Background
		
		fit_Profile_pnts_C_Z[][1] = background
		fit_Profile_pnts_C_Z[0][0] = 0
		fit_Profile_pnts_C_Z[1][0] = zref
		fit_Profile_pnts_C_Z_All[0][si] = fit_Profile_pnts_C_Z[0][0]
		fit_Profile_pnts_C_Z_All[1][si] = fit_Profile_pnts_C_Z[0][1]
		fit_Profile_pnts_C_Z_All[2][si] = fit_Profile_pnts_C_Z[1][0]	
		fit_Profile_pnts_C_Z_All[3][si] = fit_Profile_pnts_C_Z[1][1]		
		
	endfor

End

//Exponential function
Function Expx2(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Cbg + A*exp(-(x/B)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = Cbg
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B

	return w[0]+w[1]*exp(-(x/w[2])^2)

End

//Unfill the screen above the flight path
Function UnfillAboveData()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref
	variable/g ds, dz, ns, nz
	variable/g bg
	wave ScreenPosZ
	nvar background
	
	wave ScreenKrig
	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots

	// ** Removal of points below lowest flight height **
	make/o/n=(ns/ds,nz/dz) ScreenTemp=0

	duplicate/o ScreenKrig, ScreenTempu

	np = dimsize(PositionSZC,0)

	// Project the flight path onto a screen array 
	for(i=0; i<np; i+=1)
		si = floor(PositionSZC[i][0]/ds)
		zi = floor(PositionSZC[i][1]/dz)
		if(zi>0 && zi<floor(nz/dz))
			for(s=-width; s<=width; s+=1)
				if(si+s>=0 && si+s<floor(ns/ds))
					ScreenTemp[si+s][zi] = 1
				elseif(si+s<0)
					ScreenTemp[si+s+floor(ns/ds)][zi] = 1
				else
					ScreenTemp[si+s-floor(ns/ds)][zi] = 1
				endif
			endfor
		endif
	endfor

  // Delete points up to the bottom of the screen array
	for(si=0; si<floor(ns/ds); si+=1)
		zi = dimSize(ScreenTempu,1) - 1
		if (si >= dimSize(ScreenTempu,0))
			break
		endif
		do
			ScreenTempu[si][zi] = nan
			zi -= 1
		while(ScreenTemp[si][zi]==0)
	endfor

  
	duplicate/o ScreenTempu, ScreenKrig

	killwaves/Z ScreenTemp, ScreenTempu
	
End

//Fill the screen above the flight path
Function FillAboveData()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, ztop, zref
	variable/g ds, dz, ns, nz
	variable/g bg
	wave ScreenU
	wave ScreenPosZ
	wave Fita, Fitb, FitR2
	wave FitExpA, FitExpB, FitExpC, FitExpR2
	
//	wave ScreenKrig
//	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots

  // Vertical Fill at Top and Bottom
	for(s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zi = dimSize(ScreenU,1)-1
		ztop = (dimSize(ScreenU,1)-1)*dz

    // Find highest data point
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = ztop - (zi+1)*dz

    // Apply extrapolated data above highest data 
		for(z=ztop; z>ztop-zref; z-=dz)
			zi = floor(z/dz)
			ScreenU[si][zi] = uref
		endfor

	endfor
	
	if (exists("ScreenU_ugm3") == 1)
		Wave ScreenU_ugm3
	  // Vertical Fill at Top and Bottom
		for(s=0; s<floor(ns/ds)*ds; s+=ds)
			si = floor(s/ds)
			zi = dimSize(ScreenU_ugm3,1)-1
			ztop = (dimSize(ScreenU_ugm3,1)-1)*dz
	
	    // Find highest data point
			if (si >= dimSize(ScreenU_ugm3,0))
				break
			endif
			do
				uref = ScreenU_ugm3[si][zi]
				zi -= 1
			while(numtype(uref)!=0 && zi>0)
			zref = ztop - (zi+1)*dz
	
	    // Apply extrapolated data above highest data 
			for(z=ztop; z>ztop-zref; z-=dz)
				zi = floor(z/dz)
				ScreenU_ugm3[si][zi] = uref
			endfor
	
		endfor	
	endif
	
	if (exists("ScreenU_ppb") == 1)
		Wave ScreenU_ppb
	  // Vertical Fill at Top and Bottom
		for(s=0; s<floor(ns/ds)*ds; s+=ds)
			si = floor(s/ds)
			zi = dimSize(ScreenU_ppb,1)-1
			ztop = (dimSize(ScreenU_ppb,1)-1)*dz
	
	    // Find highest data point
			if (si >= dimSize(ScreenU_ppb,0))
				break
			endif
			do
				uref = ScreenU_ppb[si][zi]
				zi -= 1
			while(numtype(uref)!=0 && zi>0)
			zref = ztop - (zi+1)*dz
	
	    // Apply extrapolated data above highest data 
			for(z=ztop; z>ztop-zref; z-=dz)
				zi = floor(z/dz)
				ScreenU_ppb[si][zi] = uref
			endfor
	
		endfor	
	endif	
  
End

//Unfill the screen below the flight path
Function Unfill()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref
	variable/g ds, dz, ns, nz
	variable/g bg
	wave ScreenPosZ
	
	wave ScreenKrig
	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots

	// ** Removal of points below lowest flight height **
	make/o/n=(ns/ds,nz/dz) ScreenTemp=0

	duplicate/o ScreenKrig, ScreenTempu

	np = dimsize(PositionSZC,0)

	// Project the flight path onto a screen array 
	for(i=0; i<np; i+=1)
		si = floor(PositionSZC[i][0]/ds)
		zi = floor(PositionSZC[i][1]/dz)
		if(zi>0 && zi<floor(nz/dz))
			for(s=-width; s<=width; s+=1)
				if(si+s>=0 && si+s<floor(ns/ds))
					ScreenTemp[si+s][zi] = 1
				elseif(si+s<0)
					ScreenTemp[si+s+floor(ns/ds)][zi] = 1
				else
					ScreenTemp[si+s-floor(ns/ds)][zi] = 1
				endif
			endfor
		endif
	endfor

  // Delete points up to the bottom of the screen array
	for(si=0; si<floor(ns/ds); si+=1)
		zi = 0
		if (si >= dimSize(ScreenTempu,0))
			break
		endif
		do
			ScreenTempu[si][zi] = nan
			zi += 1
		while(ScreenTemp[si][zi]==0)
	endfor
  
  // Set negative values to zero
//	for(si=0; si<floor(ns/ds); si+=1)
//		if (si >= dimSize(ScreenTempu,0))
//			break
//		endif
//		for(zi=0; zi<nz/dz; zi+=1)
//			if(ScreenTempu[si][zi]<0)
//				ScreenTempu[si][zi] = 0
//			endif
//		endfor
//	endfor
  
	duplicate/o ScreenTempu, ScreenU

	killwaves/Z ScreenTemp, ScreenTempu
	
End

//Fill the screen below the flight path using all profile methods
Function Fill()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref
	variable/g ds, dz, ns, nz
	nvar bg
	wave ScreenU
	wave ScreenPosZ
	wave Fita, Fitb, FitR2
	wave FitExpA, FitExpB, FitExpCbg, FitExpR2
	nvar background
	
	wave ScreenKrig
	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots

	duplicate/o ScreenU, Screenf0, Screenfc, Screenf0c

  // Vertical Fill at Top and Bottom
	for(s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zsur = ScreenPosZ[s]

    // Find lowest data point
		zi = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi += 1
		while(numtype(uref)!=0 && zi<nz/dz)
		zref = zi*dz - zsur

    // Apply extrapolated data below lowest data 
		for(z=zsur; z<zsur+zref; z+=dz)
			zi = floor(z/dz)
			Screenf0[si][zi] = background
			Screenfc[si][zi] = uref
//			Screenf0c[si][zi] = (z - zsur)/zref*uref
			Screenf0c[si][zi] = (uref - background)/zref*(z - zsur) + background
		endfor

	endfor

	killwaves/z ScreenTemp 

  // ** Filling of points at sides and below **
	duplicate/o ScreenU, Screenfl, Screenfe

  // Vertical Fill at Top and Bottom
	for (s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zsur = ScreenPosZ[s]

    // Find lowest data point
		zi = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi += 1
		while (numtype(uref)!=0 && zi<nz/dz)
		zref = zi*dz - zsur

    // Apply extrapolated data below lowest data 
		for (z=zsur; z<zsur+zref; z+=dz)
			zi = floor(z/dz)
			if (numtype(Fita[si]) == 0)
				Screenfl[si][zi] = Fita[si] + Fitb[si]*(z-zsur)
			else
				Screenfl[si][zi] = uref
			endif
			if (numtype(FitExpR2[si])==0)
				Screenfe[si][zi] = FitExpCbg[si] + FitExpA[si]*exp(-((z-zsur)/FitExpB[si])^2)
			else
				Screenfe[si][zi] = uref
			endif
		endfor

	endfor

	killwaves/z ScreenTemp
  
End

//Fill the screen below the flight path using the user chosen profiles
Function FillFinal()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref
	variable/g ds, dz, ns, nz
	nvar bg
	wave ScreenU
	wave ScreenPosZ
	wave Fita, Fitb, FitR2
	wave FitExpA, FitExpB, FitExpCbg, FitExpR2
	Wave/T Fit_Flag
	nvar background

  // ** Filling of points at sides and below **
	duplicate/o ScreenU, ScreenF

  // Vertical Fill at Top and Bottom
	for (s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zsur = ScreenPosZ[s]

    // Find lowest data point
		zi = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi += 1
		while (numtype(uref)!=0 && zi<nz/dz)
		zref = zi*dz - zsur

    // Apply extrapolated data below lowest data 
		for (z=zsur; z<zsur+zref; z+=dz)
			zi = floor(z/dz)
			if (CmpStr(Fit_Flag[si], "Z") == 0)
				ScreenF[si][zi] = background
			elseif (CmpStr(Fit_Flag[si], "ZC") == 0)
				ScreenF[si][zi] = (uref - background)/zref*(z - zsur) + background
			elseif (CmpStr(Fit_Flag[si], "C") == 0)
				ScreenF[si][zi] = uref
			elseif (CmpStr(Fit_Flag[si], "L") == 0)
				if (numtype(Fita[si]) == 0)
					ScreenF[si][zi] = Fita[si] + Fitb[si]*(z-zsur)
				else
					ScreenF[si][zi] = uref
				endif
			else
				if (numtype(FitExpR2[si])==0)
					ScreenF[si][zi] = FitExpCbg[si] + FitExpA[si]*exp(-((z-zsur)/FitExpB[si])^2)
				else
					ScreenF[si][zi] = uref
				endif
			endif
		endfor

	endfor

	killwaves/z ScreenTemp
  
End

//Calculate the value of each fit at the surface
function CompareBaselines()

	variable w, si, zi
	variable/g ds, dz, ns, nz
	variable/g bg
	wave Screenfc, Screenfl, Screenfe, Screenf0, Screenf0c
  
	make/o/n=(floor(ns/ds),5) Base
	setscale/p x, 0, ds, Base
  
	for (w=0; w<5; w+=1)

		if (w==0)
			duplicate/o Screenfc, ScreenTemp
		elseif (w==1)
			duplicate/o Screenfl, ScreenTemp
		elseif (w==2)
			duplicate/o Screenfe, ScreenTemp
		elseif (w==3)
			duplicate/o Screenf0, ScreenTemp
		else
			duplicate/o Screenf0c, ScreenTemp
		endif
  
		for (si=0; si<floor(ns/ds); si+=1)
			zi = 0
			if (si >= dimSize(ScreenTemp,0))
				break
			endif
			do
				zi += 1
			while (numtype(ScreenTemp[si][zi])!=0 && zi<nz/dz)
			Base[si][w] = ScreenTemp[si][zi] //- bg
		endfor

	endfor

End
  

//Delete pressure and temperature values that occur before and after flight
Function PT_FlightTimes ()
	Wave StaticT, StaticP
	Wave PositionSZA
	Variable i
	
	for (i = 0; i < dimSize(PositionSZA,0); i += 1)
		if (numtype(PositionSZA[i][0]) != 0)
			StaticT[i] = NaN
			StaticP[i] = NaN
		endif
	endfor

End

//Display time series of data
Function tSeries ()
	Wave PositionSZC, timestamp
	SVAR dataType
	
	if (exists("PositionSZC_oldUnits") != 0 && CmpStr(dataType,"Gas") != 0)
		Wave PositionSZC_oldUnits
		Display PositionSZC_oldUnits[][2] vs timestamp
	else
		Display PositionSZC[][2] vs timestamp
	endif
	ModifyGraph mode=2,lsize=1.5
	Label left "Concentration"
	Label bottom "Date/Time (GMT)"

End

//Change background value
Function chBG()
	NVAR background		
	Wave Base, UserBase
	Wave/T Fit_Flag
	Variable bg
	Variable i
	
	Prompt bg, "Enter new background value"
	DoPrompt "Change Background", bg
	
	if (V_flag)
		Abort
	endif
	
	background = bg
	ProfilesOther()
	Fill()
	CompareBaselines()
	
	for (i = 0; i < dimSize(Fit_Flag,0); i += 1)
		if (StringMatch(Fit_Flag[i], "Z") == 1)
			UserBase[i] = Base[i][3]
		elseif (StringMatch(Fit_Flag[i], "ZC") == 1)
			UserBase[i] = Base[i][4]
		endif
	endfor
	
End

//Convert particle units to ppm
Function convertP_Units ()
	NVAR Mc
	Wave StaticT, StaticP
	Wave PositionSZC
	Variable i

	for (i = 0; i < dimSize(PositionSZC,0); i += 1)
		PositionSZC[i][2] = PositionSZC[i][2]*(StaticT[i] + 273.15)*22.4/(Mc*273.15*StaticP[i]/1013.25)
	endfor

End

//Get rid of waves that are no longer needed
Function killSurplusWaves ()
	String existingWvs = WaveList("*", ";", "")
	Variable num = ItemsInList(existingWvs)
	Variable i, j
	String item, item2
	
	String deletableWvs = "PositionSZA;fltGridPts;PositionSZC_noNan;sWv;zWv;Position_wQuantEnds;krigQuant;residuals;intVal;xWv;yWv;ScreenKrig;fit_Profile_pnts_C_Z;fit_Profile_pnts_C_ZC;"
	deletableWvs = deletableWvs + "fit_Profile_pnts_C_ZC_All;fit_Profile_pnts_C_C;fit_Profile_pnts_C_C_All;fltHeight;fltHeight_All;FitR2;Fitb;Fita;fit_Profile_pnts_C_L;fit_Profile_pnts_C_L_All;"
	deletableWvs = deletableWvs + "Profile_pnts_C;Profile_pnts_z;fit_Profile_pnts_C;W_coef;FitExpR2;FitExpB;FitExpA;FitExpC;FitExpCbg;fit_Profile_pnts_C_All;Profile_pnts_C_All;Profile_pnts_z_All;"
	deletableWvs = deletableWvs + "Profile_C_max;W_sigma;Screenf0c;Screenfc;Screenf0;Screenfe;Screenfl;Base;UserBase;Fit_Flag;labelLoc;ScreenFlux_s;ScreenFlux_zc;ScreenFlux_z;"
	Variable num2 = ItemsInList(deletableWvs)

	for (i = 0; i < num; i += 1)
		item = StringFromList(i, existingWvs)
		for (j = 0; j < num2; j += 1)
			item2 = StringFromList(j, deletableWvs)
			if (StringMatch(item, item2) == 1)
				Wave current = $item
				KillWaves/Z current
			endif
		endfor
	endfor


End

//Records all the inputs and outputs from a particular run of the program
Function recordHistory()
	Variable i = -1
	Variable j
	NVAR Mc, height, totLat, totTop, bg, units, ds, massEm
	SVAR dtNm, dataNm, fltName
	if (exists("totalAirF") != 0)
		Wave totalAirF
	endif
	Wave/T Fit_Flag
	String currFlag = ""
	
	if (DataFolderExists("History") == 0)
		NewDataFolder History
		SetDataFolder History
		Make/D/N=1000 runTime = NaN
		Make/D/N=1000 molMass = NaN
		Make/D/N=1000 molMassAir = NaN
		Make/D/N=1000 molMassRatio = NaN
		Make/D/N=1000 fltHeight = NaN
		Make/D/N=1000 EairH = NaN
		Make/D/N=1000 EairV = NaN
		Make/D/N=1000 mixRatioTop = NaN
		Make/D/N=1000 EH = NaN
		Make/D/N=1000 EV = NaN
		Make/D/N=1000 Em = NaN
		Make/D/N=1000 EC = NaN
		Make/D/N=1000 profSt = NaN
		Make/D/N=1000 profEnd = NaN
		Make/D/N=1000 profStS = NaN
		Make/D/N=1000 profEndS = NaN
		Make/T/N=1000 dtName = ""
		Make/T/N=1000 dataName = ""
		Make/T/N=1000 fltNumb = ""
		Make/T/N=1000 profNm = ""
		SetScale d 0,0,"dat", runTime
		SetDataFolder root:
	endif
	
	SetDataFolder History
	if (exists("Em") == 0)
		Make/D/N=1000 Em = NaN
	endif
	SetDataFolder root:
	
	Wave runTime = root:History:runTime
	Wave molMass = root:History:molMass
	Wave molMassAir = root:History:molMassAir
	Wave molMassRatio = root:History:molMassRatio
	Wave fltHeight = root:History:fltHeight
	Wave EairH = root:History:EairH
	Wave EairV = root:History:EairV
	Wave mixRatioTop = root:History:mixRatioTop
	Wave EH = root:History:EH
	Wave EV = root:History:EV
	Wave Em = root:History:Em
	Wave EC = root:History:EC
	Wave profSt = root:History:profSt
	Wave profEnd = root:History:profEnd
	Wave profStS = root:History:profStS
	Wave profEndS = root:History:profEndS
	Wave/T dtName = root:History:dtName
	Wave/T dataName = root:History:dataName
	Wave/T fltNumb = root:History:fltNumb
	Wave/T profNm = root:History:profNm
	
	do
		i = i + 1
	while (numtype(profSt[i]) == 0)
	runTime[i] = datetime
	molMass[i] = Mc
	molMassAir[i] = 28.97
	molMassRatio[i] = Mc/28.97
	fltHeight[i] = height
	if (exists("totalAirF") != 0)
		EairH[i] = totalAirF[0]*3600
		EairV[i] = -totalAirF[0]*3600
	else
		EairH[i] = NaN
		EairV[i] = NaN
	endif
	mixRatioTop[i] = bg*10^(units)
	EH[i] = totLat
	EV[i] = totTop
	Em[i] = massEm
	EC[i] = totLat + totTop - massEm
	dtName[i] = dtNm
	dataName[i] = dataNm
	fltNumb[i] = fltName
	
	for (j = 0; j < dimSize(Fit_Flag,0); j += 1)
		if (j == 0)
			currFlag = Fit_Flag[0]
			profSt[i] = 0
			profStS[i] = 0
		endif
		if (CmpStr(currFlag, Fit_Flag[j]) != 0)
			profEnd[i] = j - 1
			profEndS[i] = (j - 1)*ds
			if (CmpStr(Fit_Flag[j - 1], "Z") == 0)
				profNm[i] = "Zero"
			elseif (CmpStr(Fit_Flag[j - 1], "C") == 0)
				profNm[i] = "Constant"
			elseif (CmpStr(Fit_Flag[j - 1], "E") == 0)
				profNm[i] = "Exponential"
			elseif (CmpStr(Fit_Flag[j - 1], "L") == 0)
				profNm[i] = "Linear"
			elseif (CmpStr(Fit_Flag[j - 1], "ZC") == 0)
				profNm[i] = "Linear Between Constant And Background"
			endif
			i = i + 1
			profSt[i] = j
			profStS[i] = j*ds
			currFlag = Fit_Flag[j]
		endif
		if (j == dimSize(Fit_Flag,0) - 1)
			profEnd[i] = j
			profEndS[i] = j*ds
			if (CmpStr(Fit_Flag[j - 1], "Z") == 0)
				profNm[i] = "Zero"
			elseif (CmpStr(Fit_Flag[j - 1], "C") == 0)
				profNm[i] = "Constant"
			elseif (CmpStr(Fit_Flag[j - 1], "E") == 0)
				profNm[i] = "Exponential"
			elseif (CmpStr(Fit_Flag[j - 1], "L") == 0)
				profNm[i] = "Linear"
			elseif (CmpStr(Fit_Flag[j - 1], "ZC") == 0)
				profNm[i] = "Linear Between Constant And Background"
			endif
		endif
	endfor
	
End

//Display the most recent runs of GraphProfiles, GraphSurface and PanelEmissions
Function reloadGraphs ()
	Wave Frame
	Variable i
	
	if (exists("ScreenPosZ") == 0)
		Abort "Kriging must be run before plots can be loaded. "
	endif
	
	Execute "GraphProfiles()"								//Display the plot to show profile fits
	DoWindow/C GraphProfiles1
	ResetProfiles()										//Go to the previous point

	Execute "GraphSurface()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	
	if (dimSize(Frame,0) == 5)								//Calculate label locations
		Make/O/N=4 labelLoc
		for (i = 0; i < 4; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "South"
	elseif (dimSize(Frame,0) == 6)
		Make/O/N=5 labelLoc
		for (i = 0; i < 5; i += 1)
			labelLoc[i] = (Frame[i][0] + Frame[i+1][0])/2
		endfor
		Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[0], "East"
		Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[1], "North"
		Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[2], "West"
		Tag/C/N=text6/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[3], "SouthWest"
		Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-60/L=0 top, labelLoc[4], "South"		
	endif
	Execute "PanelEmissions()"

End

//Resize buttons as window is resized
Function FitButtonsTERRA(win, widRatio, heiRatio, hPosRatio, vPosRatio)
	String win
	Wave widRatio, heiRatio, hPosRatio, vPosRatio
	Variable newWidth, newHeight, newHPos, newVPos, newFont
	String ctrl
	Variable i = 0
	
	GetWindow $win wsize
	Variable winWidth = V_right - V_left
	Variable winHeight = abs(V_top - V_bottom)
	
	String buttonList = ControlNameList(win)
	Variable numControl = ItemsInList(buttonList)
	for (i = 0; i < numControl; i += 1)
		ctrl = StringFromList(i, buttonList)
		ControlInfo/W=$win $ctrl
		newWidth = widRatio[i]*winWidth
		newHeight = heiRatio[i]*winHeight
		newHPos = hPosRatio[i]*winWidth
		newVPos = vPosRatio[i]*winHeight
		ModifyControl $ctrl, win=$win, pos={newHPos,newVPos}, size={newWidth,newHeight}
	endfor
	
End

//Create ratios of button sizes for resize functions
Function createRatios(win)
	String win
	Variable i
	String ctrl
	
	GetWindow $win wsize
	Variable winWidth = V_right - V_left
	Variable winHeight = abs(V_top - V_bottom)

	String buttonList = ControlNameList(win)
	Variable numControl = ItemsInList(buttonList)
	
	Make/O/N=(numControl) widRatio, heiRatio, hPosRatio, vPosRatio
	
	for (i = 0; i < numControl; i += 1)
		ctrl = StringFromList(i, buttonList)
		ControlInfo/W=$win $ctrl
		widRatio[i] = round(V_width/winWidth*1000)/1000
		heiRatio[i] = round(V_height/winWidth*1000)/1000
		hPosRatio[i] = round(V_left/winWidth*1000)/1000
		vPosRatio[i] = round(V_top/winHeight*1000)/1000
	endfor

End

//Create vertical profile waves based on a time period
Function vertProf(stT,endT)
	Variable stT, endT
	Wave Concentration, timestamp
	Wave StaticT, StaticP, DewPoint
	Variable stIndex, endIndex
	Variable i, j
	if (exists("Height_m") == 1)
		Wave Height_m
	else
		Wave Height_m = Alt
	endif
	
	for (i = 0; i < dimSize(timestamp,0); i += 1)
		if (timestamp[i] == stT)
			stIndex = i
			break
		endif
	endfor
	
	for (j = i; j < dimSize(timestamp,0); j += 1)
		if (timestamp[j] == endT)
			endIndex = j
			break
		endif
	endfor
	
	Duplicate/O/R=(stIndex,endIndex) StaticT, StaticT_Prof
	Duplicate/O/R=(stIndex,endIndex) StaticP, StaticP_Prof
	Duplicate/O/R=(stIndex,endIndex) DewPoint, DewPoint_Prof
	Duplicate/O/R=(stIndex,endIndex) Concentration, Conc_Prof
	Duplicate/O/R=(stIndex,endIndex) Height_m, Height_Prof

End

//Create vertical profile waves based on an area
Function vertProfArea(xSt, xEnd, ySt, yEnd)
	Variable xSt, xEnd, ySt, yEnd
	Wave Concentration, timestamp
	Wave StaticT, StaticP, DewPoint
	Wave Lat, Lon
	Variable i
	Variable count = 0
	if (exists("Height_m") == 1)
		Wave Height_m
	else
		Wave Height_m = Alt
	endif
	
	Make/O/N=(dimSize(timestamp,0)) StaticT_Prof, StaticP_Prof, DewPoint_Prof, Height_Prof, Conc_Prof
	
	for (i = 0; i < dimSize(timestamp,0); i += 1)
		if (Lat[i] <= yEnd && Lat[i] >= ySt && Lon[i] >= xSt && Lon[i] <= xEnd)
			StaticT_Prof[count] = StaticT[i]
			StaticP_Prof[count] = StaticP[i]
			DewPoint_Prof[count] = DewPoint[i]
			Conc_Prof[count] = Concentration[i]
			Height_Prof[count] = Height_m[i]
			count = count + 1
		endif
	endfor
	
	DeletePoints count, dimSize(timestamp,0), StaticT_Prof, StaticP_Prof, DewPoint_Prof, Height_Prof, Conc_Prof
			
End


//Go back one profile from the end on GraphProfiles
Function ResetProfiles()
	NVAR index, maxC, ds, height, background
	Wave Profile_pnts_C_All,  Profile_pnts_C, Profile_pnts_z_All,  Profile_pnts_z, fit_Profile_pnts_C_All,  fit_Profile_pnts_C, fit_Profile_pnts_C_L_All, fit_Profile_pnts_C_L  
	Wave fit_Profile_pnts_C_Z, fit_Profile_pnts_C_Z_All, fit_Profile_pnts_C_ZC_All, fit_Profile_pnts_C_ZC, fit_Profile_pnts_C_C_All, fit_Profile_pnts_C_C  
	Wave Profile_C_max, fltHeight, fltHeight_All
	
	Wave ScreenPosZ

	Make/O/N=(2,2) currLeft, currRight, currTop, currBot

	index = index - 1
	Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_C_All,  Profile_pnts_C
	Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_z_All,  Profile_pnts_z
	Duplicate/O/R=(0, 1100)(index,index)  fit_Profile_pnts_C_All,  fit_Profile_pnts_C
	Duplicate/O/R=(0, 1500)(index,index)  fit_Profile_pnts_C_L_All,  fit_Profile_pnts_C_L
	fit_Profile_pnts_C_C[0][0] = fit_Profile_pnts_C_C_All[0][index]
	fit_Profile_pnts_C_C[0][1] = fit_Profile_pnts_C_C_All[1][index]
	fit_Profile_pnts_C_C[1][0] = fit_Profile_pnts_C_C_All[2][index]
	fit_Profile_pnts_C_C[1][1] = fit_Profile_pnts_C_C_All[3][index]
	fit_Profile_pnts_C_ZC[0][0] = fit_Profile_pnts_C_ZC_All[0][index]
	fit_Profile_pnts_C_ZC[0][1] = fit_Profile_pnts_C_ZC_All[1][index]
	fit_Profile_pnts_C_ZC[1][0] = fit_Profile_pnts_C_ZC_All[2][index]
	fit_Profile_pnts_C_ZC[1][1] = fit_Profile_pnts_C_ZC_All[3][index]
	fit_Profile_pnts_C_Z[0][0] = fit_Profile_pnts_C_Z_All[0][index]
	fit_Profile_pnts_C_Z[0][1] = fit_Profile_pnts_C_Z_All[1][index]
	fit_Profile_pnts_C_Z[1][0] = fit_Profile_pnts_C_Z_All[2][index]
	fit_Profile_pnts_C_Z[1][1] = fit_Profile_pnts_C_Z_All[3][index]	
	fltHeight[0][0] = fltHeight_All[0][index]
	fltHeight[0][1] = fltHeight_All[1][index]
	fltHeight[1][0] = fltHeight_All[2][index]
	fltHeight[1][1] = fltHeight_All[3][index]
	
	maxC = 	fit_Profile_pnts_C_C[0][1]
	WaveStats/Q fit_Profile_pnts_C
	if (V_max > maxC)
		maxC = V_max
	endif
	WaveStats/Q fit_Profile_pnts_C_L
	if (V_max > maxC)
		maxC = V_max
	endif	
	WaveStats/Q Profile_pnts_C
	if (V_max > maxC)
		maxC = V_max
	endif		
	if (background > maxC)
		maxC = background
	endif
	if (fit_Profile_pnts_C_ZC[0][1] > maxC)
		maxC = fit_Profile_pnts_C_ZC[0][1]
	endif
	if (fit_Profile_pnts_C_ZC[1][1] > maxC)
		maxC = fit_Profile_pnts_C_ZC[1][1]
	endif		
	
	//Create current profile position box on GraphSurface
	currLeft[][0] = index*ds
	currLeft[0][1] = ScreenPosZ[index*ds]
	currLeft[1][1] = height + ScreenPosZ[index*ds]
	
	currRight[][0] = index*ds + ds
	currRight[0][1] = ScreenPosZ[index*ds]
	currRight[1][1] = height + ScreenPosZ[index*ds]
	
	currTop[0][0] = index*ds
	currTop[1][0] = index*ds + ds
	currTop[][1] = ScreenPosZ[index*ds]
	
	currBot[0][0] = index*ds
	currBot[1][0] = index*ds + ds
	currBot[][1] = ScreenPosZ[index*ds] + height
End

//Move to the next profile (if one exists)
Function ProfileNext(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR index, indmax, maxC, ds, height, background
	SVAR projNm
	Wave Profile_pnts_C_All,  Profile_pnts_C, Profile_pnts_z_All,  Profile_pnts_z, fit_Profile_pnts_C_All,  fit_Profile_pnts_C, fit_Profile_pnts_C_L_All, fit_Profile_pnts_C_L  
	Wave fit_Profile_pnts_C_Z, fit_Profile_pnts_C_Z_All, fit_Profile_pnts_C_ZC_All, fit_Profile_pnts_C_ZC, fit_Profile_pnts_C_C_All, fit_Profile_pnts_C_C  
	Wave Profile_C_max, fltHeight, fltHeight_All
	Wave ScreenPosZ, currLeft, currRight, currTop, currBot
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (index < indmax - 1)
				index = index + 1
				Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_C_All,  Profile_pnts_C
				Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_z_All,  Profile_pnts_z
				Duplicate/O/R=(0, 1100)(index,index)  fit_Profile_pnts_C_All,  fit_Profile_pnts_C
				Duplicate/O/R=(0, 1500)(index,index)  fit_Profile_pnts_C_L_All,  fit_Profile_pnts_C_L
				fit_Profile_pnts_C_C[0][0] = fit_Profile_pnts_C_C_All[0][index]
				fit_Profile_pnts_C_C[0][1] = fit_Profile_pnts_C_C_All[1][index]
				fit_Profile_pnts_C_C[1][0] = fit_Profile_pnts_C_C_All[2][index]
				fit_Profile_pnts_C_C[1][1] = fit_Profile_pnts_C_C_All[3][index]
				fit_Profile_pnts_C_ZC[0][0] = fit_Profile_pnts_C_ZC_All[0][index]
				fit_Profile_pnts_C_ZC[0][1] = fit_Profile_pnts_C_ZC_All[1][index]
				fit_Profile_pnts_C_ZC[1][0] = fit_Profile_pnts_C_ZC_All[2][index]
				fit_Profile_pnts_C_ZC[1][1] = fit_Profile_pnts_C_ZC_All[3][index]
				fit_Profile_pnts_C_Z[0][0] = fit_Profile_pnts_C_Z_All[0][index]
				fit_Profile_pnts_C_Z[0][1] = fit_Profile_pnts_C_Z_All[1][index]
				fit_Profile_pnts_C_Z[1][0] = fit_Profile_pnts_C_Z_All[2][index]
				fit_Profile_pnts_C_Z[1][1] = fit_Profile_pnts_C_Z_All[3][index]	
				fltHeight[0][0] = fltHeight_All[0][index]
				fltHeight[0][1] = fltHeight_All[1][index]
				fltHeight[1][0] = fltHeight_All[2][index]
				fltHeight[1][1] = fltHeight_All[3][index]	
							
				maxC = 	fit_Profile_pnts_C_C[0][1]
				WaveStats/Q fit_Profile_pnts_C
				if (V_max > maxC)
					maxC = V_max
				endif
				WaveStats/Q fit_Profile_pnts_C_L
				if (V_max > maxC)
					maxC = V_max
				endif	
				WaveStats/Q Profile_pnts_C
				if (V_max > maxC)
					maxC = V_max
				endif		
				if (background > maxC)
					maxC = background
				endif
				if (fit_Profile_pnts_C_ZC[0][1] > maxC)
					maxC = fit_Profile_pnts_C_ZC[0][1]
				endif
				if (fit_Profile_pnts_C_ZC[1][1] > maxC)
					maxC = fit_Profile_pnts_C_ZC[1][1]
				endif
				
				TextBox/K/N=text1
				TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
				SetAxis bottom background, maxC	
				
				if (CmpStr(projNm,"2018") == 0)
					currLeft[][0] = index*ds
					currLeft[0][1] = ScreenPosZ[index*ds]
					currLeft[1][1] = height + ScreenPosZ[index*ds]
					
					currRight[][0] = index*ds + ds
					currRight[0][1] = ScreenPosZ[index*ds]
					currRight[1][1] = height + ScreenPosZ[index*ds]
					
					currTop[0][0] = index*ds
					currTop[1][0] = index*ds + ds
					currTop[][1] = ScreenPosZ[index*ds]
					
					currBot[0][0] = index*ds
					currBot[1][0] = index*ds + ds
					currBot[][1] = ScreenPosZ[index*ds] + height
				else
					currLeft[][0] = index*ds
					currLeft[0][1] = ScreenPosZ[index*ds/2]
					currLeft[1][1] = height + ScreenPosZ[index*ds/2]
					
					currRight[][0] = index*ds + ds
					currRight[0][1] = ScreenPosZ[index*ds/2]
					currRight[1][1] = height + ScreenPosZ[index*ds/2]
					
					currTop[0][0] = index*ds
					currTop[1][0] = index*ds + ds
					currTop[][1] = ScreenPosZ[index*ds/2]
					
					currBot[0][0] = index*ds
					currBot[1][0] = index*ds + ds
					currBot[][1] = ScreenPosZ[index*ds/2] + height
				endif				
				
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Move to the previous profile (if one exists)
Function ProfilePrev(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR index, maxC, ds, height, background
	SVAR projNm
	Wave Profile_pnts_C_All,  Profile_pnts_C, Profile_pnts_z_All,  Profile_pnts_z, fit_Profile_pnts_C_All,  fit_Profile_pnts_C, fit_Profile_pnts_C_L_All, fit_Profile_pnts_C_L
	Wave fit_Profile_pnts_C_Z, fit_Profile_pnts_C_ZC_All, fit_Profile_pnts_C_Z_All, fit_Profile_pnts_C_ZC, fit_Profile_pnts_C_C_All, fit_Profile_pnts_C_C     
	Wave Profile_C_max, fltHeight, fltHeight_All
	Wave ScreenPosZ, currLeft, currRight, currTop, currBot
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (index > 0)
				index = index - 1
				Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_C_All,  Profile_pnts_C
				Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_z_All,  Profile_pnts_z
				Duplicate/O/R=(0, 1100)(index,index)  fit_Profile_pnts_C_All,  fit_Profile_pnts_C
				Duplicate/O/R=(0, 1500)(index,index)  fit_Profile_pnts_C_L_All,  fit_Profile_pnts_C_L
				fit_Profile_pnts_C_C[0][0] = fit_Profile_pnts_C_C_All[0][index]
				fit_Profile_pnts_C_C[0][1] = fit_Profile_pnts_C_C_All[1][index]
				fit_Profile_pnts_C_C[1][0] = fit_Profile_pnts_C_C_All[2][index]
				fit_Profile_pnts_C_C[1][1] = fit_Profile_pnts_C_C_All[3][index]
				fit_Profile_pnts_C_ZC[0][0] = fit_Profile_pnts_C_ZC_All[0][index]
				fit_Profile_pnts_C_ZC[0][1] = fit_Profile_pnts_C_ZC_All[1][index]
				fit_Profile_pnts_C_ZC[1][0] = fit_Profile_pnts_C_ZC_All[2][index]
				fit_Profile_pnts_C_ZC[1][1] = fit_Profile_pnts_C_ZC_All[3][index]
				fit_Profile_pnts_C_Z[0][0] = fit_Profile_pnts_C_Z_All[0][index]
				fit_Profile_pnts_C_Z[0][1] = fit_Profile_pnts_C_Z_All[1][index]
				fit_Profile_pnts_C_Z[1][0] = fit_Profile_pnts_C_Z_All[2][index]
				fit_Profile_pnts_C_Z[1][1] = fit_Profile_pnts_C_Z_All[3][index]					
				fltHeight[0][0] = fltHeight_All[0][index]
				fltHeight[0][1] = fltHeight_All[1][index]
				fltHeight[1][0] = fltHeight_All[2][index]
				fltHeight[1][1] = fltHeight_All[3][index]	

				maxC = 	fit_Profile_pnts_C_C[0][1]
				WaveStats/Q fit_Profile_pnts_C
				if (V_max > maxC)
					maxC = V_max
				endif
				WaveStats/Q fit_Profile_pnts_C_L
				if (V_max > maxC)
					maxC = V_max
				endif	
				WaveStats/Q Profile_pnts_C
				if (V_max > maxC)
					maxC = V_max
				endif		
				if (background > maxC)
					maxC = background
				endif
				if (fit_Profile_pnts_C_ZC[0][1] > maxC)
					maxC = fit_Profile_pnts_C_ZC[0][1]
				endif
				if (fit_Profile_pnts_C_ZC[1][1] > maxC)
					maxC = fit_Profile_pnts_C_ZC[1][1]
				endif
	
				TextBox/K/N=text1
				TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
				SetAxis bottom background, maxC		
				
				if (CmpStr(projNm,"2018") == 0)
					currLeft[][0] = index*ds
					currLeft[0][1] = ScreenPosZ[index*ds]
					currLeft[1][1] = height + ScreenPosZ[index*ds]
					
					currRight[][0] = index*ds + ds
					currRight[0][1] = ScreenPosZ[index*ds]
					currRight[1][1] = height + ScreenPosZ[index*ds]
					
					currTop[0][0] = index*ds
					currTop[1][0] = index*ds + ds
					currTop[][1] = ScreenPosZ[index*ds]
					
					currBot[0][0] = index*ds
					currBot[1][0] = index*ds + ds
					currBot[][1] = ScreenPosZ[index*ds] + height
				else
					currLeft[][0] = index*ds
					currLeft[0][1] = ScreenPosZ[index*ds/2]
					currLeft[1][1] = height + ScreenPosZ[index*ds/2]
					
					currRight[][0] = index*ds + ds
					currRight[0][1] = ScreenPosZ[index*ds/2]
					currRight[1][1] = height + ScreenPosZ[index*ds/2]
					
					currTop[0][0] = index*ds
					currTop[1][0] = index*ds + ds
					currTop[][1] = ScreenPosZ[index*ds/2]
					
					currBot[0][0] = index*ds
					currBot[1][0] = index*ds + ds
					currBot[][1] = ScreenPosZ[index*ds/2] + height
				endif						
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose a profile to move to
Function ProfileVar(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	NVAR index, maxC, ds, height, background
	SVAR projNm
	Wave Profile_pnts_C_All,  Profile_pnts_C, Profile_pnts_z_All,  Profile_pnts_z, fit_Profile_pnts_C_All,  fit_Profile_pnts_C, fit_Profile_pnts_C_L_All, fit_Profile_pnts_C_L  
	Wave  fit_Profile_pnts_C_Z,fit_Profile_pnts_C_Z_All, fit_Profile_pnts_C_ZC_All, fit_Profile_pnts_C_ZC, fit_Profile_pnts_C_C_All, fit_Profile_pnts_C_C  
	Wave Profile_C_max, fltHeight, fltHeight_All
	Wave ScreenPosZ, currLeft, currRight, currTop, currBot
	switch( sva.eventCode )
		case 1: // mouse up
			index = sva.dval
			Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_C_All,  Profile_pnts_C
			Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_z_All,  Profile_pnts_z
			Duplicate/O/R=(0, 1100)(index,index)  fit_Profile_pnts_C_All,  fit_Profile_pnts_C
			Duplicate/O/R=(0, 1500)(index,index)  fit_Profile_pnts_C_L_All,  fit_Profile_pnts_C_L
			fit_Profile_pnts_C_C[0][0] = fit_Profile_pnts_C_C_All[0][index]
			fit_Profile_pnts_C_C[0][1] = fit_Profile_pnts_C_C_All[1][index]
			fit_Profile_pnts_C_C[1][0] = fit_Profile_pnts_C_C_All[2][index]
			fit_Profile_pnts_C_C[1][1] = fit_Profile_pnts_C_C_All[3][index]
			fit_Profile_pnts_C_ZC[0][0] = fit_Profile_pnts_C_ZC_All[0][index]
			fit_Profile_pnts_C_ZC[0][1] = fit_Profile_pnts_C_ZC_All[1][index]
			fit_Profile_pnts_C_ZC[1][0] = fit_Profile_pnts_C_ZC_All[2][index]
			fit_Profile_pnts_C_ZC[1][1] = fit_Profile_pnts_C_ZC_All[3][index]
			fit_Profile_pnts_C_Z[0][0] = fit_Profile_pnts_C_Z_All[0][index]
			fit_Profile_pnts_C_Z[0][1] = fit_Profile_pnts_C_Z_All[1][index]
			fit_Profile_pnts_C_Z[1][0] = fit_Profile_pnts_C_Z_All[2][index]
			fit_Profile_pnts_C_Z[1][1] = fit_Profile_pnts_C_Z_All[3][index]	
			fltHeight[0][0] = fltHeight_All[0][index]
			fltHeight[0][1] = fltHeight_All[1][index]
			fltHeight[1][0] = fltHeight_All[2][index]
			fltHeight[1][1] = fltHeight_All[3][index]	
			
			maxC = 	fit_Profile_pnts_C_C[0][1]
			WaveStats/Q fit_Profile_pnts_C
			if (V_max > maxC)
				maxC = V_max
			endif
			WaveStats/Q fit_Profile_pnts_C_L
			if (V_max > maxC)
				maxC = V_max
			endif	
			WaveStats/Q Profile_pnts_C
			if (V_max > maxC)
				maxC = V_max
			endif		
			if (background > maxC)
				maxC = background
			endif
			if (fit_Profile_pnts_C_ZC[0][1] > maxC)
				maxC = fit_Profile_pnts_C_ZC[0][1]
			endif
			if (fit_Profile_pnts_C_ZC[1][1] > maxC)
				maxC = fit_Profile_pnts_C_ZC[1][1]
			endif
	
			TextBox/K/N=text1
			TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
			SetAxis bottom background, maxC	
			
			if (CmpStr(projNm,"2018") == 0)
				currLeft[][0] = index*ds
				currLeft[0][1] = ScreenPosZ[index*ds]
				currLeft[1][1] = height + ScreenPosZ[index*ds]
				
				currRight[][0] = index*ds + ds
				currRight[0][1] = ScreenPosZ[index*ds]
				currRight[1][1] = height + ScreenPosZ[index*ds]
				
				currTop[0][0] = index*ds
				currTop[1][0] = index*ds + ds
				currTop[][1] = ScreenPosZ[index*ds]
				
				currBot[0][0] = index*ds
				currBot[1][0] = index*ds + ds
				currBot[][1] = ScreenPosZ[index*ds] + height
			else
				currLeft[][0] = index*ds
				currLeft[0][1] = ScreenPosZ[index*ds/2]
				currLeft[1][1] = height + ScreenPosZ[index*ds/2]
				
				currRight[][0] = index*ds + ds
				currRight[0][1] = ScreenPosZ[index*ds/2]
				currRight[1][1] = height + ScreenPosZ[index*ds/2]
				
				currTop[0][0] = index*ds
				currTop[1][0] = index*ds + ds
				currTop[][1] = ScreenPosZ[index*ds/2]
				
				currBot[0][0] = index*ds
				currBot[1][0] = index*ds + ds
				currBot[][1] = ScreenPosZ[index*ds/2] + height
			endif	
		case 2: // Enter key
			index = sva.dval
			Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_C_All,  Profile_pnts_C
			Duplicate/O/R=(0, 1100)(index,index)  Profile_pnts_z_All,  Profile_pnts_z
			Duplicate/O/R=(0, 1100)(index,index)  fit_Profile_pnts_C_All,  fit_Profile_pnts_C
			Duplicate/O/R=(0, 1500)(index,index)  fit_Profile_pnts_C_L_All,  fit_Profile_pnts_C_L
			fit_Profile_pnts_C_C[0][0] = fit_Profile_pnts_C_C_All[0][index]
			fit_Profile_pnts_C_C[0][1] = fit_Profile_pnts_C_C_All[1][index]
			fit_Profile_pnts_C_C[1][0] = fit_Profile_pnts_C_C_All[2][index]
			fit_Profile_pnts_C_C[1][1] = fit_Profile_pnts_C_C_All[3][index]
			fit_Profile_pnts_C_ZC[0][0] = fit_Profile_pnts_C_ZC_All[0][index]
			fit_Profile_pnts_C_ZC[0][1] = fit_Profile_pnts_C_ZC_All[1][index]
			fit_Profile_pnts_C_ZC[1][0] = fit_Profile_pnts_C_ZC_All[2][index]
			fit_Profile_pnts_C_ZC[1][1] = fit_Profile_pnts_C_ZC_All[3][index]
			fit_Profile_pnts_C_Z[0][0] = fit_Profile_pnts_C_Z_All[0][index]
			fit_Profile_pnts_C_Z[0][1] = fit_Profile_pnts_C_Z_All[1][index]
			fit_Profile_pnts_C_Z[1][0] = fit_Profile_pnts_C_Z_All[2][index]
			fit_Profile_pnts_C_Z[1][1] = fit_Profile_pnts_C_Z_All[3][index]	
			fltHeight[0][0] = fltHeight_All[0][index]
			fltHeight[0][1] = fltHeight_All[1][index]
			fltHeight[1][0] = fltHeight_All[2][index]
			fltHeight[1][1] = fltHeight_All[3][index]	
			
			maxC = 	fit_Profile_pnts_C_C[0][1]
			WaveStats/Q fit_Profile_pnts_C
			if (V_max > maxC)
				maxC = V_max
			endif
			WaveStats/Q fit_Profile_pnts_C_L
			if (V_max > maxC)
				maxC = V_max
			endif	
			WaveStats/Q Profile_pnts_C
			if (V_max > maxC)
				maxC = V_max
			endif		
			if (background > maxC)
				maxC = background
			endif
			if (fit_Profile_pnts_C_ZC[0][1] > maxC)
				maxC = fit_Profile_pnts_C_ZC[0][1]
			endif
			if (fit_Profile_pnts_C_ZC[1][1] > maxC)
				maxC = fit_Profile_pnts_C_ZC[1][1]
			endif
	
			TextBox/K/N=text1
			TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
			SetAxis bottom background, maxC	
			
			if (CmpStr(projNm,"2018") == 0)
				currLeft[][0] = index*ds
				currLeft[0][1] = ScreenPosZ[index*ds]
				currLeft[1][1] = height + ScreenPosZ[index*ds]
				
				currRight[][0] = index*ds + ds
				currRight[0][1] = ScreenPosZ[index*ds]
				currRight[1][1] = height + ScreenPosZ[index*ds]
				
				currTop[0][0] = index*ds
				currTop[1][0] = index*ds + ds
				currTop[][1] = ScreenPosZ[index*ds]
				
				currBot[0][0] = index*ds
				currBot[1][0] = index*ds + ds
				currBot[][1] = ScreenPosZ[index*ds] + height
			else
				currLeft[][0] = index*ds
				currLeft[0][1] = ScreenPosZ[index*ds/2]
				currLeft[1][1] = height + ScreenPosZ[index*ds/2]
				
				currRight[][0] = index*ds + ds
				currRight[0][1] = ScreenPosZ[index*ds/2]
				currRight[1][1] = height + ScreenPosZ[index*ds/2]
				
				currTop[0][0] = index*ds
				currTop[1][0] = index*ds + ds
				currTop[][1] = ScreenPosZ[index*ds/2]
				
				currBot[0][0] = index*ds
				currBot[1][0] = index*ds + ds
				currBot[][1] = ScreenPosZ[index*ds/2] + height
			endif	
		case 3: // Live update
			index = sva.dval
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose a new height to be used for fitting profiles
Function NewHeight(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	NVAR height
	switch( sva.eventCode )
		case 1: // mouse up
			height = sva.dval
		case 2: // Enter key
			height = sva.dval
		case 3: // Live update
			height = sva.dval
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Rerun the fits with a new height
Function RerunFits(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR height
	switch( ba.eventCode )
		case 2: // mouse up
			ProfilesExp(height)
			ProfilesLine(height)
			Fill()
			CompareBaselines()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Display help window
Function Help(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR nz
	switch( ba.eventCode )
		case 2: // mouse up
			DisplayHelpTopic "TERRA: Top-down Emission Rate Retrieval Algorithm"
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Change the axis on GraphSurface to their initial locations
Function ResetAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR nz
	switch( ba.eventCode )
		case 2: // mouse up
			SetAxis/A
			SetAxis left 0,nz
			SetAxis l1 -10,50
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Save the profile between the two cursors
Function SaveProf(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable csrA, csrB, fitType, i
	Wave/T Fit_Flag
	Wave UserBase
	Wave Base
	String flag
	Variable basenum

	switch( ba.eventCode )
		case 2: // mouse up
			csrA = pcsr(A)
			csrB = pcsr(B)
			Prompt fitType, "Which fit do you want to use in this region? ", popup, "Constant;Linear Between Constant and Background;Background Below Flight;Linear Fit;Exponential Fit"
			DoPrompt "Choose Fit Type", fitType
			
			if (V_flag)
				Abort
			endif
			
			if (fitType == 5)
				flag = "E"
				basenum = 2
			elseif (fitType == 4)
				flag = "L"
				basenum = 1
			elseif (fitType == 3)
				flag = "Z"
				basenum = 3
			elseif (fitType == 2)
				flag = "ZC"
				basenum = 4
			else
				flag = "C"
				basenum = 0
			endif
	
			if (csrA < csrB)
				for (i = csrA; i < csrB; i += 1)
					Fit_Flag[i] = flag
					UserBase[i] = Base[i][basenum]
				endfor
			else
				for (i = csrB; i < csrA; i += 1)
					Fit_Flag[i] = flag
					UserBase[i] = Base[i][basenum]
				endfor
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Accept profile choices and create final screen plus flux calculation
Function DoneProf(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave/T Fit_Flag
	NVAR nz, bg, totLat, totTop, Mc, units, height, massEm
	Wave labelLoc, Frame, totalAirF, totalAirFM
	SVAR unitStr, projNm
	Wave PositionSZC, ScreenU
	String wlist
	
	Variable num = dimSize(Fit_Flag,0)
	Variable i
	switch( ba.eventCode )
		case 2: // mouse up
			if (CmpStr(projNm,"2018") == 0)					//2018 campaign
				for (i = 0; i < num; i += 1)
					if (strlen(Fit_Flag[i]) == 0)
						Fit_Flag[i] = "C"
					endif
				endfor
				FillFinal()
				Wave ScreenF
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ppb
					Duplicate/O ScreenU_ppb, ScreenU
					Duplicate/O ScreenF, ScreenF_ugm3
					TopValue()
					wlist = WinList("GraphProfiles1", ";", "")
					if (strlen(wlist) > 0)
						KillWindow GraphProfiles1
					endif
					ProfilesLine (height)
					ProfilesExp (height)
					FillFinal()
					Duplicate/O ScreenF, ScreenF_ppb
				endif
				FluxCalc()
				Wave ScreenF, ScreenPosZ, Frame
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ugm3
					Duplicate/O ScreenU_ugm3, ScreenU
					Duplicate/O ScreenF_ugm3, ScreenF
					ProfilesLine (height)
					ProfilesExp (height)
					Execute "GraphProfiles()"
					DoWindow/C GraphProfiles1
				endif
	
			else													//2013 campaign
				for (i = 0; i < num; i += 1)
					if (strlen(Fit_Flag[i]) == 0)
						Fit_Flag[i] = "C"
					endif
				endfor
				FillFinal_2013()
				Wave ScreenF
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ppb
					Duplicate/O ScreenU_ppb, ScreenU
					Duplicate/O ScreenF, ScreenF_ugm3
					TopValue()
					wlist = WinList("GraphProfiles1", ";", "")
					if (strlen(wlist) > 0)
						KillWindow GraphProfiles1
					endif
					ProfilesLine_2013(height)
					ProfilesExp_2013(height)
					FillFinal_2013()
					Duplicate/O ScreenF, ScreenF_ppb
				endif
				FluxCalc_2013()
				Wave ScreenF, ScreenPosZ, Frame
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ugm3
					Duplicate/O ScreenU_ugm3, ScreenU
					Duplicate/O ScreenF_ugm3, ScreenF
					ProfilesLine_2013 (height)
					ProfilesExp_2013 (height)
					Execute "GraphProfiles()"
					DoWindow/C GraphProfiles1
				endif
			endif
	
			Display /W=(344.25,66.5,1115.25,560.75) ScreenPosZ[*]
			AppendToGraph Frame[0,4][1] vs Frame[0,4][0]
			AppendImage/T ScreenF
			SetAxis/A left
			ModifyImage ScreenF ctab= {*,*,Rainbow,1}
			ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2
			ModifyGraph rgb(ScreenPosZ)=(43520,43520,43520),mode(Frame)=1,lsize(Frame)=1.2
			ModifyGraph rgb(Frame)=(0,0,0)
			ModifyGraph margin(right)=50
			SetAxis left 0, nz
			ColorScale/C/N=text0/F=0/M/A=RT/X=-6.98/Y=13.86 image=ScreenF, logLTrip=0.0001
			ColorScale/C/N=text0 lowTrip=0.1
			ModifyGraph noLabel(top)=2
			Label bottom "s (m)"
			Label left "Altitude"
			ModifyGraph tick(top)=3

			if (dimSize(Frame,0) == 5)
				Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[0], "East"
				Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[1], "North"
				Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[2], "West"
				Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[3], "South"
			else
				Tag/C/N=text2/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[0], "East"
				Tag/C/N=text3/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[1], "North"
				Tag/C/N=text4/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[2], "West"
				Tag/C/N=text6/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[3], "SouthWest"
				Tag/C/N=text5/F=0/B=1/X=-1.00/Y=-55/L=0 top, labelLoc[4], "South"	
			endif
		
			SetDrawLayer/W=PanelEmissions/K UserBack			
			DrawText/W=PanelEmissions 27,318,num2str(totalAirF[0]*3600)
			DrawText/W=PanelEmissions 117,318,num2str(-totalAirF[0]*3600 + totalAirFM[0])
			DrawText/W=PanelEmissions 200,318,num2str(bg*10^(units))
			DrawText/W=PanelEmissions 285,318,num2str(Mc/28.97)
			if (abs(totLat) > 100000)
				DrawText/W=PanelEmissions 345,318,num2str(totLat/100000)
				DrawText/W=PanelEmissions 355,330,"e+05"
			else
				if (abs(totLat) < 0.1)
					DrawText/W=PanelEmissions 345,318,num2str(totLat*100)
					DrawText/W=PanelEmissions 355,330,"e-02"
				else
					DrawText/W=PanelEmissions 345,318,num2str(totLat)
				endif
			endif
			if (abs(totTop) > 100000)
				DrawText/W=PanelEmissions 405,318,num2str(totTop/100000)
				DrawText/W=PanelEmissions 415,330,"e+05"
			else
				if (abs(totLat) < 0.1)
					DrawText/W=PanelEmissions 405,318,num2str(totTop*100)
					DrawText/W=PanelEmissions 415,330,"e-02"
				else
					DrawText/W=PanelEmissions 405,318,num2str(totTop)
				endif
			endif
			if (abs(massEm) > 100000)
				DrawText/W=PanelEmissions 470,318,num2str(massEm/100000)
				DrawText/W=PanelEmissions 480,330,"e+05"
			else
				if (abs(massEm) < 0.1)
					DrawText/W=PanelEmissions 470,318,num2str(massEm*100)
					DrawText/W=PanelEmissions 480,330,"e-02"
				else
					DrawText/W=PanelEmissions 470,318,num2str(massEm)
				endif
			endif
			DrawText/W=PanelEmissions 537,318,num2str(totLat + totTop - massEm)
						
			recordHistory()
//			killSurplusWaves ()

			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Display the wind and air flux screens
Function DispScreens(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String graphlist = WinList("Screens1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow Screens1
			endif
			Execute "Screens()"
			DoWindow/C Screens1
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//Print the time and data value at a given point on PositionSZC
Function PrintTime(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave PositionSZC, timestamp
	Variable csrC
	String csrTname
	switch( ba.eventCode )
		case 2: // mouse up
			csrTname = CsrWave(C)
			if (CmpStr(csrTname,"PositionSZC") == 0)
				csrC = pcsr(C)
				print "The concentration ", PositionSZC[csrC][2], " was recorded at ", date2str(timestamp[csrC])
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//Change the top mixing ratio
Function TopMix(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave TopMR
	Variable topRatio = 1
	NVAR bg, Mc, totLat, totTop, units
	Wave totalAirF
	switch( ba.eventCode )
		case 2: // mouse up
			NVAR massEm
			Wave totalAirFM
			Prompt topRatio, "Enter the top mixing ratio you want to use (in data units).  Enter NaN to reset: "
			DoPrompt "Mixing Ratio at Top of Box", topRatio
			
			if (V_flag)
				Abort
			endif
			
			if (numtype(topRatio) == 0)
				TopMR = topRatio
				bg = topRatio
			else
				TopValue()
			endif
			
			totLat = NaN
			totTop = NaN
			SetDrawLayer/W=PanelEmissions/K UserBack
			DrawText/W=PanelEmissions 27,318,num2str(totalAirF[0]*3600)
			DrawText/W=PanelEmissions 117,318,num2str(-totalAirF[0]*3600 + totalAirFM[0])
			DrawText/W=PanelEmissions 200,318,num2str(bg*10^(units))
			DrawText/W=PanelEmissions 285,318,num2str(Mc/28.97)
			if (abs(totLat) > 100000)
				DrawText/W=PanelEmissions 345,318,num2str(totLat/100000)
				DrawText/W=PanelEmissions 355,330,"e+05"
			else
				if (abs(totLat) < 0.1)
					DrawText/W=PanelEmissions 345,318,num2str(totLat*100)
					DrawText/W=PanelEmissions 355,330,"e-02"
				else
					DrawText/W=PanelEmissions 345,318,num2str(totLat)
				endif
			endif
			if (abs(totTop) > 100000)
				DrawText/W=PanelEmissions 405,318,num2str(totTop/100000)
				DrawText/W=PanelEmissions 415,330,"e+05"
			else
				if (abs(totLat) < 0.1)
					DrawText/W=PanelEmissions 405,318,num2str(totTop*100)
					DrawText/W=PanelEmissions 415,330,"e-02"
				else
					DrawText/W=PanelEmissions 405,318,num2str(totTop)
				endif
			endif
			if (abs(massEm) > 100000)
				DrawText/W=PanelEmissions 470,318,num2str(massEm/100000)
				DrawText/W=PanelEmissions 480,330,"e+05"
			else
				if (abs(massEm) < 0.1)
					DrawText/W=PanelEmissions 470,318,num2str(massEm*100)
					DrawText/W=PanelEmissions 480,330,"e-02"
				else
					DrawText/W=PanelEmissions 470,318,num2str(massEm)
				endif
			endif
			DrawText/W=PanelEmissions 537,318,num2str(totLat + totTop - massEm)
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Calculate the emission rate through a plume
Function PlumeEmis(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave ScreenU
	Variable/G displayScreen = 1

	switch( ba.eventCode )
		case 2: // mouse up
			mapEdgeImage(ScreenU)
			Execute "GraphPlume()"
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Calculate the emission rate through a chosen section of the screen
Function SelEmis(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR projNm

	switch( ba.eventCode )
		case 2: // mouse up
			if (CmpStr(projNm,"2018") == 0)
				GetScreen()
			else
				GetScreen_2013()
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//Calculate the average concentration in a chosen section of the screen
Function SelAvg(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR projNm

	switch( ba.eventCode )
		case 2: // mouse up
			if (CmpStr(projNm,"2018") == 0)
				averageScreen()
			else
				averageScreen_2013()
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//Display the time series
Function PlotTS(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			tSeries()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Display the vertical profile
Function PlotVP(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave timestamp
	
	switch( ba.eventCode )
		case 2: // mouse up
			vertProf(timestamp[0],timestamp[dimSize(timestamp,0)-1])
			String list = WinList("PlotProfiles",";","")
			if (strlen(list) > 0)
				KillWindow PlotProfiles
			endif
			Execute "PlotProfiles()"
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Change background value
Function changeBG(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR projNm

	switch( ba.eventCode )
		case 2: // mouse up
			if (CmpStr(projNm,"2018") == 0)
				chBG()
			else
				chBG_2013()
			endif
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ChArea(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave Lat, Lon

	switch( ba.eventCode )
		case 2: // mouse up
			String list = WinList("FlightTrack", ";", "")
			if (strlen(list) > 0)	
				KillWindow FlightTrack
			endif
			Execute "FlightTrack()"		
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DoneArea(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave Lat, Lon
	Variable xSt, xEnd, ySt, yEnd

	switch( ba.eventCode )
		case 2: // mouse up
			GetMarquee/W=FlightTrack left, bottom
			if (V_flag > 0)
				vertProfArea (V_left, V_right, V_bottom, V_top)
			else
				Prompt ySt, "Enter start latitude: "
				Prompt yEnd, "Enter end latitude: "
				Prompt xSt, "Enter start longitude: "
				Prompt xEnd, "Enter end longitude: "
				DoPrompt "Choose Area", ySt, yEnd, xSt, xEnd
				
				if (V_flag)
					Abort
				endif
				
				vertProfArea (xSt,xEnd,ySt,yEnd)
				
			endif
			KillWindow PlotProfiles
			Execute "PlotProfiles()"
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ChTime(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave timestamp
	Variable stT, endT
	String stTs = date2str(timestamp[0])
	String endTs = date2str(timestamp[dimSize(timestamp,0)-1])

	switch( ba.eventCode )
		case 2: // mouse up
			Prompt stTs, "Enter start date/time: "
			Prompt endTs, "Enter end date/time: "
			DoPrompt "Change Start and End Times", stTs, endTs
			
			if (V_flag)
				Abort
			endif
			
			stT = str2date(stTs)
			endT = str2date(endTs)
			String graphlist = WinList("GraphSurface1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow GraphSurface1
			endif
			KillWindow PlotProfiles
			vertProf (stT, endT)
			Execute "GraphSurface()"
			DoWindow/C GraphSurface1
			Execute "PlotProfiles()"
			
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose OK on Data panel
Function ButtonPanOK(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	SVAR dtNm, dataNm, fltName, betwPts, dataType, unitStr, location, projNm
	NVAR units, fltItem
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			ControlInfo popupdt
			dtNm = S_value
			ControlInfo popupdata
			dataNm = S_value
			ControlInfo popupproj
			projNm = S_value
			ControlInfo popupflt
			fltName = S_value
			fltItem = V_value
			ControlInfo popupfill
			betwPts = S_value
			ControlInfo popuptype
			dataType = S_value
			ControlInfo popupunit
			unitStr = S_value
			if (CmpStr(unitStr,"ppm") == 0)
				units = -6
			elseif (CmpStr(unitStr, "ppb") == 0)
				units = -9
			elseif (CmpStr(unitStr, "ug/m^3") == 0)
				units = -9
			else
				units = -12
			endif	
			ControlInfo popuploc
			location = S_value
			if (CmpStr(location,"Online") == 0 && CmpStr(projNm,"2013") == 0)
				NewPath/O/Q OS "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM\\Level_1_INTERIM\\AIRCRAFT\\TERRA__Flight_Screen_Variables"
			elseif (CmpStr(location,"Online") == 0)
				NewPath/O/Q OS "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM_2018\\AIRCRAFT\\Data_v1_INTERIM\\TERRA\\V1"
			else
				NewPath/O/Q OS
				if (V_flag)
					Abort
				endif
//				String fold = StringFromList(0,IndexedDir(OS,-1,1))
//				String foldMod = ReplaceString(";", fold, ":")
//				NewPath/O/Q OS2 foldMod
//				String file = IndexedFile(OS2,-1,".ibw")
//				if (strlen(file) == 0)
//					KillWindow Data
//					Abort "The selected directory does not contain the required data."
//				endif
			endif
			KillWindow Data
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose cancel on Data panel
Function ButtonPanCanc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			KillWindow Data
			Abort "You chose to cancel."
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//If user chooses a value other than 1 for sampling interval display secondary popup menu
Function SetVarSampInt(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			if (dval > 1)
				PopupMenu popupfill, disable = 0
				SetDrawLayer UserBack
				SetDrawEnv fname= "MS Sans Serif"
				DrawText 65,245,"Between the points recorded by the instrument, do you want to insert NaNs or assume "
				SetDrawEnv fname= "MS Sans Serif"
				DrawText 65,260,"that the instrument read value continues to be valid until the subsequent reading? "
			else
				PopupMenu popupfill, disable = 1
				SetDrawLayer UserBack
				DrawAction delete
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Changes list of flights that show up depending on what project has been selected
Function PopupProj (PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	SVAR fltList
	SVAR fltCode
	SVAR projNm
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			// click code here
			if (CmpStr(PU_Struct.popStr, "2013") == 0)
				fltList = "Flight 02;Flight 05;Flight 08;Flight 09;Flight 10;Flight 12 First Box;Flight 12 Second Box;Flight 12 Both Boxes;Flight 13 Full Facility;Flight 13 West Box;Flight 14;"
				fltList = fltList + "Flight 15 Syncrude Aurora;Flight 15 Shell;Flight 15 Suncor;Flight 17 First Box;Flight 17 Second Box;Flight 17 Both Boxes;Flight 18;Flight 21 Shell;Flight 21 Imperial;Flight 22"
				fltList = fltList + ";Flight 25 West Circle;Flight 25 East Circle;Flight 25 North Circle;Flight 26 South Circle;Flight 26 North Circle" 
				projNm = "2013"
				ControlUpdate popupflt
			else
				fltList = "Flight 03 Nexen;Flight 04 CNRL;Flight 04 Imperial;Flight 04 Firebag;Flight 06 CNRL;Flight 07 CNRL;Flight 08 CNRL;Flight 08 Fort Hills;"
				fltList = fltList + "Flight 08 Aurora;Flight 09 Firebag;Flight 09 Suncor;Flight 10 Syncrude;Flight 11 Suncor;Flight 12 Jackfish;Flight 12 MEG Christina Lake;"
				fltList = fltList + "Flight 12 Cenovus Christina Lake;Flight 13 Muskeg;Flight 15 Devon2;Flight 15 Devon1;Flight 15 SK4;Flight 15 SK3;Flight 15 SK2;Flight 15 SK1;"
				fltList = fltList + "Flight 15 SK5;Flight 16 Husky1;Flight 16 CNRL2;Flight 17 CNRL;Flight 17 YAJP Balloon;Flight 17 Syncrude Plume;Flight 18 Cenovus Foster Creek;"
				fltList = fltList + "Flight 18 Imperial Cold Lake;Flight 19 Syncrude;Flight 19 Suncor Mackay;Flight 20 Brion Energy;Flight 20 Syncrude;Flight 21 Imperial;Flight 21 Suncor;"
				fltList = fltList + "Flight 23 Imperial;Flight 23 Firebag;Flight 23 Brion Energy;Flight 28 Cenovus Foster Creek;Flight 28 Imperial Cold Lake;Flight 28 CNRL3;Flight 28 Husky2"
				
				fltCode = "F03_Nexen;F04_CNRL;F04_Imperial;F04_Firebag;F06_CNRL;F07_CNRL;F08_CNRL;F08_FortHills;F08_Aurora;F09_Firebag;F09_Suncor;F10_Syncrude;F11_Suncor;F12_Jackfish;"
				fltCode = fltCode + "F12_MEGCL;F12_CenovusCL;F13_Muskeg;F15_Devon2;F15_Devon1;F15_SK4;F15_SK3;F15_SK2;F15_SK1;F15_SK5;F16_Husky1;F16_CNRL2;F17_CNRL;F17_Balloon;"
				fltCode = fltCode + "F17_SMLPlume;F18_Foster;F18_ICL;F19_Syncrude;F19_Mackay;F20_Brion;F20_Syncrude;F21_Imperial;F21_Suncor;F23_Imperial;F23_Firebag;"
				fltCode = fltCode + "F23_Brion;F28_Foster;F28_ICL;F28_CNRL3;F28_Husky2"
				projNm = "2018"
				ControlUpdate popupflt
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
	
End

//Changes list of flights that show up depending on what project has been selected - screen flights
Function PopupProjScreen (PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	SVAR fltList
	SVAR fltCode
	SVAR projNm
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			// click code here
			if (CmpStr(PU_Struct.popStr, "2013") == 0)
				fltList = "Flight 02 - Screen 01 (downwind of Syncrude);Flight 03 - Screen 02 (downwind of CNRL);Flight 03 - Screen 03 (downwind of Syncrude);Flight 03 - Screen 04 (downwind of Suncor);"
				fltList = fltList + "Flight 04 - Screen 05 (downwind of Syncrude/Suncor);Flight 04 - Screen 06 (downwind of Shell/CNRL);Flight 05 - Screen 07 (North of Suncor);Flight 06 - Screen 08 (downwind of Syncrude);"
				fltList = fltList + "Flight 06 - Screen 09 (downwind of Suncor);Flight 07 - Screen 10 (West screen);Flight 07 - Screen 11 (centre screen);Flight 07 - Screen 12 (East screen);Flight 14 - Screen 13 (centre of Suncor);"
				fltList = fltList + "Flight 19 - Screen 14 (first screen);Flight 19 - Screen 15 (second screen);Flight 19 - Screen 16 (third screen);Flight 19 - Screen 17 (fourth screen);Flight 19 - Screen 18 (fifth screen);"
				fltList = fltList + "Flight 20 - Screen 19 (West screen);Flight 20 - Screen 20 (centre screen);Flight 20 - Screen 21 (East screen)"
				projNm = "2013"
				ControlUpdate popupflt
			else
				fltList = "Flight 01 - Screen 1A (north of Syncrude);Flight 01 - Screen 1B (north of Suncor and Firebag);Flight 01 - Screen 2 (north of OS);Flight 02 - Screen 1;Flight 02 - Screen 2;Flight 02 - Screen 3;Flight 02 - Screen 4;"
				fltList = fltList + "Flight 03 - Screen 1;Flight 03 - Screen 2;Flight 03 - Screen 3;Flight 03 - Screen 4;Flight 05 - Screen 1;Flight 05 - Screen 2;Flight 05 - Screen 3;Flight 05 - Screen 4;"
				fltList = fltList + "Flight 06 - Screen 1 (north of Syncrude and Suncor);Flight 06 - Screen 2 (southwest of OS);Flight 14 - Screen 1;Flight 14 - Screen 2;Flight 14 - Screen 3;Flight 14 - Screen 4;"
				fltList = fltList + "Flight 20 - Screen 1 (east of Syncrude);Flight 20 - Screen 2;Flight 21 - Screen 1 (north of Suncor);Flight 22 - Screen 1;Flight 22 - Screen 2;Flight 22 - Screen 3;Flight 23 - Screen 1 (northwest of Syncrude);"
				fltList = fltList + "Flight 24 - Screen 1;Flight 24 - Screen 2;Flight 24 - Screen 3;Flight 25 - Screen 1;Flight 25 - Screen 2;Flight 25 - Screen 3;Flight 25 - Screen 4;Flight 26 - Screen 1;"
				fltList = fltList + "Flight 27 - Screen 1;Flight 27 - Screen 2;Flight 27 - Screen 3;Flight 29 - Screen 1;Flight 29 - Screen 2;Flight 29 - Screen 3;Flight 29 - Screen 4;Flight 30 - Screen 1;Flight 30 - Screen 2;Flight 30 - Screen 3"
				fltCode = "F01_Screen1A;F01_Screen1B;F01_Screen2;F02_Screen1;F02_Screen2;F02_Screen3;F02_Screen4;F03_Screen1;F03_Screen2;F03_Screen3;F03_Screen4;F05_Screen1;F05_Screen2;F05_Screen3;F05_Screen4;"
				fltCode = fltCode + "F06_Screen1;F06_Screen2;F14_Screen1;F14_Screen2;F14_Screen3;F14_Screen4;F20_Screen1;F20_Screen2;F21_Screen;F22_Screen1;F22_Screen2;F22_Screen3;F23_Screen;"
				fltCode = fltCode + "F24_Screen1;F24_Screen2;F24_Screen3;F25_Screen1;F25_Screen2;F25_Screen3;F25_Screen4;F26_Screen1;F27_Screen;F27_Screen1;F27_Screen2;F29_Screen1;F29_Screen2;F29_Screen3;F29_Screen4;"
				fltCode = fltCode + "F30_Screen1;F30_Screen2;F30_Screen3"
				projNm = "2018"
				ControlUpdate popupflt
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
	
End

//Changes unit popup after the user has selected a data type
Function PopupGP (PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	String/G unitlist
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			// click code here
			if (CmpStr(PU_Struct.popStr, "Particles") == 0)
				unitlist = "ug/m^3"
			else
				unitlist= "ppm;ppb;ppt"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
	
End

//Creates clickable link to map of the flight path
Function FlightLink(s)
	STRUCT WMCustomControlAction &s
	SVAR flightPathLoc
	
	switch(s.eventCode)
		case kCCE_mouseup:
			BrowseURL/Z flightPathLoc
	endswitch
	
	return 0
	
End


//Resizes the buttons as the window is resized
Function resizeWindow(s)
	STRUCT WMWinHookStruct &s
	
	Variable statusCode= 0
	String win= s.winName
	
	String sRnm = win + "_sR"
	if (exists(sRnm) != 0)
	
		Wave widRatio = $(win + "_sR")
		Wave heiRatio = $(win + "_zR")
		Wave hPosRatio = $(win + "_hR")
		Wave vPosRatio = $(win + "_vR")
		strswitch (s.eventName) 
			case "resize":
				FitButtonsTERRA(win, widRatio, heiRatio, hPosRatio, vPosRatio)
				//statusCode=1	// allow other resize hooks to run
				break
		endswitch
		return statusCode	// 0 if nothing done, else 1 or 2
		
	endif
End


//Displays the unfilled data screen, values of each profile and the surface and a plot of the surface value of the user chosen profile
Window GraphSurface() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(511.5,43.25,1407.75,714.5) PositionSZC[*][1] vs PositionSZC[*][0]
	AppendToGraph ScreenPosZ
	AppendToGraph Frame[*][1] vs Frame[*][0]
	AppendToGraph/L=l1 Base[*][0],Base[*][1],Base[*][2],Base[*][3],Base[*][4]
	AppendToGraph/L=l2 UserBase
	AppendToGraph/L=l3 TopMR
	AppendToGraph currLeft[*][1] vs currLeft[*][0]
	AppendToGraph currRight[*][1] vs currRight[*][0]
	AppendToGraph currTop[*][1] vs currTop[*][0]
	AppendToGraph currBot[*][1] vs currBot[*][0]
	AppendImage/T ScreenU
	ModifyImage ScreenU ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=30,margin(bottom)=30,margin(top)=30,margin(right)=50
	ModifyGraph mode(PositionSZC)=2,mode(ScreenPosZ)=7,mode(Frame)=1,mode(Base#2)=4
	ModifyGraph lSize(PositionSZC)=2,lSize(Frame)=1.2,lSize(Base)=1.2,lSize(Base#1)=1.2
	ModifyGraph lSize(Base#3)=1.2,lSize(Base#4)=1.2
	ModifyGraph rgb(PositionSZC)=(0,0,0),rgb(ScreenPosZ)=(26112,26112,26112),rgb(Frame)=(0,0,0)
	ModifyGraph rgb(Base)=(0,0,0),rgb(Base#1)=(0,52224,0),rgb(Base#3)=(44032,29440,58880)
	ModifyGraph rgb(Base#4)=(39168,39168,0),rgb(UserBase)=(0,0,0),rgb(TopMR)=(0,0,0)
	ModifyGraph msize(Base#2)=2
	ModifyGraph hbFill(ScreenPosZ)=2
	ModifyGraph mirror(left)=2,mirror(bottom)=0,mirror(l1)=2,mirror(l2)=2,mirror(l3)=2
	ModifyGraph mirror(top)=0
	ModifyGraph nticks(left)=2,nticks(bottom)=18,nticks(l1)=2,nticks(l2)=2,nticks(l3)=2
	ModifyGraph nticks(top)=18
	ModifyGraph minor=1
	ModifyGraph fSize=8
	ModifyGraph lblMargin(bottom)=6,lblMargin(top)=12
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=25,lblPos(l1)=25,lblPos(l2)=25,lblPos(l3)=25
	ModifyGraph lblLatPos(bottom)=-1,lblLatPos(l1)=9,lblLatPos(l3)=9,lblLatPos(top)=412
	ModifyGraph tkLblRot(left)=90,tkLblRot(l1)=90,tkLblRot(l2)=90,tkLblRot(l3)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	ModifyGraph freePos(l1)={0,kwFraction}
	ModifyGraph freePos(l2)={0,kwFraction}
	ModifyGraph freePos(l3)={0,kwFraction}
	ModifyGraph axisEnab(left)={0.5,0.89}
	ModifyGraph axisEnab(l1)={0,0.3}
	ModifyGraph axisEnab(l2)={0.325,0.475}
	ModifyGraph axisEnab(l3)={0.91,1}
	Label left "\\Z10Altitude (m)"
	Label bottom "\\Z10\\f02s\\f00 [m]"
	Label l1 "\\Z10Surface Value"
	Label l3 "\\Z10Top Mixing Ratio"
	SetAxis left 0,nz
	SetAxis l1 -10,50
	Cursor/P/S=1/C=(0,15872,65280) A Base 0;Cursor/P/S=1/C=(16384,16384,65280) B Base 100;Cursor/P/S=1/C=(65280,0,52224) C PositionSZC 0
	ShowInfo
	Legend/C/N=text0/J/X=9.06/Y=66.84 "\\F'times'\\Z12\r\\s(Base) Constant\r\\s(Base#1) Linear Fit\r\\s(Base#2) Exponential\r\\s(Base#3) Background"
	AppendText "\\s(Base#4) Linear Between Constant and Background"
	ColorScale/C/N=text1/F=0/M/A=RT/X=-5.79/Y=10.06 image=ScreenU, heightPct=40
	ColorScale/C/N=text1 width=10, fsize=10, logLTrip=0.0001, lowTrip=0.1
	ControlBar/R 100
	TitleBox title0,pos={1095,192},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title1,pos={1095,480},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title2,pos={1095,664},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	Button button0,pos={1102,28},size={90,50},proc=DispScreens,title="Show Wind/\rAir Screens"
	Button button1,pos={1102,80},size={90,50},proc=PlotTS,title="Show Time\r Series"
	Button button2,pos={1102,132},size={90,50},proc=PlotVP,title="Show Vertical\r Profile"
	Button button3,pos={1102,212},size={90,50},proc=ResetAxis,title="Reset Axis"
	Button button4,pos={1102,264},size={90,50},proc=PrintTime,title="Print Values"
	Button button5,pos={1102,316},size={90,50},proc=PlumeEmis,title="Obtain Emission\rPlume"
	Button button6,pos={1102,368},size={90,50},proc=SelEmis,title="Obtain Emission\rSelected Section"
	Button button7,pos={1102,420},size={90,50},proc=SelAvg,title="Obtain Average\rSelected Section"
	Button button8,pos={1102,500},size={90,50},proc=TopMix,title="Change Top \rMixing Ratio"
	Button button9,pos={1102,552},size={90,50},proc=changeBG,title="Change \rBackground"
	Button button10,pos={1102,604},size={90,50},proc=upExtrap,title="Extrapolate\r Upward"
	Button button11,pos={1102,684},size={90,50},proc=SaveProf,title="Set Profiles"
	Button button12,pos={1102,736},size={90,50},proc=DoneProf,title="Calculate \rEmission Rates"
	Button button13,pos={1102,835},size={90,50},proc=Help,title="Help"
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro


//Displays the value of each profile at the surface
Window GraphGround() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(338.25,323,1068,538.25) Base[*][0],Base[*][1],Base[*][2] as "GraphGround"
	AppendToGraph Base[*][3]
	AppendToGraph Frame[0,4][1] vs Frame[0,4][0]
	ModifyGraph mode(Base#2)=4,mode(Frame)=1
	ModifyGraph lSize(Base)=1.2,lSize(Base#1)=1.2,lSize(Base#3)=1.2
	ModifyGraph rgb(Base)=(0,0,0),rgb(Base#1)=(0,52224,26368),rgb(Base#3)=(29440,0,58880)
	ModifyGraph rgb(Frame)=(0,0,0)
	ModifyGraph msize(Base#2)=2
	ModifyGraph grid(left)=1
	ModifyGraph zero(left)=1
	ModifyGraph mirror=1
	ModifyGraph nticks=20
	ModifyGraph font="Times New Roman"
	ModifyGraph fSize=12
	ModifyGraph highTrip(bottom)=1e+06
	ModifyGraph lowTrip(bottom)=0.0001
	ModifyGraph lblMargin=5
	ModifyGraph standoff=0
	ModifyGraph gridRGB(left)=(47872,47872,47872)
	Label left " Xsur [ppm]"
	Label bottom "\\f02s\\f00 [m]"
	SetAxis left 0,1.2
	Legend/C/N=text0/J/X=4.18/Y=11.85 "\\F'times'\\Z12\r\\s(Base) Constant\r\\s(Base#1) Linear\r\\s(Base#2) Exponential (w/ constant)"
	AppendText "\\s(Base#3) Exponential (filled gaps)"
EndMacro

//Displays a plot of each profile for each horizontal grid point
Window GraphProfiles() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(25.5,42.5,495,395)/VERT fltHeight[*][1] vs fltHeight[*][0]
	AppendToGraph/VERT Profile_pnts_C vs Profile_pnts_z
	AppendToGraph/VERT fit_Profile_pnts_C_L,fit_Profile_pnts_C
	AppendToGraph/VERT fit_Profile_pnts_C_C[*][1] vs fit_Profile_pnts_C_C[*][0]
	AppendToGraph/VERT fit_Profile_pnts_C_ZC[*][1] vs fit_Profile_pnts_C_ZC[*][0]
	AppendToGraph/VERT fit_Profile_pnts_C_Z[*][1] vs fit_Profile_pnts_C_Z[*][0]
	ModifyGraph margin(bottom)=110
	ModifyGraph mode(Profile_pnts_C)=3
	ModifyGraph marker(Profile_pnts_C)=19
	ModifyGraph lSize(fltHeight)=2
	ModifyGraph rgb(fltHeight)=(0,0,0),rgb(fit_Profile_pnts_C_L)=(0,52224,0),rgb(fit_Profile_pnts_C)=(65280,0,0)
	ModifyGraph rgb(fit_Profile_pnts_C_C)=(0,0,0),rgb(fit_Profile_pnts_C_ZC)=(39168,39168,0)
	ModifyGraph rgb(fit_Profile_pnts_C_Z)=(44032,29440,58880)
	ModifyGraph msize(Profile_pnts_C)=2
	ModifyGraph mirror=1
	ModifyGraph nticks=20
	ModifyGraph font="Times New Roman"
	ModifyGraph fSize=12
	ModifyGraph highTrip(bottom)=1e+06
	ModifyGraph lowTrip(bottom)=0.0001
	ModifyGraph lblMargin(left)=5,lblMargin(bottom)=70
	ModifyGraph standoff=0
	ModifyGraph lblLatPos(bottom)=-40
	Label left "Height Above Surface (m)"
	Label bottom "Concentration"
	SetAxis left 0,600
	SetAxis bottom 0,2.5
	Legend/C/N=text0/J/X=-4.26/Y=113.65 "\\Z10\\s(Profile_pnts_C) Points\r\\s(fit_Profile_pnts_C_C) Constant\r\\s(fit_Profile_pnts_C_L) Linear"
	AppendText "\\s(fit_Profile_pnts_C) Exponential\r\\s(fit_Profile_pnts_C_Z) Background\r\\s(fit_Profile_pnts_C_ZC) Linear Between Constant and BG"
	TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
	ControlBar/R 100
	Button button0,pos={534,23},size={90,50},proc=ProfilePrev,title="Previous"
	Button button1,pos={534,75},size={90,50},proc=ProfileNext,title="Next"
	SetVariable setvar0,pos={534,175},size={90,16},proc=ProfileVar,title=" "
	SetVariable setvar0,limits={0,dimSize(ScreenU,0),1},value= index
	SetVariable SetHeight,pos={533,250},size={90,16},proc=NewHeight,title=" "
	SetVariable SetHeight,limits={100,2000,10},value= height
	Button button2,pos={534,277},size={90,50},proc=RerunFits,title="Rerun"
	TitleBox title0,pos={543,139},size={64,34},title="Horizontal\rGrid Square:",frame=0
	TitleBox title1,pos={558,227},size={39,21},title="Height:",frame=0
	TitleBox title2,pos={526,205},size={120,10},title=" ",fixedSize=1,labelBack=(52224,52224,52224)
	TextBox/K/N=text1
	TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
	SetAxis bottom background, maxC	
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro

//Displays wind and air flux screens
Window Screens() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(334.5,20,1180.5,690.5)/L=L1 ScreenPosZ
	AppendToGraph/L=L2 ScreenPosZ
	AppendToGraph/B=HorizCrossing ScreenPosZ
	AppendToGraph Frame[0,5][1] vs Frame[0,5][0]
	AppendToGraph/L=L1 Frame[0,5][1] vs Frame[0,5][0]
	AppendToGraph/L=L2 Frame[0,5][1] vs Frame[0,5][0]
	AppendImage/T ScreenAirFlux
	ModifyImage ScreenAirFlux ctab= {*,*,Rainbow,1}
	AppendImage/T/L=L1 ScreenWindEf
	ModifyImage ScreenWindEf ctab= {*,*,Rainbow,1}
	AppendImage/T/L=L2 ScreenWindNf
	ModifyImage ScreenWindNf ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=50
	ModifyGraph mode(ScreenPosZ)=7,mode(ScreenPosZ#1)=7,mode(ScreenPosZ#2)=7,mode(Frame)=1
	ModifyGraph mode(Frame#1)=1,mode(Frame#2)=1
	ModifyGraph rgb(ScreenPosZ)=(34816,34816,34816),rgb(ScreenPosZ#1)=(34816,34816,34816)
	ModifyGraph rgb(ScreenPosZ#2)=(34816,34816,34816),rgb(Frame)=(0,0,0),rgb(Frame#1)=(0,0,0)
	ModifyGraph rgb(Frame#2)=(0,0,0)
	ModifyGraph hbFill(ScreenPosZ)=2,hbFill(ScreenPosZ#1)=2,hbFill(ScreenPosZ#2)=2
	ModifyGraph tick(bottom)=3,tick(HorizCrossing)=3
	ModifyGraph mirror(L1)=2,mirror(bottom)=0,mirror(L2)=2,mirror(left)=2,mirror(top)=0
	ModifyGraph nticks(L1)=2,nticks(L2)=2,nticks(left)=2,nticks(top)=20
	ModifyGraph minor(L1)=1,minor(L2)=1,minor(left)=1,minor(top)=1
	ModifyGraph noLabel(bottom)=2,noLabel(HorizCrossing)=2
	ModifyGraph fSize(L1)=8,fSize(L2)=8,fSize(left)=8,fSize(top)=8
	ModifyGraph standoff(left)=0,standoff(top)=0
	ModifyGraph lblPos(bottom)=12,lblPos(left)=13,lblPos(HorizCrossing)=-540
	ModifyGraph lblLatPos(HorizCrossing)=6
	ModifyGraph tkLblRot(L1)=90,tkLblRot(L2)=90,tkLblRot(left)=90
	ModifyGraph btLen(L1)=3,btLen(L2)=3,btLen(left)=3,btLen(top)=3
	ModifyGraph tlOffset(L1)=-2,tlOffset(L2)=-2,tlOffset(left)=-2,tlOffset(top)=-2
	ModifyGraph freePos(L1)=1
	ModifyGraph freePos(L2)=0
	ModifyGraph freePos(HorizCrossing)=-27
	ModifyGraph tickZap(HorizCrossing)={0}
	ModifyGraph axisEnab(L1)={0.33,0.63}
	ModifyGraph axisEnab(L2)={0.66,0.96}
	ModifyGraph axisEnab(left)={0,0.3}
	SetAxis left 0,nz
	SetAxis L1 0,nz
	SetAxis L2 0,nz
	TextBox/C/N=text0/F=0/A=MC/X=3.26/Y=-19.23 "Air Flux Screen"
	TextBox/C/N=text1/F=0/A=MC/X=2.93/Y=47.32 "North Wind Screen"
	TextBox/C/N=text2/F=0/A=MC/X=3.02/Y=14.34 "East Wind Screen"
	ColorScale/C/N=text3/F=0/A=MC/X=53.64/Y=-35.31 image=ScreenAirFlux, heightPct=30
	ColorScale/C/N=text3 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "kg m\\S-2\\M s\\S-1\\M"
	ColorScale/C/N=text4/F=0/A=MC/X=53.26/Y=-2.21 image=ScreenWindEf, heightPct=30
	ColorScale/C/N=text4 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "m/s"
	ColorScale/C/N=text5/F=0/A=MC/X=53.35/Y=30.89 image=ScreenWindNf, heightPct=30
	ColorScale/C/N=text5 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "m/s"
EndMacro

//Displays exponential fitting coefficients
Window GraphABC() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(80.25,68,822.75,427.25)/L=Cbg FitExpCbg[0,1463]
	AppendToGraph/L=B FitExpB[0,1463]
	AppendToGraph/L=A FitExpA[0,1463]
	AppendToGraph/L=C FitExpC[0,1463]
	AppendToGraph/L=R2 FitExpR2[0,1463]
	AppendToGraph/R Frame[0,4][1] vs Frame[0,4][0]
	ModifyGraph mode(FitExpCbg)=2,mode(FitExpB)=2,mode(FitExpA)=2,mode(FitExpR2)=2,mode(Frame)=1
	ModifyGraph lSize(FitExpCbg)=1.2,lSize(FitExpB)=1.2,lSize(FitExpA)=1.2,lSize(FitExpR2)=1.2
	ModifyGraph rgb(FitExpCbg)=(0,0,0),rgb(FitExpB)=(0,15872,65280),rgb(FitExpR2)=(0,52224,0)
	ModifyGraph rgb(Frame)=(0,0,0)
	ModifyGraph grid(Cbg)=1,grid(B)=1,grid(A)=1,grid(R2)=1
	ModifyGraph tick(right)=3
	ModifyGraph zero(Cbg)=1,zero(B)=1,zero(A)=1,zero(R2)=1
	ModifyGraph mirror(Cbg)=1,mirror(bottom)=1,mirror(B)=1,mirror(A)=1,mirror(R2)=1
	ModifyGraph nticks(bottom)=20
	ModifyGraph font(Cbg)="Times New Roman",font(bottom)="Times New Roman",font(B)="Times New Roman"
	ModifyGraph font(A)="Times New Roman",font(R2)="Times New Roman"
	ModifyGraph noLabel(right)=2
	ModifyGraph fSize(Cbg)=12,fSize(bottom)=12,fSize(B)=12,fSize(A)=12,fSize(R2)=12
	ModifyGraph highTrip(bottom)=1e+06
	ModifyGraph lowTrip(bottom)=0.0001,lowTrip(B)=0.0001
	ModifyGraph lblMargin(Cbg)=10,lblMargin(bottom)=5,lblMargin(B)=10,lblMargin(A)=10
	ModifyGraph lblMargin(R2)=10
	ModifyGraph standoff=0
	ModifyGraph gridRGB(Cbg)=(47872,47872,47872),gridRGB(B)=(47872,47872,47872),gridRGB(A)=(47872,47872,47872)
	ModifyGraph gridRGB(R2)=(47872,47872,47872)
	ModifyGraph lblPosMode(Cbg)=1,lblPosMode(B)=1,lblPosMode(A)=1,lblPosMode(R2)=1
	ModifyGraph freePos(Cbg)=0
	ModifyGraph freePos(B)=0
	ModifyGraph freePos(A)=0
	ModifyGraph freePos(R2)=0
	ModifyGraph axisEnab(Cbg)={0,0.25}
	ModifyGraph axisEnab(B)={0.5,0.75}
	ModifyGraph axisEnab(A)={0.25,0.5}
	ModifyGraph axisEnab(R2)={0.75,1}
	Label Cbg "Cbg"
	Label B "B"
	Label A "A"
	Label R2 "R2"
	SetAxis/A/N=1 Cbg
	SetAxis bottom 7074.66424976156,57684.4696848393
	SetAxis/A/N=1 B
	SetAxis/N=1 A -39.9874047999999,108.5237248
	SetAxis right 2000,2000
EndMacro

//Displays linear fitting coefficients
Window Graphab() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(542.25,85.25,1302.75,444.5)/L=B Fitb[0,1463]
	AppendToGraph/L=A Fita[0,1463]
	AppendToGraph/L=R2 FitR2[0,1463]
	ModifyGraph mode=2
	ModifyGraph lSize=1.2
	ModifyGraph rgb(Fitb)=(0,15872,65280),rgb(FitR2)=(0,52224,0)
	ModifyGraph grid(B)=1,grid(A)=1,grid(R2)=1
	ModifyGraph zero(B)=1,zero(A)=1,zero(R2)=1
	ModifyGraph mirror=1
	ModifyGraph nticks(bottom)=20
	ModifyGraph font="Times New Roman"
	ModifyGraph fSize=12
	ModifyGraph highTrip(bottom)=1e+06
	ModifyGraph lowTrip(bottom)=0.0001
	ModifyGraph lblMargin(B)=10,lblMargin(bottom)=5,lblMargin(A)=10,lblMargin(R2)=10
	ModifyGraph standoff=0
	ModifyGraph gridRGB(B)=(47872,47872,47872),gridRGB(A)=(47872,47872,47872),gridRGB(R2)=(47872,47872,47872)
	ModifyGraph lblPosMode(B)=1,lblPosMode(A)=1,lblPosMode(R2)=1
	ModifyGraph freePos(B)=0
	ModifyGraph freePos(A)=0
	ModifyGraph freePos(R2)=0
	ModifyGraph axisEnab(B)={0.35,0.65}
	ModifyGraph axisEnab(A)={0,0.3}
	ModifyGraph axisEnab(R2)={0.7,1}
	Label B "b"
	Label A "a"
	Label R2 "R2"
	SetAxis/A/N=1 B
	SetAxis/A/N=1 A
	SetAxis R2 0,1
EndMacro

//Displays emission results from a screen
Window PanelEmissions() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(31,571,663,967)
	ModifyPanel cbRGB=(65534,65534,65534)
	SetDrawLayer ProgBack
	DrawRect 22,202,603,346
	DrawLine 105,202,105,346
	DrawLine 188,202,188,346
	DrawLine 271,202,271,346
	DrawLine 333,202,333,346
	DrawLine 395,202,395,346
	DrawLine 457,202,457,346
	DrawLine 520,202,520,346
	DrawLine 22,274,603,274
	SetDrawEnv fsize= 20
	DrawText 45,247,"E\\Bair,H\\M"
	SetDrawEnv fsize= 20
	DrawText 131,247,"E\\Bair,V\\M"
	SetDrawEnv fsize= 20
	DrawText 212,247,"X\\BTop\\M"
	SetDrawEnv fsize= 20
	DrawText 290,247,"M\\BR\\M"
	SetDrawEnv fsize= 20
	DrawText 345,247,"E\\BC,H\\M"
	SetDrawEnv fsize= 20
	DrawText 405,247,"E\\BC,V\\M"
	SetDrawEnv fsize= 20
	DrawText 470,247,"E\\BC,M\\M"
	SetDrawEnv fsize= 20
	DrawText 551,247,"E\\BC\\M"
	SetDrawEnv fsize= 20
	DrawText 165,35,"E\\BC\\M = E\\BC,H\\M + E\\BC,V\\M - E\\BC,M\\M"
	SetDrawEnv fsize= 20
	DrawText 116,109,"E\\Bair,H\\M + E\\Bair,V\\M - E\\Bair,M\\M = 0"
	SetDrawEnv fsize= 20
	DrawText 83,153,"E\\BC,V\\M = M\\BR\\MX\\BTop\\ME\\Bair,V\\M = -M\\BR\\MX\\BTop\\ME\\Bair,H\\M"
	SetDrawEnv fsize= 20
	DrawText 135,189,"E\\BC\\M = E\\BC,H\\M - M\\BR\\MX\\BTop\\ME\\Bair,H\\M"
	SetDrawEnv fsize= 16
	DrawText 35,29,"Mass Balance: "
	DrawText 71,53,"Total emission rate"
	DrawText 129,71,"Emission rate through box sides"
	DrawText 331,70,"Emission rate through box top"
	DrawText 398,51,"Change in mass within volume"
	SetDrawEnv fsize= 16
	DrawText 37,103,"Air Flux: "
	SetDrawEnv arrow= 1
	DrawLine 227,58,227,34
	SetDrawEnv arrow= 1
	DrawLine 136,38,159,25
	SetDrawEnv arrow= 2
	DrawLine 308,33,345,54
	SetDrawEnv arrow= 2
	DrawLine 370,28,395,39
	DrawText 451,169,"M\\BR\\M = Molar mass ratio"
	DrawText 449,150,"X\\BTop\\M = Mixing ratio at box top"
//	DrawLine 329,33,363,7
//	SetDrawEnv fsize= 10
//	DrawText 366,12,"0"
//	DrawLine 243,111,280,81
//	SetDrawEnv fsize= 10
//	DrawText 282,86,"0"
	SetDrawEnv fsize= 14
	DrawText 345,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 405,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 545,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 45,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 132,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 470,264,"(kg/hr)"
	SetDrawEnv fsize= 14
//	DrawText 220,264,("(" + unitStr + ")")
	DrawText 26,374,"For further details see algorithm in Gordon et al., 2015"
//	CustomControl link,pos={490,357},size={165,19},proc=FlightLink,title="Flight Path",frame=0,fStyle=4,fSize=14,valueColor=(0,0,65535)
	SetDrawLayer UserBack
	DrawText 27,318,num2str(totalAirF[0]*3600)
	DrawText 117,318,num2str(-totalAirF[0]*3600 + totalAirFM[0])
	DrawText 200,318,num2str(bg*10^(units))
	DrawText 285,318,num2str(Mc/28.97)
	if (abs(totLat) > 100000)
		DrawText 345,318,num2str(totLat/100000)
		DrawText 355,330,"e+05"
	else
		if (abs(totLat) < 0.1)
			DrawText 345,318,num2str(totLat*100)
			DrawText 355,330,"e-02"
		else
			DrawText 345,318,num2str(totLat)
		endif
	endif
	if (abs(totTop) > 100000)
		DrawText 405,318,num2str(totTop/100000)
		DrawText 415,330,"e+05"
	else
		if (abs(totLat) < 0.1)
			DrawText 405,318,num2str(totTop*100)
			DrawText 415,330,"e-02"
		else
			DrawText 405,318,num2str(totTop)
		endif
	endif
	if (abs(massEm) > 100000)
		DrawText 470,318,num2str(massEm/100000)
		DrawText 480,330,"e+05"
	else
		if (abs(massEm) < 0.1)
			DrawText 470,318,num2str(massEm*100)
			DrawText 480,330,"e-02"
		else
			DrawText 470,318,num2str(massEm)
		endif
	endif
	DrawText 545,318,num2str(totLat + totTop - massEm)
EndMacro

//Displays a history of the operations the user has performed
Window TableHistory() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:History:
	Edit/W=(14.25,64.25,1426.5,301.25) runTime,dtName,dataName,fltNumb,EC,EH,EV,Em,EairH
	AppendToTable EairV,molMass,molMassAir,molMassRatio,fltHeight,mixRatioTop,profNm
	AppendToTable profSt,profStS,profEnd,profEndS
	ModifyTable format(Point)=1,width(Point)=20,format(runTime)=8,sigDigits(runTime)=10
	ModifyTable width(runTime)=108,title(runTime)="Time of Run",sigDigits(dtName)=10
	ModifyTable title(dtName)="Date/Time Wave",sigDigits(dataName)=10,title(dataName)="Data Wave"
	ModifyTable sigDigits(fltNumb)=10,width(fltNumb)=51,title(fltNumb)="Flight",sigDigits(EC)=10
	ModifyTable width(EC)=132,title(EC)="Total Emission Rate (kg/hr)",sigDigits(EH)=10
	ModifyTable width(EH)=131,title(EH)="Lateral Emission (kg/hr)",sigDigits(EV)=10
	ModifyTable width(EV)=107,title(EV)="Top Emission (kg/hr)",sigDigits(EairH)=10,width(EairH)=132
	ModifyTable width(Em)=107,title(Em)="Mass Emission (kg/hr)",sigDigits(Em)=10,width(Em)=132	
	ModifyTable title(EairH)="Lateral Air Emission (kg/hr)",sigDigits(EairV)=10,width(EairV)=122
	ModifyTable title(EairV)="Top Air Emission (kg/hr)",sigDigits(molMass)=10,width(molMass)=95
	ModifyTable title(molMass)="Molar Mass (g/mol)",sigDigits(molMassAir)=10,width(molMassAir)=116
	ModifyTable title(molMassAir)="Molar Mass of Air (g/mol)",sigDigits(molMassRatio)=10
	ModifyTable width(molMassRatio)=111,title(molMassRatio)="Ratio of Molar Masses"
	ModifyTable sigDigits(fltHeight)=10,width(fltHeight)=84,title(fltHeight)="Fitting Height (m)"
	ModifyTable sigDigits(mixRatioTop)=10,width(mixRatioTop)=123,title(mixRatioTop)="Mixing Ratio at Box Top"
	ModifyTable sigDigits(profNm)=10,width(profNm)=57,title(profNm)="Profile",sigDigits(profSt)=10
	ModifyTable width(profSt)=92,title(profSt)="Profile Start (index)",width(profStS)=140
	ModifyTable title(profStS)="Profile Start (s position in m)",sigDigits(profEnd)=10
	ModifyTable width(profEnd)=101,title(profEnd)="Profile End (index)",width(profEndS)=137
	ModifyTable title(profEndS)="Profile End (s position in m)"
	SetDataFolder fldrSav0
EndMacro

//Screen Versions of the Functions
Function quickKrigScreen ()
	String fltNum, flight, fltF, dash, screen, screenNum
	String cont, year, month, day
	Variable fitType, i
	Variable/G height = 300
	Variable/G maxC = 2
	String/G fltName, dtNm, dataNm, betwPts, unitStr, location, dataType	
	Variable/G units = -9
	Variable/G totLat = NaN, totTop = NaN
	String/G unitlist = "ppm;ppb;ppt"
	String filePre, fileSuf
	Variable/G fltItem
	
	if (exists("smpInt") == 0)
		Variable/G smpInt = 1
	else
		NVAR smpInt
	endif
	
	if (exists("Mc") == 0)
		Variable/G Mc = 28.97
	else
		NVAR Mc
	endif
	
	if (exists("background") == 0)
		Variable/G background = 0
	else
		NVAR background
	endif	
	
	if (CmpStr(dataType,"Particles") == 0)
		unitlist = "ug/m^3"
	endif
	
	if (exists("bs") == 0)
		String/G bs = "screen"
	else
		SVAR bs
		if (CmpStr(bs,"box") == 0)
			fltName = ""
			bs = "screen"
		endif
	endif
	
	if (exists("projNm") == 0)
		String/G projNm = "2013"
	else
		SVAR projNm
	endif	
	
	//Close any open graph windows if they exist
	String graphlist = WinList("GraphSurface1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphSurface1
	endif
	graphlist = WinList("GraphProfiles1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphProfiles1
	endif
	graphlist = WinList("PanelEmissionsScreen*", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow/Z PanelEmissions
		KillWindow/Z PanelEmissionsScreen
	endif
	String origList = WaveList("*original*",";","")
	for (i = 0; i < ItemsInList(origList); i += 1)
		KillWaves/Z $StringFromList(i, origList)
	endfor
	
	if (CmpStr(projNm,"2013") == 0)
		String/G fltList = "Flight 02 - Screen 01 (downwind of Syncrude);Flight 03 - Screen 02 (downwind of CNRL);Flight 03 - Screen 03 (downwind of Syncrude);Flight 03 - Screen 04 (downwind of Suncor);"
		fltList = fltList + "Flight 04 - Screen 05 (downwind of Syncrude/Suncor);Flight 04 - Screen 06 (downwind of Shell/CNRL);Flight 05 - Screen 07 (North of Suncor);Flight 06 - Screen 08 (downwind of Syncrude);"
		fltList = fltList + "Flight 06 - Screen 09 (downwind of Suncor);Flight 07 - Screen 10 (West screen);Flight 07 - Screen 11 (centre screen);Flight 07 - Screen 12 (East screen);Flight 14 - Screen 13 (centre of Suncor);"
		fltList = fltList + "Flight 19 - Screen 14 (first screen);Flight 19 - Screen 15 (second screen);Flight 19 - Screen 16 (third screen);Flight 19 - Screen 17 (fourth screen);Flight 19 - Screen 18 (fifth screen);"
		fltList = fltList + "Flight 20 - Screen 19 (West screen);Flight 20 - Screen 20 (centre screen);Flight 20 - Screen 21 (East screen)"
		String/G fltCode = ""
	else
		String/G fltList = "Flight 01 - Screen 1A (north of Syncrude);Flight 01 - Screen 1B (north of Suncor and Firebag);Flight 01 - Screen 2 (north of OS);Flight 02 - Screen 1;Flight 02 - Screen 2;Flight 02 - Screen 3;Flight 02 - Screen 4;"
		fltList = fltList + "Flight 03 - Screen 1;Flight 03 - Screen 2;Flight 03 - Screen 3;Flight 03 - Screen 4;Flight 05 - Screen 1;Flight 05 - Screen 2;Flight 05 - Screen 3;Flight 05 - Screen 4;"
		fltList = fltList + "Flight 06 - Screen 1 (north of Syncrude and Suncor);Flight 06 - Screen 2 (southwest of OS);Flight 14 - Screen 1;Flight 14 - Screen 2;Flight 14 - Screen 3;Flight 14 - Screen 4;"
		fltList = fltList + "Flight 20 - Screen 1 (east of Syncrude);Flight 20 - Screen 2;Flight 21 - Screen 1 (north of Suncor);Flight 22 - Screen 1;Flight 22 - Screen 2;Flight 22 - Screen 3;Flight 23 - Screen 1 (northwest of Syncrude);"
		fltList = fltList + "Flight 24 - Screen 1;Flight 24 - Screen 2;Flight 24 - Screen 3;Flight 25 - Screen 1;Flight 25 - Screen 2;Flight 25 - Screen 3;Flight 25 - Screen 4;Flight 26 - Screen 1;"
		fltList = fltList + "Flight 27 - Screen 1;Flight 27 - Screen 2;Flight 27 - Screen 3;Flight 29 - Screen 1;Flight 29 - Screen 2;Flight 29 - Screen 3;Flight 29 - Screen 4;Flight 30 - Screen 1;Flight 30 - Screen 2;Flight 30 - Screen 3"
		String/G fltCode = "F01_Screen1A;F01_Screen1B;F01_Screen2;F02_Screen1;F02_Screen2;F02_Screen3;F02_Screen4;F03_Screen1;F03_Screen2;F03_Screen3;F03_Screen4;F05_Screen1;F05_Screen2;F05_Screen3;F05_Screen4;"
		fltCode = fltCode + "F06_Screen1;F06_Screen2;F14_Screen1;F14_Screen2;F14_Screen3;F14_Screen4;F20_Screen1;F20_Screen2;F21_Screen;F22_Screen1;F22_Screen2;F22_Screen3;F23_Screen;"
		fltCode = fltCode + "F24_Screen1;F24_Screen2;F24_Screen3;F25_Screen1;F25_Screen2;F25_Screen3;F25_Screen4;F26_Screen1;F27_Screen;F27_Screen1;F27_Screen2;F29_Screen1;F29_Screen2;F29_Screen3;F29_Screen4;"
		fltCode = fltCode + "F30_Screen1;F30_Screen2;F30_Screen3"
	endif
	
	//Prompt user for information
	NewPanel/N=Data /W=(700,158,1330,700)
	PopupMenu popupdt,pos={65,40},size={235,21},title="Choose date/time column: "
	PopupMenu popupdt,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dtNm
	PopupMenu popupdata,pos={65,80},size={211,21},title="Choose data column: "
	PopupMenu popupdata,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dataNm
	PopupMenu popupproj,pos={65,120},size={135,21},title="Choose project: "
	PopupMenu popupproj,mode=1,value="2013;2018",proc=PopupProjScreen,popvalue=projNm
	PopupMenu popupflt,pos={65,160},size={135,21},title="Choose flight: "
	PopupMenu popupflt,mode=1,value= #"fltList",popvalue=fltName
	SetVariable setvarsmp,pos={65,200},size={200,16},title="Enter sampling interval (in s): "
	SetVariable setvarsmp,limits={1,inf,1},value= smpInt, proc=SetVarSampInt
	PopupMenu popupfill,disable=1,pos={500,240},size={47,21}
	PopupMenu popupfill,mode=1,value= "NaN;Value",popvalue=betwPts
	if (smpInt > 1)
		PopupMenu popupfill,disable=0
		SetDrawLayer UserBack
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,245,"Between the points recorded by the instrument, do you want to insert NaNs or assume "
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,260,"that the instrument read value continues to be valid until the subsequent reading? "
	endif
	PopupMenu popuptype,pos={65,280},size={240,12},mode=1,value="Gas;Particles",proc=PopupGP,title="What type of data is being loaded? ",popvalue=dataType	
	SetVariable setvarmass,pos={65,320},size={300,16},title="Enter the molar mass of the quantity (g/mol): "
	SetVariable setvarmass,limits={0,inf,1},value= Mc
	SetVariable setvarbg,pos={65,360},size={350,16},title="Enter the background value (enter 0 if this is unknown): ",limits={0,inf,1},value=background
	PopupMenu popupunit,mode=1,pos={65,400},size={300,16},title="What units are your data in? ", value=#"unitlist",popvalue=unitStr
	PopupMenu popuploc,pos={65,440},mode=1,size={300,16},title="Where do you want to load weights from?", value="Online;Local",popvalue=location
	Button buttonOK,pos={100,490},size={50,20},proc=ButtonPanOK,title="OK"
	Button buttonCanc,pos={435,490},size={50,20},proc=ButtonPanCanc,title="Cancel"
	PauseForUser Data
	
	Wave dt = $dtNm
	Wave data = $dataNm
	
	//If the sampling interval is not 1 then run the function to create a 1 second time series for that data
	if (smpInt < 1)
		Abort "Sampling interval is too small."
	elseif (smpInt > 1)		
		if (CmpStr(betwPts, "Value") == 0)
			createNewTimeSeries(dtNm, dataNm, smpInt)
			Wave dt = dt1sec
			Wave data = data1sec
		endif
	endif	
	
	String flightNumber, format, desc
	
	//2013 Campaign
	if (CmpStr(projNm,"2013") == 0)	
	
		//Get the flight number
		format = "%s %s %s %s %s"
		sscanf fltName, format, flight, fltNum, dash, screen, screenNum
		
		flightNumber = "Flight" + num2str(str2num(fltNum))
		
		//Load in the premade Igor binary files
		String fileFold = "F" + fltNum + "_Screen"
		fileSuf = "Screen" + screenNum
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":weights_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":weightsLoc_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":WindDir_" + fileSuf + ".ibw")
		
	//2018 Campaign
	elseif (CmpStr(projNm,"2018") == 0)
		fltItem = WhichListItem(fltName,fltList)
		filePre = StringFromList(fltItem,fltCode)
		fileSuf = filePre
		
		format = "%3s_%s"
		sscanf filePre, format, fltNum, desc		
		flightNumber = fltNum
		
		//Load in the premade Igor binary files
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
		LoadData/O/Q/P=OS (":" + filePre + ":weights_" + fileSuf + ".pxp")
	endif

	//Move ScreenFlux to ScreenAirFlux
	Wave ScreenFlux
	Duplicate/O ScreenFlux, ScreenAirFlux
	KillWaves/Z ScreenFlux
//	PT_FlightTimes()
	
	//Load varValues values into the appropriate variables
	Wave varValues
	Variable/G ns = varValues[0]
	Variable/G nz = varValues[1] 
	Variable/G ds = varValues[2]
	Variable/G dz = varValues[3]
	Variable/G index = floor(ns/ds) 
	Variable/G indmax = floor(ns/ds)
	
	//Create the PositionSZC wave (consists of position and concentration during the flight)
	createConcWv (dt, data)
	Wave PositionSZC, Concentration, timestamp
	WaveStats/Q Concentration
	if (V_numNaNs != 0)
		fillNaNsTS(timestamp, Concentration)
	endif
	
	//If there are no points then the times did not match up and the wrong flight has been chosen
	Duplicate/O/R=(0,dimSize(PositionSZC,0))(2,2) PositionSZC, quantTemp
	WaveStats/Q quantTemp
	if (V_npnts == 0)
		Abort "You have selected the wrong flight number"
	endif
	KillWaves/Z quantTemp
	
	//Create link to flight path for PanelEmissions
	Wave timestamp
	String dateSt = date2str(timestamp[0])
	format = "%4s-%2s-%2s"
	sscanf dateSt, format, year, month, day
	String/G flightPathLoc
	
	if (CmpStr(projNm, "2013") == 0)
		if (CmpStr(month, "08") == 0)
			month = "Aug"
		else
			month = "Sep"
		endif
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM\\Level_0_RAW\\AIRCRAFT\\Plots\\OS2013_" + month + day + "_" + flightNumber + "_Map.jpg"
	elseif (CmpStr(projNm, "2018") == 0)
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM_2018\\AIRCRAFT\\Metadata\\Maps\\" + flightNumber + "_FlightTrack.jpg"
	endif	
	
	//Run the kriging routine and create a screen of the results
	runInterpNoPromptScreen ()
	Wave intVal
	Wave fltGridPts
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
	Redimension/N=-1 xWv, yWv
	Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
	Wave ScreenKrig, ScreenWindEf, ScreenWindNf, ScreenAirf //Frame
	
	//If there is an extra line, delete it
	if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
		DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
	endif
	
	UnfillAboveData()
	Unfill()												//Unfill the screen above and below the flight path
	Wave ScreenU
	SVAR unitStr
	
	if (CmpStr(unitStr, "ug/m^3") == 0)	
		Duplicate/O PositionSZC, PositionSZC_oldUnits
		Duplicate/O ScreenU, ScreenU_ugm3
		convertP_Units()
		runInterpNoPromptScreen()
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
		Redimension/N=-1 xWv, yWv
		Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
		if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
			DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
		endif
		UnfillAboveData()
		Unfill()
		Duplicate/O ScreenU, ScreenU_ppb
		Duplicate/O ScreenU_ugm3, ScreenU
	endif
	
	KillWaves/Z weights, weightsLoc
	
	Variable num = dimSize(ScreenKrig,0)
	
	Wave ScreenPosZ

	if (CmpStr(projNm,"2018") == 0)			//2018 campaign
	
		ProfilesOther()										//Calculate the profiles to the ground for zero, constant and line between zero and constant
		ProfilesLine(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C			
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp(height)									//Calculate the exponential fits
		ResetProfiles()										//Go to the previous point	
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		TopValue()											//Get values for top of the screen	
		Fill()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface
		
	else											//2013 campaign
	
		ProfilesOther_2013()										//Calculate the profiles to the ground for zero, constant and line between zero and constant
		ProfilesLine_2013(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C			
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp_2013(height)									//Calculate the exponential fits
		ResetProfiles_2013()										//Go to the previous point	
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		TopValue()											//Get values for top of the screen	
		Fill_2013()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface

	endif
	
	Make/D/O/N=(floor(ns/ds)) UserBase = NaN	
	SetScale/P x 0,40,"", UserBase
	Make/T/O/N=(floor(ns/ds)) Fit_Flag = ""
	Execute "GraphSurfaceScreen()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	createRatios("GraphSurface1")
	Wave widRatio, heiRatio, vPosRatio, hPosRatio
	Duplicate/O widRatio, GraphSurface1_sR
	Duplicate/O heiRatio, GraphSurface1_zR
	Duplicate/O hPosRatio, GraphSurface1_hR
	Duplicate/O vPosRatio, GraphSurface1_vR
	Execute "PanelEmissionsScreen()"

End

Function fullKrigScreen()
	String fltNum, flight, fltF, dash, screen, screenNum
	String cont, year, month, day
	Variable fitType, i
	Variable/G height = 300
	Variable/G maxC = 2
	String/G fltName, dtNm, dataNm, betwPts, unitStr, location, dataType
	Variable/G units = -9
	Variable/G totLat = NaN, totTop = NaN
	String/G unitlist = "ppm;ppb;ppt"
	String filePre, fileSuf
	
	if (exists("smpInt") == 0)
		Variable/G smpInt = 1
	else
		NVAR smpInt
	endif
	
	if (exists("Mc") == 0)
		Variable/G Mc = 28.97
	else
		NVAR Mc
	endif
	
	if (exists("background") == 0)
		Variable/G background = 0
	else
		NVAR background
	endif	
	
	if (CmpStr(dataType,"Particles") == 0)
		unitlist = "ug/m^3"
	endif
	
	if (exists("bs") == 0)
		String/G bs = "screen"
	else
		SVAR bs
		if (CmpStr(bs,"box") == 0)
			fltName = ""
			bs = "screen"
		endif
	endif
	
	if (exists("projNm") == 0)
		String/G projNm = "2013"
	else
		SVAR projNm
	endif	
	
	//Close any open graph windows if they exist
	String graphlist = WinList("GraphSurface1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphSurface1
	endif
	graphlist = WinList("GraphProfiles1", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow GraphProfiles1
	endif
	graphlist = WinList("PanelEmissionsScreen*", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow/Z PanelEmissions
		KillWindow/Z PanelEmissionsScreen
	endif
	String origList = WaveList("*original*",";","")
	for (i = 0; i < ItemsInList(origList); i += 1)
		KillWaves/Z $StringFromList(i, origList)
	endfor

	if (CmpStr(projNm,"2013") == 0)
		String/G fltList = "Flight 02 - Screen 01 (downwind of Syncrude);Flight 03 - Screen 02 (downwind of CNRL);Flight 03 - Screen 03 (downwind of Syncrude);Flight 03 - Screen 04 (downwind of Suncor);"
		fltList = fltList + "Flight 04 - Screen 05 (downwind of Syncrude/Suncor);Flight 04 - Screen 06 (downwind of Shell/CNRL);Flight 05 - Screen 07 (North of Suncor);Flight 06 - Screen 08 (downwind of Syncrude);"
		fltList = fltList + "Flight 06 - Screen 09 (downwind of Suncor);Flight 07 - Screen 10 (West screen);Flight 07 - Screen 11 (centre screen);Flight 07 - Screen 12 (East screen);Flight 14 - Screen 13 (centre of Suncor);"
		fltList = fltList + "Flight 19 - Screen 14 (first screen);Flight 19 - Screen 15 (second screen);Flight 19 - Screen 16 (third screen);Flight 19 - Screen 17 (fourth screen);Flight 19 - Screen 18 (fifth screen);"
		fltList = fltList + "Flight 20 - Screen 19 (West screen);Flight 20 - Screen 20 (centre screen);Flight 20 - Screen 21 (East screen)"
		String/G fltCode = ""
	else
		String/G fltList = "Flight 01 - Screen 1A (north of Syncrude);Flight 01 - Screen 1B (north of Suncor and Firebag);Flight 01 - Screen 2 (north of OS);Flight 02 - Screen 1;Flight 02 - Screen 2;Flight 02 - Screen 3;Flight 02 - Screen 4;"
		fltList = fltList + "Flight 03 - Screen 1;Flight 03 - Screen 2;Flight 03 - Screen 3;Flight 03 - Screen 4;Flight 05 - Screen 1;Flight 05 - Screen 2;Flight 05 - Screen 3;Flight 05 - Screen 4;"
		fltList = fltList + "Flight 06 - Screen 1 (north of Syncrude and Suncor);Flight 06 - Screen 2 (southwest of OS);Flight 14 - Screen 1;Flight 14 - Screen 2;Flight 14 - Screen 3;Flight 14 - Screen 4;"
		fltList = fltList + "Flight 20 - Screen 1 (east of Syncrude);Flight 20 - Screen 2;Flight 21 - Screen 1 (north of Suncor);Flight 22 - Screen 1;Flight 22 - Screen 2;Flight 22 - Screen 3;Flight 23 - Screen 1 (northwest of Syncrude);"
		fltList = fltList + "Flight 24 - Screen 1;Flight 24 - Screen 2;Flight 24 - Screen 3;Flight 25 - Screen 1;Flight 25 - Screen 2;Flight 25 - Screen 3;Flight 25 - Screen 4;Flight 26 - Screen 1;"
		fltList = fltList + "Flight 27 - Screen 1;Flight 27 - Screen 2;Flight 27 - Screen 3;Flight 29 - Screen 1;Flight 29 - Screen 2;Flight 29 - Screen 3;Flight 29 - Screen 4;Flight 30 - Screen 1;Flight 30 - Screen 2;Flight 30 - Screen 3"
		String/G fltCode = "F01_Screen1A;F01_Screen1B;F01_Screen2;F02_Screen1;F02_Screen2;F02_Screen3;F02_Screen4;F03_Screen1;F03_Screen2;F03_Screen3;F03_Screen4;F05_Screen1;F05_Screen2;F05_Screen3;F05_Screen4;"
		fltCode = fltCode + "F06_Screen1;F06_Screen2;F14_Screen1;F14_Screen2;F14_Screen3;F14_Screen4;F20_Screen1;F20_Screen2;F21_Screen;F22_Screen1;F22_Screen2;F22_Screen3;F23_Screen;"
		fltCode = fltCode + "F24_Screen1;F24_Screen2;F24_Screen3;F24_Screen4;F25_Screen1;F25_Screen2;F25_Screen3;F25_Screen4;F26_Screen1;F27_Screen;F27_Screen1;F27_Screen2;F29_Screen1;F29_Screen2;F29_Screen3;F29_Screen4"
		fltCode = fltCode + "F30_Screen1;F30_Screen2;F30_Screen3"
	endif
	
	//Prompt user for information
	NewPanel/N=Data /W=(700,158,1330,700)
	PopupMenu popupdt,pos={65,40},size={235,21},title="Choose date/time column: "
	PopupMenu popupdt,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dtNm
	PopupMenu popupdata,pos={65,80},size={211,21},title="Choose data column: "
	PopupMenu popupdata,mode=1,value= WaveList("*",";","TEXT:0"),popvalue=dataNm
	PopupMenu popupproj,pos={65,120},size={135,21},title="Choose project: "
	PopupMenu popupproj,mode=1,value="2013;2018",proc=PopupProjScreen,popvalue=projNm
	PopupMenu popupflt,pos={65,160},size={135,21},title="Choose flight: "
	PopupMenu popupflt,mode=1,value= #"fltList",popvalue=fltName
	SetVariable setvarsmp,pos={65,200},size={200,16},title="Enter sampling interval (in s): "
	SetVariable setvarsmp,limits={1,inf,1},value= smpInt, proc=SetVarSampInt
	PopupMenu popupfill,disable=1,pos={500,240},size={47,21}
	PopupMenu popupfill,mode=1,value= "NaN;Value",popvalue=betwPts
	if (smpInt > 1)
		PopupMenu popupfill,disable=0
		SetDrawLayer UserBack
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,245,"Between the points recorded by the instrument, do you want to insert NaNs or assume "
		SetDrawEnv fname= "MS Sans Serif"
		DrawText 65,260,"that the instrument read value continues to be valid until the subsequent reading? "
	endif
	PopupMenu popuptype,pos={65,280},size={240,12},mode=1,value="Gas;Particles",proc=PopupGP,title="What type of data is being loaded? ",popvalue=dataType	
	SetVariable setvarmass,pos={65,320},size={300,16},title="Enter the molar mass of the quantity (g/mol): "
	SetVariable setvarmass,limits={0,inf,1},value= Mc
	SetVariable setvarbg,pos={65,360},size={350,16},title="Enter the background value (enter 0 if this is unknown): ",limits={0,inf,1},value=background
	PopupMenu popupunit,mode=1,pos={65,400},size={300,16},title="What units are your data in? ", value=#"unitlist",popvalue=unitStr
	PopupMenu popuploc,pos={65,440},mode=1,size={300,16},title="Where do you want to load weights from?", value="Online;Local",popvalue=location
	Button buttonOK,pos={100,490},size={50,20},proc=ButtonPanOK,title="OK"
	Button buttonCanc,pos={435,490},size={50,20},proc=ButtonPanCanc,title="Cancel"
	PauseForUser Data
	
	Wave dt = $dtNm
	Wave data = $dataNm
	
	//If the sampling interval is not 1 then run the function to create a 1 second time series for that data
	if (smpInt < 1)
		Abort "Sampling interval is too small."
	elseif (smpInt > 1)		
		if (CmpStr(betwPts, "Value") == 0)
			createNewTimeSeries(dtNm, dataNm, smpInt)
			Wave dt = dt1sec
			Wave data = data1sec
		endif
	endif	
	
	String flightNumber, format, desc
	
	//2013 Campaign
	if (CmpStr(projNm,"2013") == 0)			
		format = "%s %s %s %s %s"
		sscanf fltName, format, flight, fltNum, dash, screen, screenNum
		
		flightNumber = "Flight" + num2str(str2num(fltNum))
	
		//Load in the premade Igor binary files
		String fileFold = "F" + fltNum + "_Screen"
		fileSuf = "Screen" + screenNum
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + fileFold + ":WindDir_" + fileSuf + ".ibw")
		
	//2018 Campaign
	elseif (CmpStr(projNm,"2018") == 0)
		ControlInfo popupflt
		filePre = StringFromList(V_value,fltCode)
		fileSuf = filePre
		
		format = "%3s_%s"
		sscanf filePre, format, fltNum, desc		
		flightNumber = fltNum
		
		//Load in the premade Igor binary files
		LoadWave/H/O/Q/P=OS (":" + filePre + ":timestamp_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Frame_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindEf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenWindNf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirf_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenAirFlux_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_deg_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosXY_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":ScreenPosZ_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":PositionSZA_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":varValues_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":fltGridPts_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirF_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":totalAirFM_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticT_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":StaticP_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":massInfo_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lat_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Lon_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":Alt_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":DewPoint_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindSpeed_" + fileSuf + ".ibw")
		LoadWave/H/O/Q/P=OS (":" + filePre + ":WindDir_" + fileSuf + ".ibw")
		LoadData/O/Q/P=OS (":" + filePre + ":weights_" + fileSuf + ".pxp")
	endif	
	
	//Move ScreenFlux to ScreenAirFlux
	Wave ScreenFlux
	Duplicate/O ScreenFlux, ScreenAirFlux
	KillWaves/Z ScreenFlux
//	PT_FlightTimes()
	
	//Load varValues values into the appropriate variables
	Wave varValues
	Variable/G ns = varValues[0]
	Variable/G nz = varValues[1] 
	Variable/G ds = varValues[2]
	Variable/G dz = varValues[3]
	Variable/G index = floor(ns/ds) 
	Variable/G indmax = floor(ns/ds)
	
	//Create the PositionSZC wave (consists of position and concentration during the flight)
	createConcWv (dt, data)
	Wave PositionSZC
	
	//If there are no points then the times did not match up and the wrong flight has been chosen
	Duplicate/O/R=(0,dimSize(PositionSZC,0))(2,2) PositionSZC, quantTemp
	WaveStats/Q quantTemp
	if (V_npnts == 0)
		Abort "You have selected the wrong flight number"
	endif
	KillWaves/Z quantTemp
	
	//Create link to flight path for PanelEmissions
	Wave timestamp
	String dateSt = date2str(timestamp[0])
	format = "%4s-%2s-%2s"
	sscanf dateSt, format, year, month, day
	String/G flightPathLoc
	
	if (CmpStr(projNm, "2013") == 0)
		if (CmpStr(month, "08") == 0)
			month = "Aug"
		else
			month = "Sep"
		endif
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM\\Level_0_RAW\\AIRCRAFT\\Plots\\OS2013_" + month + day + "_" + flightNumber + "_Map.jpg"
	elseif (CmpStr(projNm, "2018") == 0)
		flightPathLoc = "\\\\econm3hwvasp010.ncr.int.ec.gc.ca\\OSM_2018\\AIRCRAFT\\Metadata\\Maps\\" + flightNumber + "_FlightTrack.jpg"
	endif	
	
	//Create the variables with initial values and display the variogram of the data
	createVar()
	graphlist = WinList("VariogramPlot", ";", "")
	if (strlen(graphlist) > 0)
		KillWindow VariogramPlot
	endif	
	variogram(PositionSZC, 30)
	PauseForUser VariogramPlot

	//After variable values have been selected on the plot, run the kriging
	runFullKrigScreen()

	Wave intVal
	Wave fltGridPts
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
	Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
	Redimension/N=-1 xWv, yWv
	Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
	Wave ScreenKrig, ScreenWindEf, ScreenWindNf, ScreenAirf
	
	//If there is an extra line, delete it
	if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
		DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
	endif
	
	UnfillAboveData()
	Unfill()												//Unfill the screen above and below the flight path
	Wave ScreenU
	SVAR unitStr
	
	if (CmpStr(unitStr, "ug/m^3") == 0)	
		Duplicate/O PositionSZC, PositionSZC_oldUnits
		Duplicate/O ScreenU, ScreenU_ugm3
		convertP_Units()
		runInterpNoPrompt()
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(0,0) fltGridPts, xWv 
		Duplicate/O/R=(0, dimSize(fltGridPts,0))(1,1) fltGridPts, yWv 
		Redimension/N=-1 xWv, yWv
		Grid2Matrix(xWv,"ScreenKrig",yWv,2,intVal,0)
		if (dimSize(ScreenAirf,0) < dimSize(ScreenKrig,0))
			DeletePoints dimSize(ScreenAirf,0), (dimSize(ScreenKrig,0) - dimSize(ScreenAirf,0)), ScreenKrig
		endif
		UnfillAboveData()
		Unfill()
		Duplicate/O ScreenU, ScreenU_ppb
		Duplicate/O ScreenU_ugm3, ScreenU
	endif
	
	KillWaves/Z weights, weightsLoc
	
	Variable num = dimSize(ScreenKrig,0)
	
	Wave ScreenPosZ
	
	if (CmpStr(projNm,"2018") == 0)			//2018 campaign
	
		ProfilesOther()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp(height)									//Calculate the exponential fits
		ResetProfiles()										//Go to the previous point	
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		Fill()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface
		
	else

		ProfilesOther_2013()										//Calculate the profiles to the ground for zero, constant and line between background and constant
		ProfilesLine_2013(height)									//Calculate the linear fits
		Make/o/n=(80) Profile_pnts_z, Profile_pnts_C
		Make/o/n=1100 fit_Profile_pnts_C
		ProfilesExp_2013(height)									//Calculate the exponential fits
		ResetProfiles_2013()										//Go to the previous point	
		Execute "GraphProfiles()"								//Display the plot to show profile fits
		DoWindow/C GraphProfiles1
		createRatios("GraphProfiles1")
		Wave widRatio, heiRatio, vPosRatio, hPosRatio
		Duplicate/O widRatio, GraphProfiles1_sR
		Duplicate/O heiRatio, GraphProfiles1_zR
		Duplicate/O hPosRatio, GraphProfiles1_hR
		Duplicate/O vPosRatio, GraphProfiles1_vR
		
		FillAboveData()
		Fill_2013()													//Fill the screen to the ground
		CompareBaselines()									//Calculate the value of each fit at the surface
		
	endif	
	
	Make/D/O/N=(floor(ns/ds)) UserBase = NaN
	SetScale/P x 0,40,"", UserBase
	Make/T/O/N=(floor(ns/ds)) Fit_Flag = ""
	Execute "GraphSurfaceScreen()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	createRatios("GraphSurface1")
	Wave widRatio, heiRatio, vPosRatio, hPosRatio
	Duplicate/O widRatio, GraphSurface1_sR
	Duplicate/O heiRatio, GraphSurface1_zR
	Duplicate/O hPosRatio, GraphSurface1_hR
	Duplicate/O vPosRatio, GraphSurface1_vR
	Execute "PanelEmissionsScreen()"
	
End

Function DoneProfScreen(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave/T Fit_Flag
	NVAR nz, bg, totLat, totTop, Mc, units, ds, dz, height
	SVAR unitStr, projNm
	Wave totalAirF
	String wlist
	
	Variable num = dimSize(Fit_Flag,0)
	Variable i
	switch( ba.eventCode )
		case 2: // mouse up
			if (CmpStr(projNm,"2018") == 0)							//2018 campaign
				for (i = 0; i < num; i += 1)
					if (strlen(Fit_Flag[i]) == 0)
						Fit_Flag[i] = "C"
					endif
				endfor
				FillFinal()
				Wave ScreenF
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ppb
					Duplicate/O ScreenU_ppb, ScreenU
					Duplicate/O ScreenF, ScreenF_ugm3
					TopValue()
					wlist = WinList("GraphProfiles1", ";", "")
					if (strlen(wlist) > 0)
						KillWindow GraphProfiles1
					endif
					ProfilesLine (height)
					ProfilesExp (height)
					FillFinal()
					Duplicate/O ScreenF, ScreenF_ppb
				endif
				Wave ScreenWindEf, ScreenWindNf, ScreenF
				FluxCalcScreen(0,0,ds*dimSize(ScreenWindNf,0),dz*dimSize(ScreenWindNf,1), ScreenF)
				Wave ScreenPosZ
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ugm3
					Duplicate/O ScreenU_ugm3, ScreenU
					Duplicate/O ScreenF_ugm3, ScreenF
					ProfilesLine (height)
					ProfilesExp (height)
					Execute "GraphProfiles()"
					DoWindow/C GraphProfiles1
				endif
			else															//2013 campaign
				for (i = 0; i < num; i += 1)
					if (strlen(Fit_Flag[i]) == 0)
						Fit_Flag[i] = "C"
					endif
				endfor
				FillFinal_2013()
				Wave ScreenF
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ppb
					Duplicate/O ScreenU_ppb, ScreenU
					Duplicate/O ScreenF, ScreenF_ugm3
					TopValue()
					wlist = WinList("GraphProfiles1", ";", "")
					if (strlen(wlist) > 0)
						KillWindow GraphProfiles1
					endif
					ProfilesLine_2013 (height)
					ProfilesExp_2013 (height)
					FillFinal_2013()
					Duplicate/O ScreenF, ScreenF_ppb
				endif
				Wave ScreenWindEf, ScreenWindNf, ScreenF
				FluxCalcScreen_2013(0,0,ds*dimSize(ScreenWindNf,0),dz*dimSize(ScreenWindNf,1), ScreenF)
				Wave ScreenPosZ
				if (CmpStr(unitStr, "ug/m^3") == 0)	
					Wave ScreenU_ugm3
					Duplicate/O ScreenU_ugm3, ScreenU
					Duplicate/O ScreenF_ugm3, ScreenF
					ProfilesLine_2013 (height)
					ProfilesExp_2013 (height)
					Execute "GraphProfiles()"
					DoWindow/C GraphProfiles1
				endif
			endif
			
			Wave ScreenPosZ
			Display /W=(344.25,66.5,1115.25,560.75) ScreenPosZ[*]
			AppendImage/T ScreenF
			SetAxis/A left
			ModifyImage ScreenF ctab= {*,*,Rainbow,1}
			ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2
			ModifyGraph rgb(ScreenPosZ)=(43520,43520,43520)
			ModifyGraph margin(right)=50
			SetAxis left 0, nz
			ColorScale/C/N=text0/F=0/M/A=RT/X=-6.98/Y=13.86 image=ScreenF, logLTrip=0.0001
			ColorScale/C/N=text0 lowTrip=0.1
			ModifyGraph noLabel(top)=2
			Label bottom "s (m)"
			Label left "Altitude"
			ModifyGraph tick(top)=3		
			SetDrawLayer/W=PanelEmissionsScreen/K UserBack
			DrawText/W=PanelEmissionsScreen 27,318,num2str(totalAirF[0]*3600)
			DrawText/W=PanelEmissionsScreen 297,318,num2str(Mc/28.97)
			DrawText/W=PanelEmissionsScreen 370,318,num2str(abs(totLat))
			DrawText/W=PanelEmissionsScreen 537,318,num2str(abs(totLat))
			
			recordHistory()
//			killSurplusWaves ()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function reloadGraphsScreen ()
	Variable i
	SVAR projNm
	
	if (exists("ScreenPosZ") == 0)
		Abort "Kriging must be run before plots can be loaded. "
	endif
	
	Execute "GraphProfiles()"								//Display the plot to show profile fits
	DoWindow/C GraphProfiles1
	if (CmpStr(projNm,"2018") == 0)
		ResetProfiles()										//Go to the previous point
	else
		ResetProfiles_2013()
	endif

	Execute "GraphSurfaceScreen()"								//Display the plot to show the screen and surface values
	DoWindow/C GraphSurface1
	Execute "PanelEmissionsScreen()"

End

Function GetScreen()
	NVAR ds, dz
	SVAR unitStr
	Variable sSt, sEnd, zSt, zEnd
	String ilist
	Variable ind1, ind2
	
	SetDrawLayer/K UserFront
	GetMarquee/Z left, bottom
	if (strlen(S_marqueeWin) > 0)
		ilist = ImageNameList(S_marqueeWin, ";")
	else
		ilist = ImageNameList("", ";")
	endif
	String image = StringFromList(0, ilist)
	
	if (CmpStr(unitStr, "ug/m^3") == 0)
		if (CmpStr(image, "ScreenU") == 0)
			Wave screen = ScreenU_ppb
		else
			Wave screen = ScreenF_ppb
		endif
	else
		if (CmpStr(image, "ScreenU") == 0)
			Wave screen = ScreenU
		else
			Wave screen = ScreenF
		endif
	endif
	
	if (V_flag != 0)	
		print " "
		print "s goes from", V_left, "to", V_right, " and z goes from", V_bottom, "to", V_top	
		GetCoords(screen)
		Wave latscreen, lonscreen
		ind1 = round(V_left/40)
		ind2 = round(V_right/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		FluxCalcAir(V_left, V_bottom, V_right, V_top)
		FluxCalcScreen(V_left, V_bottom, V_right, V_top, screen)
	
		SetDrawLayer UserFront								//Draw box around data
		SetDrawEnv xcoord= bottom,ycoord= left			
		SetDrawEnv	fillpat = 0, linethick = 2
		DrawRect round(V_left/ds)*ds, round(V_bottom/dz)*dz, round(V_right/ds)*ds, round(V_top/dz)*dz	
	else
		Prompt sSt, "Enter starting s value: "
		Prompt sEnd, "Enter ending s value: "
		Prompt zSt, "Enter starting z value: "
		Prompt zEnd, "Enter ending z value: "
		DoPrompt "Box Coordinates", sSt, sEnd, zSt, zEnd
		
		if (V_flag)
			Abort
		endif
		
		print " "
		print "s goes from", sSt, "to", sEnd, " and z goes from", zSt, "to", zEnd
		GetCoords(screen)
		Wave latscreen, lonscreen
		ind1 = round(sSt/40)
		ind2 = round(sEnd/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		FluxCalcAir(sSt, zSt, sEnd, zEnd)
		FluxCalcScreen(sSt, zSt, sEnd, zEnd, screen)
	
		SetDrawLayer UserFront								//Draw box around data
		SetDrawEnv xcoord= bottom,ycoord= left			
		SetDrawEnv	fillpat = 0, linethick = 2
		DrawRect round(sSt/ds)*ds, round(zSt/dz)*dz, round(sEnd/ds)*ds, round(zEnd/dz)*dz
	endif	
	
End

Function averageScreen()
	String ilist, image
	SVAR unitStr
	NVAR ds, dz
	Variable sSt, sEnd, zSt, zEnd
	Variable ind1, ind2
	
	SetDrawLayer/K UserFront
	GetMarquee/Z left, bottom
	if (strlen(S_marqueeWin) > 0)
		ilist = ImageNameList(S_marqueeWin, ";")
	else
		ilist = ImageNameList("", ";")
	endif
	image = StringFromList(0, ilist)
	Wave screen = $image

	if (V_flag != 0)
		print " "		
		print "s goes from", V_left, "to", V_right, " and z goes from", V_bottom, "to", V_top
		GetCoords(screen)
		Wave latscreen, lonscreen
		ind1 = round(V_left/40)
		ind2 = round(V_right/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		AvgCalcScreen(V_left, V_bottom, V_right, V_top, screen)
	
		SetDrawLayer UserFront								//Draw box around data
		SetDrawEnv xcoord= bottom,ycoord= left			
		SetDrawEnv	fillpat = 0, linethick = 2
		DrawRect round(V_left/ds)*ds, round(V_bottom/dz)*dz, round(V_right/ds)*ds, round(V_top/dz)*dz	
	else
		Prompt sSt, "Enter starting s value: "
		Prompt sEnd, "Enter ending s value: "
		Prompt zSt, "Enter starting z value: "
		Prompt zEnd, "Enter ending z value: "
		DoPrompt "Box Coordinates", sSt, sEnd, zSt, zEnd
		
		if (V_flag)
			Abort
		endif
	
		print " "
		print "s goes from", sSt, "to", sEnd, " and z goes from", zSt, "to", zEnd
		GetCoords(screen)
		Wave latscreen, lonscreen
		ind1 = round(sSt/40)
		ind2 = round(sEnd/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		AvgCalcScreen(sSt, zSt, sEnd, zEnd, screen)
		
		SetDrawLayer UserFront								//Draw box around data
		SetDrawEnv xcoord= bottom,ycoord= left			
		SetDrawEnv	fillpat = 0, linethick = 2
		DrawRect round(sSt/ds)*ds, round(zSt/dz)*dz, round(sEnd/ds)*ds, round(zEnd/dz)*dz
	endif	

End

Function GetCoords(screen)
	Wave screen
	Wave ScreenPosXY_deg
	NVAR ds, dz
	Variable i
	Variable count = 0
	
	Variable num = dimSize(screen,0)
	Variable num2 = dimSize(screen,1)
	Make/O/N=(num) latscreen, lonscreen
	
	Variable stpt = dimoffset(screen,0)
	
	Variable stindex = 0
	for (i = 1; i < num - 1; i += 1)
		if (stpt > ds*i)
			stindex = stindex + 1
		endif
	endfor
	
	for (i = stindex; i < num; i += 1)
		if (dimSize(ScreenPosXY_deg,0) < i*ds/2)
			break
		endif
		latscreen[count] = ScreenPosXY_deg[i*ds][1]
		lonscreen[count] = ScreenPosXY_deg[i*ds][0]
		count = count + 1
	endfor
	
End
	

Function FluxCalcScreen(sst, zst, send, zend, ScreenWv)
	variable sst, zst, send, zend
	Wave ScreenWv
	variable/g ds, dz
	variable w, s, nsi, z, nzi, nz, ns
	variable ux, uy, vx, vy, ws, zsur
	Variable Total,avg, rms, TotalU, totalOut, totalIn, totalOutU, totalInU
	wave ScreenWindNf, ScreenWindEf, ScreenAirf
	wave ScreenPosXY, ScreenPosZ
	NVAR bg, Mc, units
	SVAR unitStr
	
//	if (CmpStr(unitStr, "ug/m^3") == 0)
//		Wave ScreenU = ScreenU_ppb
//	else
//		Wave ScreenU = ScreenU
//	endif

	if (exists("ScreenU_ppb_original") == 1)
		Wave ScreenU = ScreenU_ppb_original
	elseif (exists("ScreenU_original") == 1)
		Wave ScreenU = ScreenU_original
	else
		if (CmpStr(unitStr, "ug/m^3") == 0)
			Wave ScreenU = ScreenU_ppb
		else
			Wave ScreenU = ScreenU
		endif
	endif

//	nsi = dimsize(ScreenWindNf,0)
//	nzi = dimsize(ScreenWindNf,1)
	nsi = round(send/ds)
	nzi = round(zend/dz)
	ns = round(sst/ds)
	nz = round(zst/dz)
	
	if (nsi > dimSize(ScreenWv,0))
		nsi = dimSize(ScreenWv,0)
	endif
	
	if (nzi > dimSize(ScreenWv,1))
		nzi = dimSize(ScreenWv,1)
	endif
	
	if (nz < 0 || nzi < 0)
		Abort "You must select an area on the screen."
	endif
    
	Total = 0
	TotalU = 0
	totalOut = 0
	totalIn = 0
	totalOutU = 0
	totalInU = 0

	make/o/n=(nsi,nzi) ScreenFlux, ScreenFluxU
	make/o/n=(nsi) ScreenFlux_s, ScreenFlux_sU
	make/o/n=(nzi) ScreenFlux_z, ScreenFlux_zc, ScreenFlux_zU, ScreenFlux_zcU
	setscale/p x, 0, ds, ScreenFlux, ScreenFlux_s, ScreenFluxU, ScreenFlux_sU
	setscale/p y, 0, dz, ScreenFlux, ScreenFluxU
	setscale/p x, 0, ds, ScreenFlux_z, ScreenFlux_zU
	ScreenFlux_s = 0
	ScreenFlux_z = 0
	ScreenFlux_zc = 0
	ScreenFlux_sU = 0
	ScreenFlux_zU = 0
	ScreenFlux_zcU = 0	

	for (s=ns; s<nsi - 1; s+=1)
		zsur = ScreenPosZ[s*ds]/dz
		for (z=nz; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if (s==0)
				ux = (ScreenPosXY[5][0] - ScreenPosXY[0][0]) // Lon Difference 
				uy = (ScreenPosXY[5][1] - ScreenPosXY[0][1]) // Lat Difference
			elseif (s == nsi-1)
				ux = (ScreenPosXY[nsi*ds][0] - ScreenPosXY[nsi*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[nsi*ds][1] - ScreenPosXY[nsi*ds-5][1]) // Lat Difference			
			else
				ux = (ScreenPosXY[s*ds+5][0] - ScreenPosXY[s*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s*ds+5][1] - ScreenPosXY[s*ds-5][1]) // Lat Difference
			endif
			vx = ScreenWindEf[s][z]/ws  // East Wind
			vy = ScreenWindNf[s][z]/ws  // North Wind
			ScreenFlux[s][z] = (ux*vy - uy*vx)/sqrt(ux*ux+uy*uy) // normal vector
			ScreenFlux[s][z] *= Mc/28.97*10^(units)*(ScreenWv[s][z]) // parts/parts
			ScreenFlux[s][z] *= ScreenAirf[s][z]                  // kg/m3
			ScreenFlux[s][z] *= ws                                // kg/m2/s
			
			if (numtype(ScreenFlux[s][z])==0)
				ScreenFlux_s[s] += ScreenFlux[s][z]
				if (z > zsur)
					ScreenFlux_z[floor(z-zsur)] += ScreenFlux[s][z]
					ScreenFlux_zc[floor(z-zsur)] += 1
					Total += (ScreenFlux[s][z]*ds*dz) // kg/s
					if (ScreenFlux[s][z] < 0)
						totalOut += ScreenFlux[s][z]*ds*dz
					else
						totalIn += ScreenFlux[s][z]*ds*dz
					endif
				endif
			endif
			
			//Repeat for unfilled screen
			if (z < dimSize(ScreenU,1))
				ScreenFluxU[s][z] = (ux*vy - uy*vx)/sqrt(ux*ux+uy*uy)
				ScreenFluxU[s][z] *= Mc/28.97*10^(units)*(ScreenU[s][z])
				ScreenFluxU[s][z] *= ScreenAirf[s][z] 
				ScreenFluxU[s][z] *= ws  
			
				if (numtype(ScreenFluxU[s][z])==0)
					ScreenFlux_sU[s] += ScreenFluxU[s][z]
					if (z > zsur)
						ScreenFlux_zU[floor(z-zsur)] += ScreenFluxU[s][z]
						ScreenFlux_zcU[floor(z-zsur)] += 1
						TotalU += (ScreenFluxU[s][z]*ds*dz) // kg/s
						if (ScreenFluxU[s][z] < 0)
							totalOutU += ScreenFluxU[s][z]*ds*dz
						else
							totalInU += ScreenFluxU[s][z]*ds*dz
						endif
					endif
				endif
			endif
		endfor
	endfor

	ScreenFlux_s *= (dz*3600) // kg/m/Hr
	ScreenFlux_z *= (ds*3600)*abs(ScreenFlux_zc)/ScreenFlux_zc // kg/m/Hr
	
	ScreenFlux_sU *= (dz*3600) // kg/m/Hr
	ScreenFlux_zU *= (ds*3600)*abs(ScreenFlux_zcU)/ScreenFlux_zcU // kg/m/Hr
	
	NVAR totLat
	totLat = Total*3600		//kg/Hr
//	totTop = bg*10^(units)*(-totalAirF[0])*Mc/28.97*3600		//kg/Hr
	Variable totalInUP = totalInU/totalIn*100
	Variable totalOutUP = totalOutU/totalOut*100

	print " "
	print "~", round(1000 - totalInUP*10)/10, "% of matter entering does so through the extrapolated area outside the flight path, ~", round(1000 - totalOutUP*10)/10, "% of matter leaving does so through the extrapolated area outside the flight path."
	print "Total lateral emission rate is ", abs(totLat), "kg/Hr ", abs(totLat*24/1000), "T/d"
  
	ScreenFlux *= 10^(units) 
	ScreenFluxU *= 10^(units)
  
End 


Function AvgCalcScreen(sst, zst, send, zend, ScreenWv)
	Variable sst, zst, send, zend
	Wave ScreenWv
	Variable nsi, nzi, ns, nz
	Variable s, z
	Variable cSum = 0
	Variable nmPts = 0
	Variable cAvg = 0
	SVAR unitStr
	NVAR ds, dz

	nsi = round(send/ds)
	nzi = round(zend/dz)
	ns = round(sst/ds)
	nz = round(zst/dz)
	
	if (nsi > dimSize(ScreenWv,0))
		nsi = dimSize(ScreenWv,0)
	endif
	
	if (nzi > dimSize(ScreenWv,1))
		nzi = dimSize(ScreenWv,1)
	endif
	
	for (s = ns; s < nsi - 1; s += 1)
		for (z = nz; z < nzi - 1; z += 1)
			if (numtype(ScreenWv[s][z]) == 0)
				cSum = cSum + ScreenWv[s][z]
				nmPts = nmPts + 1
			endif
		endfor
	endfor
	
	cAvg = cSum/nmPts
	Print "Average concentration is", cAvg, unitStr

End

Function DispScreensScreen(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			String graphlist = WinList("Screens1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow Screens1
			endif
			Execute "ScreensScreen()"
			DoWindow/C Screens1
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End  


Window GraphSurfaceScreen() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(511.5,43.25,1407.75,714.5) PositionSZC[*][1] vs PositionSZC[*][0]
	AppendToGraph ScreenPosZ
	AppendToGraph/L=l1 Base[*][0],Base[*][1],Base[*][2],Base[*][3],Base[*][4]
	AppendToGraph/L=l2 UserBase
	AppendToGraph currLeft[*][1] vs currLeft[*][0]
	AppendToGraph currRight[*][1] vs currRight[*][0]
	AppendToGraph currTop[*][1] vs currTop[*][0]
	AppendToGraph currBot[*][1] vs currBot[*][0]
	AppendImage/T ScreenU
	ModifyImage ScreenU ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=30,margin(bottom)=30,margin(top)=30,margin(right)=50
	ModifyGraph mode(PositionSZC)=2,mode(ScreenPosZ)=7,mode(Base#2)=4
	ModifyGraph lSize(PositionSZC)=2,lSize(Base)=1.2,lSize(Base#1)=1.2
	ModifyGraph lSize(Base#3)=1.2,lSize(Base#4)=1.2
	ModifyGraph rgb(PositionSZC)=(0,0,0),rgb(ScreenPosZ)=(26112,26112,26112)
	ModifyGraph rgb(Base)=(0,0,0),rgb(Base#1)=(0,52224,0),rgb(Base#3)=(44032,29440,58880)
	ModifyGraph rgb(Base#4)=(39168,39168,0),rgb(UserBase)=(0,0,0)
	ModifyGraph msize(Base#2)=2
	ModifyGraph hbFill(ScreenPosZ)=2
	ModifyGraph mirror(left)=2,mirror(bottom)=0,mirror(l1)=2,mirror(l2)=2
	ModifyGraph mirror(top)=0
	ModifyGraph nticks(left)=2,nticks(bottom)=18,nticks(l1)=2,nticks(l2)=2
	ModifyGraph nticks(top)=18
	ModifyGraph minor=1
	ModifyGraph fSize=8
	ModifyGraph lblMargin(bottom)=6,lblMargin(top)=12
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=25,lblPos(l1)=25,lblPos(l2)=25
	ModifyGraph lblLatPos(bottom)=-1,lblLatPos(l1)=9,lblLatPos(top)=412
	ModifyGraph tkLblRot(left)=90,tkLblRot(l1)=90,tkLblRot(l2)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	ModifyGraph freePos(l1)={0,kwFraction}
	ModifyGraph freePos(l2)={0,kwFraction}
	ModifyGraph axisEnab(left)={0.55,1}
	ModifyGraph axisEnab(l1)={0,0.3}
	ModifyGraph axisEnab(l2)={0.325,0.525}
	Label left "\\Z10Altitude (m)"
	Label bottom "\\Z10\\f02s\\f00 [m]"
	Label l1 "\\Z10Surface Value"
	SetAxis left 0,nz
	SetAxis l1 -10,50
	Cursor/P/S=1/C=(0,15872,65280) A Base 0;Cursor/P/S=1/C=(16384,16384,65280) B Base 100;Cursor/P/S=1/C=(65280,0,52224) C PositionSZC 0
	ShowInfo
	Legend/C/N=text0/J/X=9.06/Y=66.84 "\\F'times'\\Z12\r\\s(Base) Constant\r\\s(Base#1) Linear Fit\r\\s(Base#2) Exponential\r\\s(Base#3) Background"
	AppendText "\\s(Base#4) Linear Between Constant and Background"
	ColorScale/C/N=text1/F=0/M/A=RT/X=-5.79/Y=10.06 image=ScreenU, heightPct=40
	ColorScale/C/N=text1 width=10, fsize=10, logLTrip=0.0001, lowTrip=0.1
	ControlBar/R 100
	TitleBox title0,pos={1095,192},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title1,pos={1095,428},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title2,pos={1095,610},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	Button button0,pos={1102,28},size={90,50},proc=DispScreensScreen,title="Show Wind/\rAir Screens"
	Button button1,pos={1102,80},size={90,50},proc=PlotTS,title="Show Time\r Series"
	Button button2,pos={1102,132},size={90,50},proc=PlotVP,title="Show Vertical\r Profile"
	Button button3,pos={1102,212},size={90,50},proc=ResetAxis,title="Reset Axis"
	Button button4,pos={1102,264},size={90,50},proc=PrintTime,title="Print Values"
	Button button5,pos={1102,316},size={90,50},proc=SelEmis,title="Obtain Emission\rSelected Section"
	Button button6,pos={1102,368},size={90,50},proc=SelAvg,title="Obtain Average\rSelected Section"
	Button button7,pos={1102,448},size={90,50},proc=TopMix,title="Change Top \rMixing Ratio",disable=2
	Button button8,pos={1102,500},size={90,50},proc=changeBG,title="Change \rBackground"
	Button button9,pos={1102,552},size={90,50},proc=upExtrapScreen,title="Extrapolate\r Upward"
	Button button10,pos={1102,632},size={90,50},proc=SaveProf,title="Set Profiles"
	Button button11,pos={1102,684},size={90,50},proc=DoneProfScreen,title="Calculate \rEmission Rates"
	Button button12,pos={1102,835},size={90,50},proc=Help,title="Help"
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro



Window ScreensScreen() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(334.5,20,1180.5,690.5)/L=L1 ScreenPosZ
	AppendToGraph/L=L2 ScreenPosZ
	AppendToGraph/B=HorizCrossing ScreenPosZ
	AppendImage/T ScreenAirFlux
	ModifyImage ScreenAirFlux ctab= {*,*,Rainbow,1}
	AppendImage/T/L=L1 ScreenWindEf
	ModifyImage ScreenWindEf ctab= {*,*,Rainbow,1}
	AppendImage/T/L=L2 ScreenWindNf
	ModifyImage ScreenWindNf ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=50
	ModifyGraph mode(ScreenPosZ)=7,mode(ScreenPosZ#1)=7,mode(ScreenPosZ#2)=7
	ModifyGraph rgb(ScreenPosZ)=(34816,34816,34816),rgb(ScreenPosZ#1)=(34816,34816,34816)
	ModifyGraph rgb(ScreenPosZ#2)=(34816,34816,34816)
	ModifyGraph hbFill(ScreenPosZ)=2,hbFill(ScreenPosZ#1)=2,hbFill(ScreenPosZ#2)=2
	ModifyGraph tick(bottom)=3,tick(HorizCrossing)=3
	ModifyGraph mirror(L1)=2,mirror(bottom)=0,mirror(L2)=2,mirror(left)=2,mirror(top)=0
	ModifyGraph nticks(L1)=2,nticks(L2)=2,nticks(left)=2,nticks(top)=20
	ModifyGraph minor(L1)=1,minor(L2)=1,minor(left)=1,minor(top)=1
	ModifyGraph noLabel(bottom)=2,noLabel(HorizCrossing)=2
	ModifyGraph fSize(L1)=8,fSize(L2)=8,fSize(left)=8,fSize(top)=8
	ModifyGraph standoff(left)=0,standoff(top)=0
	ModifyGraph lblPos(bottom)=12,lblPos(left)=13,lblPos(HorizCrossing)=-540
	ModifyGraph lblLatPos(HorizCrossing)=6
	ModifyGraph tkLblRot(L1)=90,tkLblRot(L2)=90,tkLblRot(left)=90
	ModifyGraph btLen(L1)=3,btLen(L2)=3,btLen(left)=3,btLen(top)=3
	ModifyGraph tlOffset(L1)=-2,tlOffset(L2)=-2,tlOffset(left)=-2,tlOffset(top)=-2
	ModifyGraph freePos(L1)=1
	ModifyGraph freePos(L2)=0
	ModifyGraph freePos(HorizCrossing)=-27
	ModifyGraph tickZap(HorizCrossing)={0}
	ModifyGraph axisEnab(L1)={0.33,0.63}
	ModifyGraph axisEnab(L2)={0.66,0.96}
	ModifyGraph axisEnab(left)={0,0.3}
	SetAxis left 0,nz
	SetAxis L1 0,nz
	SetAxis L2 0,nz
	TextBox/C/N=text0/F=0/A=MC/X=3.26/Y=-19.23 "Air Flux Screen"
	TextBox/C/N=text1/F=0/A=MC/X=2.93/Y=47.32 "North Wind Screen"
	TextBox/C/N=text2/F=0/A=MC/X=3.02/Y=14.34 "East Wind Screen"
	ColorScale/C/N=text3/F=0/A=MC/X=53.64/Y=-35.31 image=ScreenAirFlux, heightPct=30
	ColorScale/C/N=text3 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "kg m\\S-2\\M s\\S-1\\M"
	ColorScale/C/N=text4/F=0/A=MC/X=53.26/Y=-2.21 image=ScreenWindEf, heightPct=30
	ColorScale/C/N=text4 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "m/s"
	ColorScale/C/N=text5/F=0/A=MC/X=53.35/Y=30.89 image=ScreenWindNf, heightPct=30
	ColorScale/C/N=text5 width=10, fsize=8, lblMargin=3, logLTrip=0.0001, lowTrip=0.1
	AppendText "m/s"
EndMacro

Window PanelEmissionsScreen() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(31,571,663,967)
	ModifyPanel cbRGB=(65534,65534,65534)
	SetDrawLayer ProgBack
	DrawRect 22,202,603,346
	DrawLine 105,202,105,346
	DrawLine 188,202,188,346
	DrawLine 271,202,271,346
	DrawLine 354,202,354,346
	DrawLine 437,202,437,346
	DrawLine 520,202,520,346
	DrawLine 22,274,603,274
	SetDrawEnv fsize= 20
	DrawText 45,247,"E\\Bair,H\\M"
	SetDrawEnv fsize= 20
	DrawText 131,247,"E\\Bair,V\\M"
	SetDrawEnv fsize= 20
	DrawText 212,247,"X\\BTop\\M"
	SetDrawEnv fsize= 20
	DrawText 295,247,"M\\BR\\M"
	SetDrawEnv fsize= 20
	DrawText 378,247,"E\\BC,H\\M"
	SetDrawEnv fsize= 20
	DrawText 459,247,"E\\BC,V\\M"
	SetDrawEnv fsize= 20
	DrawText 551,247,"E\\BC\\M"
	SetDrawEnv fsize= 20
	DrawText 165,35,"E\\BC\\M = E\\BC,H\\M + E\\BC,V\\M - E\\BC,M\\M"
	SetDrawEnv fsize= 20
	DrawText 116,109,"E\\Bair,H\\M + E\\Bair,V\\M - E\\Bair,M\\M = 0"
	SetDrawEnv fsize= 20
	DrawText 83,153,"E\\BC,V\\M = M\\BR\\MX\\BTop\\ME\\Bair,V\\M = -M\\BR\\MX\\BTop\\ME\\Bair,H\\M"
	SetDrawEnv fsize= 20
	DrawText 135,189,"E\\BC\\M = E\\BC,H\\M - M\\BR\\MX\\BTop\\ME\\Bair,H\\M"
	SetDrawEnv fsize= 16
	DrawText 35,29,"Mass Balance: "
	DrawText 71,53,"Total emission rate"
	DrawText 129,71,"Emission rate through box sides"
	DrawText 331,70,"Emission rate through box top"
	DrawText 398,51,"Change in mass within volume"
	SetDrawEnv fsize= 16
	DrawText 37,103,"Air Flux: "
	SetDrawEnv arrow= 1
	DrawLine 227,58,227,34
	SetDrawEnv arrow= 1
	DrawLine 136,38,159,25
	SetDrawEnv arrow= 2
	DrawLine 308,33,345,54
	SetDrawEnv arrow= 2
	DrawLine 370,28,395,39
	DrawText 451,169,"M\\BR\\M = Molar mass ratio"
	DrawText 449,150,"X\\BTop\\M = Mixing ratio at box top"
	DrawLine 329,33,363,7
	SetDrawEnv fsize= 10
	DrawText 366,12,"0"
	DrawLine 243,111,280,81
	SetDrawEnv fsize= 10
	DrawText 282,86,"0"
	SetDrawEnv fsize= 14
	DrawText 378,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 460,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 545,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 45,264,"(kg/hr)"
	SetDrawEnv fsize= 14
	DrawText 132,264,"(kg/hr)"
	SetDrawEnv fsize= 14
//	DrawText 220,264,("(" + unitStr + ")")
	DrawText 26,374,"For further details see algorithm in Gordon et al., 2015"
//	CustomControl link,pos={490,357},size={165,19},proc=FlightLink,title="Flight Path",frame=0,fStyle=4,fSize=14,valueColor=(0,0,65535)
	SetDrawLayer UserBack
//	DrawText 27,318,"NA"
//	DrawText 117,318,"NA"
	DrawText 27,318,num2str(totalAirF[0]*3600)
	DrawText 297,318,num2str(Mc/28.97)
	DrawText 370,318,num2str(totLat)
//	DrawText 450,318,"NA"
	DrawText 537,318,num2str(abs(totLat))

EndMacro

Window PlotProfiles() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(4.5,46.25,784.5,689)/VERT StaticT_Prof vs Height_Prof
	AppendToGraph/W=PlotProfiles/VERT/B=B1/L=L1 Conc_Prof vs Height_Prof
	AppendToGraph/W=PlotProfiles/VERT/B=B2/L=L2 StaticP_Prof vs Height_Prof
	AppendToGraph/W=PlotProfiles/VERT/B=B3/L=L3 DewPoint_Prof vs Height_Prof
	ModifyGraph/W=PlotProfiles gfSize=12
	ModifyGraph/W=PlotProfiles mode=2
	ModifyGraph/W=PlotProfiles lSize=2
	ModifyGraph/W=PlotProfiles rgb(StaticT_Prof)=(0,0,0),rgb(StaticP_Prof)=(0,0,0),rgb(DewPoint_Prof)=(0,0,0)
	ModifyGraph/W=PlotProfiles lblPos(left)=67,lblPos(bottom)=45,lblPos(B1)=40,lblPos(L1)=67,lblPos(B2)=40
	ModifyGraph/W=PlotProfiles lblPos(L2)=55,lblPos(B3)=45,lblPos(L3)=55
	ModifyGraph/W=PlotProfiles freePos(B1)={0.55,kwFraction}
	ModifyGraph/W=PlotProfiles freePos(L1)={0,kwFraction}
	ModifyGraph/W=PlotProfiles freePos(B2)={0.55,kwFraction}
	ModifyGraph/W=PlotProfiles freePos(L2)={0.55,kwFraction}
	ModifyGraph/W=PlotProfiles freePos(B3)={0,kwFraction}
	ModifyGraph/W=PlotProfiles freePos(L3)={0.55,kwFraction}
	ModifyGraph/W=PlotProfiles axisEnab(left)={0,0.45}
	ModifyGraph/W=PlotProfiles axisEnab(bottom)={0,0.45}
	ModifyGraph/W=PlotProfiles axisEnab(B1)={0,0.45}
	ModifyGraph/W=PlotProfiles axisEnab(L1)={0.55,1}
	ModifyGraph/W=PlotProfiles axisEnab(B2)={0.55,1}
	ModifyGraph/W=PlotProfiles axisEnab(L2)={0.55,1}
	ModifyGraph/W=PlotProfiles axisEnab(B3)={0.55,1}
	ModifyGraph/W=PlotProfiles axisEnab(L3)={0,0.45}
	Label/W=PlotProfiles left "Altitude (m)"
	Label/W=PlotProfiles bottom "Temperature (C)"
	Label/W=PlotProfiles B1 "Concentration"
	Label/W=PlotProfiles L1 "Altitude (m)"
	Label/W=PlotProfiles B2 "Pressure (mb)"
	Label/W=PlotProfiles L2 "Altitude (m)"
	Label/W=PlotProfiles B3 "Dew Point Temperature (C)"
	Label/W=PlotProfiles L3 "Altitude (m)"
	ControlBar/R/W=PlotProfiles 100
	Button button0,pos={950,279},size={80,50},proc=ChTime,title="Choose Time\rPeriod"
	Button button1,pos={950,342},size={80,50},proc=ChArea,title="Choose \rArea"
	Button button2,pos={950,404},size={80,50},proc=DoneArea,title="Area Selection\rComplete"
EndMacro

Window FlightTrack() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(799.5,47,1427.25,689.75) Lat vs Lon
	ModifyGraph gfSize=12
	Label left "Latitude"
	Label bottom "Longitude"
EndMacro
