#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "DateTimeConversions"
#include <XYZToMatrix>

//KRIGING FUNCTIONS

//Run the kriging process including the calculation of the weights (includes prompt for wave to krig)
Function runAll ()
	String posWvNm

	Prompt posWvNm, "Choose triplet wave to krig: ", popup, WaveList("*", ";", "")
	DoPrompt "Kriging", posWvNm
	
	if (V_flag)
		Abort
	endif
	
	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	print "Start: ", date2str(datetime)
	accountEndsQuant(positions_noNan)
	Wave positions = root:Position_wQuantEnds
	
	print "AccountEnds Complete: ", date2str(datetime)
	distMatrix(positions)
	
	print "Data Matices Complete: ", date2str(datetime)
	Wave covarwv = root:cov
	invertDist (covarwv)
	
	print "Covariance Matrix Inverted: ", date2str(datetime)
	makeGrid (positions)
	
	print "Grid Complete: ", date2str(datetime)
	Wave grid = root:fltGridPts
	dist2Est (positions, grid)
	
	print "Grid Covariance Vectors Complete: ", date2str(datetime)
	Wave K_inv = root:cov_inv
	Wave k = root:covEst
	Wave k_loc = root:covLoc
	calcWeights (K_inv, k, k_loc)
	
	print "Weight Calculation Complete: ", date2str(datetime)	
//	accountEndsQuant(positions)
	deleteEnds()
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
	//Create matrix
	Wave intVal = root:intVal
	Duplicate/O/R=[][0] grid, xWv
	Duplicate/O/R=[][1] grid, yWv
	String lastChar = posWvNm[strlen(posWvNm) - 1]
	if (CmpStr(lastChar, "E") == 0 || CmpStr(lastChar, "N") == 0)
		Grid2Matrix(xWv,"ScreenWind" + lastChar,yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenWind" + lastChar
	else
		Grid2Matrix(xWv,"ScreenKrig",yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenKrig"
	endif
	
	//Plot Screen
	Wave ScreenPosZ = root:ScreenPosZ
	WaveStats/Q ScreenImage
	Display/W=(30,53,860.25,558.5) positionsSt[][1] vs positionsSt[][0]
	ModifyGraph mode=3,marker=19,msize=2,zColor($NameOfWave(positionsSt))={$NameOfWave(positionsSt)[*][2],V_min,V_max,Rainbow,1}
	AppendImage ScreenImage
	ModifyImage $NameOfWave(ScreenImage) ctab= {*,*,Rainbow,1}
	AppendToGraph ScreenPosZ
	ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2,rgb(ScreenPosZ)=(39321,39321,39321)
	ColorScale/C/N=text0/A=MC/X=-45.31/Y=-34.77 image=$NameOfWave(ScreenImage), heightPct=30
	ColorScale/C/N=text0 width=15	
	
	print "All Done! ", date2str(datetime)
	
End

//Run the kriging process including the calculation of the weights (includes prompt for wave to krig)
Function runAllScreen ()
	String posWvNm

	Prompt posWvNm, "Choose triplet wave to krig: ", popup, WaveList("*", ";", "")
	DoPrompt "Kriging", posWvNm
	
	if (V_flag)
		Abort
	endif
	
	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	print "Start: ", date2str(datetime)
//	accountEndsQuant(positions_noNan)
	Wave positions = positions_noNan
	
//	print "AccountEnds Complete: ", date2str(datetime)
	distMatrix(positions)
	
	print "Data Matices Complete: ", date2str(datetime)
	Wave covariance = root:cov
	invertDist (covariance)
	
	print "Covariance Matrix Inverted: ", date2str(datetime)
	makeGridScreen (positions)
	
	print "Grid Complete: ", date2str(datetime)
	Wave grid = root:fltGridPts
	dist2Est (positions, grid)
	
	print "Grid Covariance Vectors Complete: ", date2str(datetime)
	Wave K_inv = root:cov_inv
	Wave k = root:covEst
	Wave k_loc = root:covLoc
	calcWeights (K_inv, k, k_loc)
	
	print "Weight Calculation Complete: ", date2str(datetime)	
//	accountEndsQuant(positions)
//	deleteEnds()
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
		//Create matrix
	Wave intVal = root:intVal
	Duplicate/O/R=[][0] grid, xWv
	Duplicate/O/R=[][1] grid, yWv
	String lastChar = posWvNm[strlen(posWvNm) - 1]
	if (CmpStr(lastChar, "E") == 0 || CmpStr(lastChar, "N") == 0)
		Grid2Matrix(xWv,"ScreenWind" + lastChar,yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenWind" + lastChar
	else
		Grid2Matrix(xWv,"ScreenKrig",yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenKrig"
	endif
	
	//Plot Screen
	Wave ScreenPosZ = root:ScreenPosZ
	WaveStats/Q ScreenImage
	Display/W=(30,53,860.25,558.5) positionsSt[][1] vs positionsSt[][0]
	ModifyGraph mode=3,marker=19,msize=2,zColor($NameOfWave(positionsSt))={$NameOfWave(positionsSt)[*][2],V_min,V_max,Rainbow,1}
	AppendImage ScreenImage
	ModifyImage $NameOfWave(ScreenImage) ctab= {*,*,Rainbow,1}
	AppendToGraph ScreenPosZ
	ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2,rgb(ScreenPosZ)=(39321,39321,39321)
	ColorScale/C/N=text0/A=MC/X=-45.31/Y=-34.77 image=$NameOfWave(ScreenImage), heightPct=30
	ColorScale/C/N=text0 width=15	
	
	print "All Done! ", date2str(datetime)
	
End


//Run the kriging process using precalculated weights (includes prompt for wave to krig)
Function runInterp ()
	String posWvNm = "PositionSZA"

	Prompt posWvNm, "Choose triplet wave to interpolate: ", popup, WaveList("*", ";", "")
	DoPrompt "Interpolation", posWvNm
	
	if (V_flag)
		Abort
	endif
	
	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	print "Start: ", date2str(datetime)
	accountEndsQuant(positions_noNan)
	Wave positions = root:Position_wQuantEnds
	
	print "AccountEnds Complete: ", date2str(datetime)
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
	print "All Done! ", date2str(datetime)
	
	//Create matrix
	Wave intVal = root:intVal
	Wave grid = root:fltGridPts
	Duplicate/O/R=[][0] grid, xWv
	Duplicate/O/R=[][1] grid, yWv
	String lastChar = posWvNm[strlen(posWvNm) - 1]
	if (CmpStr(lastChar, "E") == 0 || CmpStr(lastChar, "N") == 0)
		Grid2Matrix(xWv,"ScreenWind" + lastChar,yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenWind" + lastChar
	else
		Grid2Matrix(xWv,"ScreenKrig",yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenKrig"
		
		Display positionsSt[][2] vs positionsSt[][1]
		CurveFit/M=2/W=0 line, positionsSt[*][2]/X=positionsSt[*][1]/D
	endif
	
	//Plot Screen
	Wave ScreenPosZ = root:ScreenPosZ
	WaveStats/Q ScreenImage
	Display/W=(30,53,860.25,558.5) positionsSt[][1] vs positionsSt[][0]
	ModifyGraph mode=3,marker=19,msize=2,zColor($NameOfWave(positionsSt))={$NameOfWave(positionsSt)[*][2],V_min,V_max,Rainbow,1}
	AppendImage ScreenImage
	ModifyImage $NameOfWave(ScreenImage) ctab= {*,*,Rainbow,1}
	AppendToGraph ScreenPosZ
	ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2,rgb(ScreenPosZ)=(39321,39321,39321)
	ColorScale/C/N=text0/A=MC/X=-45.31/Y=-34.77 image=$NameOfWave(ScreenImage), heightPct=30
	ColorScale/C/N=text0 width=15	
	
End

//Run the kriging process using precalculated weights (includes prompt for wave to krig)
Function runInterpScreen ()
	String posWvNm

	Prompt posWvNm, "Choose triplet wave to interpolate: ", popup, WaveList("*", ";", "")
	DoPrompt "Interpolation", posWvNm
	
	if (V_flag)
		Abort
	endif
	
	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	print "Start: ", date2str(datetime)
//	accountEndsQuant(positions_noNan)
	Wave positions = positions_noNan
	
	print "AccountEnds Complete: ", date2str(datetime)
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
		//Create matrix
	Wave intVal = root:intVal
	Wave grid = root:fltGridPts
	Duplicate/O/R=[][0] grid, xWv
	Duplicate/O/R=[][1] grid, yWv
	String lastChar = posWvNm[strlen(posWvNm) - 1]
	if (CmpStr(lastChar, "E") == 0 || CmpStr(lastChar, "N") == 0)
		Grid2Matrix(xWv,"ScreenWind" + lastChar,yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenWind" + lastChar
	else
		Grid2Matrix(xWv,"ScreenKrig",yWv,0,intVal,0)
		Wave ScreenImage = $"root:ScreenKrig"
		
		Display positionsSt[][2] vs positionsSt[][1]
		CurveFit/M=2/W=0 line, positionsSt[*][2]/X=positionsSt[*][1]/D
	endif
	
	//Plot Screen
	Wave ScreenPosZ = root:ScreenPosZ
	WaveStats/Q ScreenImage
	Display/W=(30,53,860.25,558.5) positionsSt[][1] vs positionsSt[][0]
	ModifyGraph mode=3,marker=19,msize=2,zColor($NameOfWave(positionsSt))={$NameOfWave(positionsSt)[*][2],V_min,V_max,Rainbow,1}
	AppendImage ScreenImage
	ModifyImage $NameOfWave(ScreenImage) ctab= {*,*,Rainbow,1}
	AppendToGraph ScreenPosZ
	ModifyGraph mode(ScreenPosZ)=7,hbFill(ScreenPosZ)=2,rgb(ScreenPosZ)=(39321,39321,39321)
	ColorScale/C/N=text0/A=MC/X=-45.31/Y=-34.77 image=$NameOfWave(ScreenImage), heightPct=30
	ColorScale/C/N=text0 width=15	
	
	print "All Done! ", date2str(datetime)
	
End


//Run the kriging process using precalculated weights (no prompt)
Function runInterpNoPrompt ()
	String posWvNm = "PositionSZC"

	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	accountEndsQuant(positions_noNan)
	Wave positions = root:Position_wQuantEnds

	residVector (positions)
	
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
//	print "Kriging Complete! ", date2str(datetime)
	
End

//Run the kriging process using precalculated weights (no prompt) for a screen
Function runInterpNoPromptScreen ()
	String posWvNm = "PositionSZC"

	Wave positionsSt = $posWvNm
	createVar()
	delNaNs(positionsSt)
	
	String newNm = posWvNm + "_noNan"
	Wave positions_noNan = $newNm
//	fillNans(positions_noNan)
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
//	accountEndsQuant(positions_noNan)
	Wave positions = positions_noNan

	residVector (positions)
	
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
//	print "Kriging Complete! ", date2str(datetime)
	
End

//Run the kriging process including the calculation of the weights (no prompt)
Function runFullKrig ()
	String posWvNm
	
	print "Kriging Started: ", date2str(datetime)
	Wave positionsSt = PositionSZC
	delNaNsFull(positionsSt)
	
	String newNm = "PositionSZC_noNan"
	Wave positions_noNan = $newNm
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
	accountEndsQuant(positions_noNan)
	Wave positions = root:Position_wQuantEnds
	
	distMatrix(positions)
	
	print "Data Matices Complete: ", date2str(datetime)
	Wave covarwv = root:cov
	invertDist (covarwv)
	
	print "Covariance Matrix Inverted: ", date2str(datetime)
	makeGrid (positions)
	
	print "Grid Complete: ", date2str(datetime)
	Wave grid = root:fltGridPts
	dist2Est (positions, grid)
	
	print "Grid Covariance Vectors Complete: ", date2str(datetime)
	Wave K_inv = root:cov_inv
	Wave k = root:covEst
	Wave k_loc = root:covLoc
	calcWeights (K_inv, k, k_loc)
	
	print "Weight Calculation Complete: ", date2str(datetime)	
	deleteEnds()
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
	print "Kriging Complete! ", date2str(datetime)
	
End

//Run the kriging process including the calculation of the weights (no prompt) for screens
Function runFullKrigScreen ()
	String posWvNm
	
	print "Kriging Started: ", date2str(datetime)
	Wave positionsSt = PositionSZC
	delNaNsFull(positionsSt)
	
	String newNm = "PositionSZC_noNan"
	Wave positions_noNan = $newNm
	if (exists("projNm") == 1)
		SVAR projNm
		if (CmpStr(projNm,"2013") == 0)
			removeDoubLoc(positions_noNan)
		endif
	endif
	
//	accountEndsQuant(positions_noNan)
	Wave positions = positions_noNan
	
	distMatrix(positions)
	
	print "Data Matices Complete: ", date2str(datetime)
	Wave covarwv = root:cov
	invertDist (covarwv)
	
	print "Covariance Matrix Inverted: ", date2str(datetime)
	makeGridScreen (positions)
	
	print "Grid Complete: ", date2str(datetime)
	Wave grid = root:fltGridPts
	dist2Est (positions, grid)
	
	print "Grid Covariance Vectors Complete: ", date2str(datetime)
	Wave K_inv = root:cov_inv
	Wave k = root:covEst
	Wave k_loc = root:covLoc
	calcWeights (K_inv, k, k_loc)
	
	print "Weight Calculation Complete: ", date2str(datetime)	
//	deleteEnds()
	residVector (positions)
	
	print "Residual Data Vector Complete: ", date2str(datetime)
	Wave residuals = root:residuals
	Wave weights = root:weights
	Wave weightsLoc = root:weightsLoc
	interpVal (residuals, weights, weightsLoc)
	
	print "Kriging Complete! ", date2str(datetime)
	
End

//Create global variables
Function createVar ()

	Variable/G nugget = 0
	Variable/G sill = 1
	Variable/G range
	Variable/G horgrid = 40
	Variable/G vertgrid = 20
	Variable/G ds = 40
	Variable/G dz = 20
	
	SVAR projNm
	if (CmpStr(projNm,"2013") == 0)
		range = 300
	else
		range = 500
	endif
	
End

//Delete rows that contain only NaNs
Function delNaNs (positions)
	Wave positions
	Variable i, j
	
	String posNm = NameofWave(positions)
	String newNm = posNm + "_noNan"
	
	Duplicate/O positions, $newNm
	Wave pos_noNan = $newNm
	Variable num = dimSize(pos_noNan, 0)
	
	for (i = 0; i < num; i += 1)
		j = num - i - 1
//		if (numtype(pos_noNan[j][0]) != 0 || numtype(pos_noNan[j][2]) != 0)
		if (numtype(pos_noNan[j][0]) != 0)
			DeletePoints j, 1, pos_noNan
		endif
	endfor

End

//Add a section of the end of the screen onto the beginning of it and vice versa to ensure that calculations on either end are calculated properly
Function accountEndsQuant (positions_wQuant)
	Wave positions_wQuant
	NVAR range
	Variable i
	Variable count = 0
	
	Duplicate/O/R=(0,dimSize(positions_wQuant,0))(0,0) positions_wQuant, sWv		//Distance along path
	Duplicate/O/R=(0,dimSize(positions_wQuant,0))(1,1) positions_wQuant, zWv		//Altitude
	Duplicate/O positions_wQuant, Position_wQuantEnds
	Variable/G sMax = wavemax(sWv)
	
	for (i = 0; i < dimSize(sWv, 0); i += 1)
		if (sWv[i] > sMax - range)
			InsertPoints count, 1, sWv, zWv, Position_wQuantEnds
			sWv[count] = sWv[i+1] - sMax
			zWv[count] = zWv[i+1]
			Position_wQuantEnds[count][0] = sWv[i+1] - sMax
			Position_wQuantEnds[count][1] = zWv[i+1]
			Position_wQuantEnds[count][2] = Position_wQuantEnds[i+1][2]
			count = count + 1
			i = i + 1
		elseif (sWv[i] < range)
			InsertPoints count, 1, sWv, zWv, Position_wQuantEnds
			sWv[count] = sWv[i+1] + sMax
			zWv[count] = zWv[i+1]
			Position_wQuantEnds[count][0] = sWv[i+1] + sMax
			Position_wQuantEnds[count][1] = zWv[i+1]
			Position_wQuantEnds[count][2] = Position_wQuantEnds[i+1][2]
			count = count + 1
			i = i + 1
		endif
	endfor	

End

//Create a matrix containing the distance between each flight point and every other flight point
Function distMatrix (positions)
	Wave positions
	Variable i, j, k
	NVAR range, nugget, sill
	
	Duplicate/O/R=(0,dimSize(positions,0))(0,0) positions, sWv		//Distance along path
	Duplicate/O/R=(0,dimSize(positions,0))(1,1) positions, zWv		//Altitude
	Make/O/N=(dimSize(sWv,0), dimSize(sWv,0)) dist
	Make/O/N=(dimSize(sWv,0), dimSize(sWv,0)) cov
	
	for (i = 0; i < dimSize(sWv,0); i += 1)
		for (k = 0; k < i; k += 1)
			dist[i][k] = dist[k][i]
			cov[i][k] = cov[k][i]
		endfor
		for (j = i; j < dimSize(sWv,0); j += 1)
			dist[i][j] = sqrt((sWv[i] - sWv[j])^2 + (zWv[i] - zWv[j])^2)
			if (dist[i][j] <= range)
				cov[i][j] = (sill - nugget)*(1 - 1.5*(dist[i][j]/range) + 0.5*(dist[i][j]/range)^3)
			else
				cov[i][j] = 0
			endif
		endfor
	endfor
	
End

//Invert the distance matrix
Function invertDist (covarwv)
	Wave covarwv
	Variable i, j

	MatrixOP/O cov_inv = inv(covarwv)
	
	for (i = 0; i < dimSize(cov_inv,0); i += 1)
		for (j = 0; j < dimSize(cov_inv,1); j += 1)
			if (abs(cov_inv[i][j]) < 0.0000001)
				cov_inv[i][j] = 0
			endif
		endfor
	endfor

End

//Create a grid encompassing the area of the flight
Function makeGrid (positions)
	Wave positions
	Variable distMax, distMin, altMax, altMin
	Variable i, j
	Variable k = 1
	NVAR horgrid
	NVAR vertgrid
	NVAR ns
	
	Duplicate/O/R=(0,dimSize(positions,0))(0,0) positions, sWv		//Distance along path
	Duplicate/O/R=(0,dimSize(positions,0))(1,1) positions, zWv		//Altitude
	
	distMax = round(wavemax(sWv) + 1)
	distMin = round(wavemin(sWv) - 1)
//	distMin = 0
//	distMax = ns
//	distMax = 10000

	altMax = round(wavemax(zWv) + 1)
//	altMax = 840
	altMin = round(wavemin(zWv) - 1)
	
	altMin = 0
	Variable/G nz = floor(altMax/20)*20 + 20
//	Variable/G nz = 840

	Make/O/N=(round((distMax - distMin)/horgrid + horgrid)*round((altMax - altMin)/vertgrid + vertgrid), 2) fltGridPts
	
	fltGridPts[0][0] = distMin
	fltGridPts[0][1] = altMin
		
	for (i = 1; i < round((distMax - distMin)/horgrid); i += 1)
		for (j = 0; j < round((altMax - altMin + 1)/vertgrid); j += 1)
			fltGridPts[k][1] = fltGridPts[k-1][1] + vertgrid
			fltGridPts[k][0] = fltGridPts[k-1][0]
			k = k + 1
		endfor
		fltGridPts[k][0] = fltGridPts[k-1][0] + horgrid
		fltGridPts[k][1] = altMin
		k = k + 1
	endfor			
	
	DeletePoints k-1, 100000, fltGridPts
	
End

//Create a grid encompassing the area of the flight
Function makeGridScreen (positions)
	Wave positions
	Variable distMax, distMin, altMax, altMin
	Variable i, j
	Variable k = 1
	NVAR horgrid
	NVAR vertgrid
	NVAR ns
	
	Duplicate/O/R=(0,dimSize(positions,0))(0,0) positions, sWv		//Distance along path
	Duplicate/O/R=(0,dimSize(positions,0))(1,1) positions, zWv		//Altitude
	
	distMax = round(wavemax(sWv) + 1)
	distMin = round(wavemin(sWv) - 1)
	distMin = 0
	distMax = ns
//	distMax = 10000
	altMax = round(wavemax(zWv) + 1)
	altMin = round(wavemin(zWv) - 1)
	
	altMin = 0
	Variable/G nz = floor(altMax/20)*20 + 20

	Make/O/N=(round((distMax - distMin)/horgrid + horgrid)*round((altMax - altMin)/vertgrid + vertgrid), 2) fltGridPts
	
	fltGridPts[0][0] = distMin
	fltGridPts[0][1] = altMin
		
	for (i = 1; i < round((distMax - distMin)/horgrid); i += 1)
		for (j = 0; j < round((altMax - altMin + 1)/vertgrid); j += 1)
			fltGridPts[k][1] = fltGridPts[k-1][1] + vertgrid
			fltGridPts[k][0] = fltGridPts[k-1][0]
			k = k + 1
		endfor
		fltGridPts[k][0] = fltGridPts[k-1][0] + horgrid
		fltGridPts[k][1] = altMin
		k = k + 1
	endfor			
	
	DeletePoints k-1, 1000000, fltGridPts
	
End

//Create a covariance matrix for the grid
Function dist2Est (positions, grid)
	Wave positions
	Wave grid
	Variable i, j, k
	Variable distance, count
	NVAR range, nugget, sill, ds, dz
	
	Make/O/N=(dimSize(grid,0), range/ds*range/dz) covEst = NaN
	Make/O/N=(dimSize(grid,0), range/ds*range/dz) covLoc = NaN
	
	Variable nthreads = ThreadProcessorCount
	print "Number of threads = " + num2str(nthreads)
	Variable threadGroupID = ThreadGroupCreate(nthreads)
	
	for (i = 0; i < dimSize(grid,0);)
		for (k = 0; k < nthreads; k += 1)
			ThreadStart threadGroupID, k, covPoint(i, positions, grid, covEst, covLoc, range, nugget, sill)
			i += 1
			
			if (i >= dimSize(grid,0))
				break
			endif

		endfor
		do
			Variable threadGroupStatus = ThreadGroupWait(threadGroupID, 100)
		while (threadGroupStatus != 0)
	endfor
	
	Variable dummy = ThreadGroupRelease(threadGroupID)

End

ThreadSafe Function covPoint(i, positions, grid, covEst, covLoc, range, nugget, sill)
	Variable i
	Wave positions, grid, covEst, covLoc
	Variable range, nugget, sill
	Variable j
	Variable distance
	
	Variable count = 0
	for (j = 0; j < dimSize(positions,0); j += 1)
		distance = sqrt((grid[i][0] - positions[j][0])^2 + (grid[i][1] - positions[j][1])^2)
		if (distance <= range)
			covLoc[i][count] = j
			covEst[i][count] = (sill - nugget)*(1 - 1.5*(distance/range) + 0.5*(distance/range)^3)
			count = count + 1
		endif
	endfor
	
End

//Calculate the weights based on the covariance matrix and the inverse of the distance covariance matrix
Function calcWeights (K_inv, k, k_loc)
	Wave K_inv							//Inverse of the matrix of covariances between each point
	Wave k								//Non-zero values of covariance vectors for grid points
	Wave k_loc							//Location of non-zero values of covariance vectors for grid points
	Variable i, j, m, o, count, wt, count2
	
	Make/O/N=(dimSize(k,0), 5000) weights = NaN
	Make/O/N=(dimSize(k,0), 5000) weightsLoc = NaN
	
	Variable nthreads = ThreadProcessorCount
	Variable threadGroupID = ThreadGroupCreate(nthreads)
	
	for (i = 0; i < dimSize(k,0);)									//Loop through each k vector
		for (o = 0; o < nthreads; o += 1)
			ThreadStart threadGroupID, o, krigPoint(i, K_inv, k, k_loc, weights, weightsLoc)
//		count2 = 0
//
//		for (j = 0; j < dimSize(K_inv,1); j += 1)					//Loop through each entry in the weights vector
//			wt = 0
//			for (m = 0; m < dimSize(k, 1); m += 1)
//				if (numtype(k[i][m]) == 2)
//					break
//				endif
//				wt = wt+ K_inv[j][k_loc[i][m]]*k[i][m]
//			endfor
//
//			if (wt != 0)
//				weights[i][count2] = wt
//				weightsLoc[i][count2] = j
//				count2 = count2 + 1
//			endif
//		endfor
			i += 1
			if (i >= dimSize(k,0))
				break
			endif
		endfor
		do
			Variable threadGroupStatus = ThreadGroupWait(threadGroupID,100)
		while (threadGroupStatus != 0)
	endfor
	
	Variable dummy = ThreadGroupRelease(threadGroupID)

End

ThreadSafe Function krigPoint(i, K_inv, k, k_loc, weights, weightsLoc)
	Variable i
	Wave K_inv, k, k_loc, weights, weightsLoc
	Variable j, m, wt

	Variable count2 = 0
	for (j = 0; j < dimSize(K_inv,1); j += 1)					//Loop through each entry in the weights vector
		wt = 0
		for (m = 0; m < dimSize(k, 1); m += 1)
			if (numtype(k[i][m]) == 2)
				break
			endif
			wt = wt+ K_inv[j][k_loc[i][m]]*k[i][m]
		endfor

		if (wt != 0)
			weights[i][count2] = wt
			weightsLoc[i][count2] = j
			count2 = count2 + 1
		endif
	endfor
	
	return 0

End

//Delete the ends that were added on by accountEnds
Function deleteEnds ()
	Wave fltGridPts, covEst, covLoc, weights, weightsLoc
	NVAR sMax
	Variable sMin = 0
	Variable i

//	Variable num = dimSize(fltGridPts,0)
//
//	do
//		if (fltGridPts[i][0] < sMin || fltGridPts[i][0] > sMax)
//			DeletePoints i, 1, fltGridPts, covEst, covLoc, weights, weightsLoc
//			num = num - 1
//		else
//			i = i + 1
//		endif	
//	while (i < num)
	
	Duplicate/O/R=[][0] fltGridPts, fltGridPtsX
	Variable ind = BinarySearch(fltGridPtsX,0)
	if (fltGridPts[ind][0] == 0)
		DeletePoints 0, ind, fltGridPts, fltGridPtsX, covEst, covLoc, weights, weightsLoc
	else
		DeletePoints 0, ind + 1, fltGridPts, fltGridPtsX, covEst, covLoc, weights, weightsLoc
	endif
	
	ind = BinarySearch(fltGridPtsX,sMax)
	if (ind > 0)
		if (fltGridPts[ind][0] == sMax)
			ind = BinarySearch(fltGridPtsX, sMax + 1)
			DeletePoints ind + 1, dimSize(fltGridPtsX,0), fltGridPts, fltGridPtsX, covEst, covLoc, weights, weightsLoc
		else
			DeletePoints ind + 1, dimSize(fltGridPtsX,0), fltGridPts, fltGridPtsX, covEst, covLoc, weights, weightsLoc
		endif	
	endif
	

End

//Calculate the residuals of the data
Function residVector (positions)
	Wave positions
	Variable i

	Duplicate/O/R=(0,dimSize(positions,0))(2,2) positions, krigQuant		//Distance along path
	Make/O/N=(dimSize(positions,0)) residuals

	WaveStats/Q krigQuant
	Variable/G avg = V_avg
	
	for (i = 0; i < dimSize(positions,0); i += 1)
		if (numtype(krigQuant[i]) == 0)
			residuals[i] = krigQuant[i] - avg
		else
			residuals[i] = NaN
		endif
	endfor

End

//Calculate the interpolated (kriged) value using the residuals and the weights
Function interpVal (residuals, weights, weightsLoc)
	Wave residuals, weights, weightsLoc
	Variable i, j, inta, intw
	NVAR avg
	
	Make/O/N=(dimSize(weights,0)) intVal
	Make/O/N=(dimSize(weights,0)) intWeight
	
	for (i = 0; i < dimSize(weights, 0); i += 1)
		inta = 0
		intw = 0
		for (j = 0; j < dimSize(weights,1); j += 1)
			if (numtype(weights[i][j]) == 2)
				break
			endif
			if (numtype(residuals[weightsLoc[i][j]]) == 0)
				inta = inta + weights[i][j]*residuals[weightsLoc[i][j]]
				intw = intw + weights[i][j]
			endif
		endfor
		intVal[i] = inta + avg
		intWeight[i] = intw
	endfor

End

//Convert grid points (3-col wave) into matrix  
Function Grid2Matrix(wx,matNm,wy,mktbl,wz,mkimg)
	Wave wx, wy, wz
	String matNm
	Variable mktbl,mkimg

	// Determine if x values vary most rapidly, or if y values vary most rapidly
	Variable yCols, xRows, xVariesMostRapidly
	Variable pnts= numpnts(wx)	// must be same for all waves
	WaveStats/Q wx
	Variable delta=(V_max-V_min) / pnts
	if( abs(wx[0] - wx[1] ) < delta )	// 	If adjacent X values differ by less than a linear increment from min to max, they're "constant".
		xVariesMostRapidly= 0			// the x values are all one value for a while, then switch to the next x value on the grid.
		yCols= WMRunLessThanDelta(wx,delta)
		xRows= pnts / yCols
	else
		xVariesMostRapidly= 1			// presumably the x values increment while the y's are all one value for a while.
		WaveStats/Q wy
		delta=(V_max-V_min) / pnts
		xRows= WMRunLessThanDelta(wy,delta)
		yCols= pnts / xRows
	endif
	Make/O/N=(xRows, yCols)/D $matNm
	Wave mat = $matNm
	SetScale/I x, wx[0], wx[pnts-1], WaveUnits(wx, 0), mat
	SetScale/I y, wy[0], wy[pnts-1], WaveUnits(wy, 0), mat

	if( xVariesMostRapidly )
		mat = wz[q*xrows+p]
	else
		mat = wz[p*ycols+q]
	endif
	
	if( mktbl == 1)
		Edit mat
	endif
	if( mkimg == 1)
		Display /W=(30,53,801,504.5)
		AppendImage/T mat
		ModifyImage ScreenKrig ctab= {0,*,Rainbow,1}
		SetAxis/A left
		ModifyGraph margin(right)=57
		ColorScale/C/N=text0/F=0/A=MC/X=54.27/Y=4.58 image=ScreenKrig
	endif
End

//Create a variogram of the data
Function variogram (positions, hdisp)
	Wave positions
	Variable hdisp
	Variable dval, zval, sourcePoint, bin, npnts
	Variable i, j, k, l, n
	Variable numdist, disth, roundval
	Variable count = 0
	NVAR range, sill, nugget
	
	Duplicate/O/R=(0,dimSize(positions,0))(0,0) positions, sWv
	Duplicate/O/R=(0,dimSize(positions,0))(1,1) positions, zWv
	Duplicate/O/R=(0,dimSize(positions,0))(2,2) positions, cWv
	
	Wave x = root:sWv
	Wave y = root:zWv
	Wave z = root:cWv
	
	numdist = (dimSize(y,0))*(dimSize(y,0) - 1)/2
	
	Make/D/O/N=(numdist) xdist
	Make/D/O/N=(numdist) ydist
	Make/D/O/N=(numdist) dist
	Make/D/O/N=(numdist) zdiff
	
	for (i = 0; i <= dimSize(y,0) - 1; i += 1)
		for (j = 0; j <= dimSize(y,0) - 1; j += 1)
			if (i < j)
				if (numtype(z[i]) == 0 && numtype(z[j]) == 0)
					xdist[count] = abs(x[i] - x[j])
					ydist[count] = abs(y[i] - y[j])
					dist[count] = sqrt((xdist[count])^2 + (ydist[count])^2)
					zdiff[count] = abs(z[i] - z[j])
					if (numtype(zdiff[count]) != 0)
						print z[i], z[j]
					endif
					count = count + 1
				endif
			endif
		endfor
	endfor
	
	Variable mindist = wavemin(dist)
	Variable maxdist = wavemax(dist)
	Variable diff = maxdist - mindist

	Make/O/N=(diff/hdisp + 1) counts = 0
	Make/O/N=(diff/hdisp + 1) zsum = 0
	Make/O/N=(diff/hdisp + 1) h = NaN
	roundval = hdisp

	for (k = 0; k <= dimSize(h,0) - 1; k += 1)
		h[k] = mindist + hdisp*k
	endfor

	npnts = numpnts(dist)
	sourcePoint = 0
	do
		zval = zdiff[sourcePoint]					// Get next value from source
		dval = dist[sourcePoint]
		bin = trunc((dval-mindist)/hdisp)				// Figure out which bin in dest it falls into
		zsum[bin] += zval	^2						// Add value from source to dest
		counts[bin] += 1
		sourcePoint += 1
	while (sourcePoint < npnts)
	
	Make/O/N=(dimSize(counts,0)) vari = 0
	
	for (n = 0; n <= dimSize(counts,0) - 1; n += 1)
		if (counts[n] != 0)
			vari[n] = zsum[n]/(2*counts[n])
		endif
	endfor

	Display /W=(221.25,139.25,1059.75,669.5)/N=VariogramPlot vari vs h
	ModifyGraph mode=3,marker=19,msize=2
	String title = "Variogram"
	TextBox/C/N=text0/F=0/A=MC/X=-2.16/Y=50.66 title
	SetAxis bottom 0,1000
	
	Variable num = wavemax(h)
	Make/O/N=(num) h_test = p
	Make/O/N=(num) vari_test = NaN
	
	for (i = 0; i < range; i += 1)
		vari_test[i] = nugget + (sill - nugget)*(3*h_test[i]/(2*range) - h_test[i]^3/(2*range^3))
	endfor
	for (i = range; i < num; i += 1)
		vari_test[i] = vari_test[range-1]
	endfor
	
	AppendToGraph vari_test vs h_test
	ModifyGraph rgb(vari_test)=(0,0,0)
	ControlBar 40
	SetVariable setRange,pos={92,12},size={120,16},title="Range: ",font="Arial",fSize=12
	SetVariable setRange,limits={0,inf,10},value= range
	SetVariable setSill,pos={222,12},size={120,16},title="Sill:  ",font="Arial",fSize=12
	SetVariable setSill,limits={0,inf,0.1},value= sill
	SetVariable setNugget,pos={352,12},size={120,16},title="Nugget:   ",font="Arial",fSize=12
	SetVariable setNugget,limits={0,inf,0.1},value= nugget
	Button button0,pos={511,6},size={100,25},proc=RerunVariFit,title="Rerun Fit"
	Button button1,pos={1000,6},size={100,25},proc=VariHelp,title="Help"
	Button button2,pos={742,6},size={100,25},proc=DoneVari,title="Done"
	Label bottom "Lag (m)"
	Label left "Semivariance"

End

//Delete rows that contain only NaNs
Function delNaNsFull (positions)
	Wave positions
	Variable i, j
	
	String posNm = NameofWave(positions)
	String newNm = posNm + "_noNan"
	
	Duplicate/O positions, $newNm
	Wave pos_noNan = $newNm
	Variable num = dimSize(pos_noNan, 0)
	
	for (i = 0; i < num; i += 1)
		j = num - i - 1
		if (numtype(pos_noNan[j][0]) != 0 || numtype(pos_noNan[j][2]) != 0)
//		if (numtype(pos_noNan[j][0]) != 0)
			DeletePoints j, 1, pos_noNan
		endif
	endfor

End

//If two points are located too close together, average the locations and value
Function removeDoubLoc (positions)
	Wave positions
	Variable i, j, distance
	
	Variable mindist = 20
	Variable num = dimSize(positions,0)
	
	for (i = 0; i < num; i += 1)
		for (j = i + 1; j < num; j += 1)
			if (numtype(positions[j][0]) == 0)
				distance = sqrt((positions[i][0] - positions[j][0])^2 + (positions[i][1] - positions[j][1])^2)
				if (distance < mindist)
					positions[i][0] = (positions[i][0] + positions[j][0])/2
					positions[i][1] = (positions[i][1] + positions[j][1])/2
					positions[i][2] = (positions[i][2] + positions[j][2])/2
					positions[j][0] = NaN
					positions[j][1] = NaN
					positions[j][2] = NaN
				endif
			endif
		endfor
	endfor
	
	for (i = 0; i < num; i += 1)
		j = num - i - 1
		if (numtype(positions[j][0]) == 2 || numtype(positions[j][0]) == 1)
			DeletePoints j, 1, positions
		endif
	endfor

End

//Change the variogram fit line based on the user's entries
Function RerunVariFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR range, sill, nugget
	Wave vari_test, h_test
	Variable i, num
	switch( ba.eventCode )
		case 2: // mouse up
			SetDrawLayer /K UserFront
			ControlInfo setRange
			range = V_Value
			ControlInfo setSill
			sill = V_Value
			ControlInfo setNugget
			nugget = V_Value	
			
			num = dimSize(h_test,0)
			for (i = 0; i < range; i += 1)
				vari_test[i] = nugget + (sill - nugget)*(3*h_test[i]/(2*range) - h_test[i]^3/(2*range^3))
			endfor
			for (i = range; i < num; i += 1)
				vari_test[i] = vari_test[range-1]
			endfor		
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Help with the variogram by drawing on lines showing the range, sill, nugget
Function VariHelp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR range, sill, nugget
	switch( ba.eventCode )
		case 2: // mouse up
			SetAxis bottom -30,1000
			SetDrawLayer /K UserFront
			SetDrawLayer UserFront
			SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65280),arrow= 2
			DrawLine range,sill,range,nugget
			SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65280),arrow= 2
			DrawLine -30,nugget,0,nugget
			SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (0,0,65280),arrow= 3
			DrawLine -30,sill,range,sill
			SetDrawEnv xcoord= bottom,ycoord= left,textrgb= (0,0,65280)
			DrawText range/2 - 30,sill + 0.01,"Range"
			SetDrawEnv xcoord= bottom,ycoord= left,textrgb= (0,0,65280)
			DrawText 10,nugget - 0.005,"Nugget"
			SetDrawEnv xcoord= bottom,ycoord= left,textrgb= (0,0,65280)
			DrawText range+15,sill/2,"Sill"
			SetDrawEnv xcoord= bottom,ycoord= left,dash= 3
			DrawLine -30,nugget,1000,nugget
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//User indicates they are finished with the variogram
Function DoneVari(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			KillWindow VariogramPlot
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End