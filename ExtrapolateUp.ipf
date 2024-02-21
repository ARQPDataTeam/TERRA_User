#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function upExtrap(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR nz, ns, dz, ds
	Variable extrap = nz + 300
	Variable/G extrapH
	Variable/G heightUp = nz - 300
	Variable/G heightDownFromTop = 300
	Variable/G indexUp = floor(ns/ds) 
	Variable extrapType
	Wave ScreenWindNf, ScreenWindEf, ScreenAirf, ScreenAirFlux
	SVAR unitStr

	switch( ba.eventCode )
		case 2: // mouse up
			Prompt extrapType, "Do you want to create a new extrapolation or revert to orginal screen?", popup, "New Extrapolation;Revert to Original Screen"
			Prompt extrap, "What height do you want to extrapolate to?"
			DoPrompt "Extrapolation Height", extrapType, extrap
			if (V_flag)
				Abort
			endif
			if (extrapType == 2)
				if (exists("ScreenU_original") == 1)
					Wave ScreenU_original, ScreenWindNf_original, ScreenWindEf_original, ScreenAirf_original, ScreenAirFlux_original, totalAirF_original
					Duplicate/O ScreenU_original, ScreenU
					Duplicate/O ScreenWindNf_original, ScreenWindNf
					Duplicate/O ScreenWindEf_original, ScreenWindEf
					Duplicate/O ScreenAirf_original, ScreenAirf
					Duplicate/O ScreenAirFlux_original, ScreenAirFlux
					Duplicate/O totalAirF_original, totalAirF
					if (CmpStr(unitStr,"ug/m^3") == 0)
						Wave ScreenU_ugm3_original, ScreenU_ppb_original
						Duplicate/O ScreenU_ugm3_original, ScreenU_ugm3
						Duplicate/O ScreenU_ppb_original, ScreenU_ppb
						Duplicate/O ScreenU_ugm3_original, ScreenU
					endif
					nz = dimSize(ScreenU,1)*dz - dz
					FillAboveData()
					TopValue()
					SetAxis/W=GraphSurface1 left 0,nz
				endif
			else
				extrapH = extrap
				UnfillUp()
				ProfilesOtherUp()
				ProfilesLineUp(heightDownFromTop)
				Make/o/n=(80) Profile_pnts_zUp, Profile_pnts_CUp
				Make/o/n=3000 up_Profile_pnts_C
				ProfilesExpUp(heightDownFromTop)
				Execute "GraphProfilesUp()"
				DoWindow/C GraphProfilesUp1
				createRatios("GraphProfilesUp1")
				Wave widRatio, heiRatio, vPosRatio, hPosRatio
				Duplicate/O widRatio, GraphProfilesUp1_sR
				Duplicate/O heiRatio, GraphProfilesUp1_zR
				Duplicate/O hPosRatio, GraphProfilesUp1_hR
				Duplicate/O vPosRatio, GraphProfilesUp1_vR
				ResetProfilesUp()
				
				if (exists("ScreenWindNf_original") == 1)
					Wave ScreenWindNf_original, ScreenWindEf_original, ScreenAirf_original, ScreenAirFlux_original, totalAirF_original
					Duplicate/O ScreenWindNf_original, ScreenWindNf
					Duplicate/O ScreenWindEf_original, ScreenWindEf
					Duplicate/O ScreenAirf_original, ScreenAirf
					Duplicate/O ScreenAirFlux_original, ScreenAirFlux
					Duplicate/O totalAirF_original, totalAirF
				endif
				highAltWS()
				FitProfiles_Flight()
				FillWindUp()
				fitAir()
				FillAirUp()
				Wave ScreenWindNf_Up, ScreenWindEf_Up, ScreenAirf_Up
				if (exists("ScreenWindNf_original") == 0)
					Duplicate ScreenWindNf, ScreenWindNf_original
					Duplicate ScreenWindEf, ScreenWindEf_original
					Duplicate ScreenAirf, ScreenAirf_original
					Duplicate ScreenAirFlux, ScreenAirFlux_original
					Duplicate totalAirF, totalAirF_original
				endif
				Duplicate/O ScreenWindNf_Up, ScreenWindNf
				Duplicate/O ScreenWindEf_Up, ScreenWindEf
				Duplicate/O ScreenAirf_Up, ScreenAirf
				
				SVAR projNm
				if (CmpStr(projNm,"2013") == 0)
					AirFluxCalc_2013()
				else
					AirFluxCalc()
				endif
				NVAR Total
				Make/D/O/N=1 totalAirF_temp = Total
				Duplicate/O totalAirF_temp, totalAirF
				
			//	UnfillUp()
				FillUp()
				CompareBaselinesUp()
				Make/D/O/N=(floor(ns/ds)) UserBaseUp = NaN	
				SetScale/P x 0,40,"", UserBaseUp
				Make/T/O/N=(floor(ns/ds)) Fit_FlagUp = ""
				Execute "GraphSurfaceUp()"
				DoWindow/C GraphSurfaceUp1
				createRatios("GraphSurfaceUp1")
				Wave widRatio, heiRatio, vPosRatio, hPosRatio
				Duplicate/O widRatio, GraphSurfaceUp1_sR
				Duplicate/O heiRatio, GraphSurfaceUp1_zR
				Duplicate/O hPosRatio, GraphSurfaceUp1_hR
				Duplicate/O vPosRatio, GraphSurfaceUp1_vR
			endif

			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function upExtrapScreen(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR nz, ns, dz, ds
	Variable extrap = nz + 300
	Variable/G extrapH
	Variable/G heightUp = nz - 300
	Variable/G heightDownFromTop = 300
	Variable/G indexUp = floor(ns/ds) 
	Variable extrapType
	Wave ScreenWindNf, ScreenWindEf, ScreenAirf, ScreenAirFlux, totalAirF
	SVAR unitStr

	switch( ba.eventCode )
		case 2: // mouse up
			Prompt extrapType, "Do you want to create a new extrapolation or revert to orginal screen?", popup, "New Extrapolation;Revert to Original Screen"
			Prompt extrap, "What height do you want to extrapolate to?"
			DoPrompt "Extrapolation Height", extrapType, extrap
			if (V_flag)
				Abort
			endif
			if (extrapType == 2)
				if (exists("ScreenU_original") == 1)
					Wave ScreenU_original, ScreenWindNf_original, ScreenWindEf_original, ScreenAirf_original, ScreenAirFlux_original, totalAirF_original
					Duplicate/O ScreenU_original, ScreenU
					Duplicate/O ScreenWindNf_original, ScreenWindNf
					Duplicate/O ScreenWindEf_original, ScreenWindEf
					Duplicate/O ScreenAirf_original, ScreenAirf
					Duplicate/O ScreenAirFlux_original, ScreenAirFlux
					Duplicate/O totalAirF_original, totalAirF
					if (CmpStr(unitStr,"ug/m^3") == 0)
						Wave ScreenU_ugm3_original, ScreenU_ppb_original
						Duplicate/O ScreenU_ugm3_original, ScreenU_ugm3
						Duplicate/O ScreenU_ppb_original, ScreenU_ppb
						Duplicate/O ScreenU_ugm3_original, ScreenU
					endif
					nz = dimSize(ScreenU,1)*dz - dz
					FillAboveData()
					TopValue()
					SetAxis/W=GraphSurface1 left 0,nz
				endif
			else
				extrapH = extrap
				UnfillUp()
				ProfilesOtherUp()
				ProfilesLineUp(heightDownFromTop)
				Make/o/n=(80) Profile_pnts_zUp, Profile_pnts_CUp
				Make/o/n=3000 up_Profile_pnts_C
				ProfilesExpUp(heightDownFromTop)
				Execute "GraphProfilesUp()"
				DoWindow/C GraphProfilesUp1
				createRatios("GraphProfilesUp1")
				Wave widRatio, heiRatio, vPosRatio, hPosRatio
				Duplicate/O widRatio, GraphProfilesUp1_sR
				Duplicate/O heiRatio, GraphProfilesUp1_zR
				Duplicate/O hPosRatio, GraphProfilesUp1_hR
				Duplicate/O vPosRatio, GraphProfilesUp1_vR
				ResetProfilesUp()
				
				if (exists("ScreenWindNf_original") == 1)
					Wave ScreenWindNf_original, ScreenWindEf_original, ScreenAirf_original, ScreenAirFlux_original, totalAirF_original
					Duplicate/O ScreenWindNf_original, ScreenWindNf
					Duplicate/O ScreenWindEf_original, ScreenWindEf
					Duplicate/O ScreenAirf_original, ScreenAirf
					Duplicate/O ScreenAirFlux_original, ScreenAirFlux
					Duplicate/O totalAirF_original, totalAirF
				endif
				highAltWS()
				FitProfiles_Flight()
				FillWindUp()
				fitAir()
				FillAirUp()
				Wave ScreenWindNf_Up, ScreenWindEf_Up, ScreenAirf_Up
				if (exists("ScreenWindNf_original") == 0)
					Duplicate ScreenWindNf, ScreenWindNf_original
					Duplicate ScreenWindEf, ScreenWindEf_original
					Duplicate ScreenAirf, ScreenAirf_original
					Duplicate ScreenAirFlux, ScreenAirFlux_original
					Duplicate totalAirF, totalAirF_original
				endif
				Duplicate/O ScreenWindNf_Up, ScreenWindNf
				Duplicate/O ScreenWindEf_Up, ScreenWindEf
				Duplicate/O ScreenAirf_Up, ScreenAirf

				SVAR projNm
				if (CmpStr(projNm,"2013") == 0)
					AirFluxCalc_2013()
				else
					AirFluxCalc()
				endif
				NVAR Total
				Make/D/O/N=1 totalAirF_temp = Total
				Duplicate/O totalAirF_temp, totalAirF
				
			//	UnfillUp()				
				FillUp()
				CompareBaselinesUp()
				Make/D/O/N=(floor(ns/ds)) UserBaseUp = NaN	
				SetScale/P x 0,40,"", UserBaseUp
				Make/T/O/N=(floor(ns/ds)) Fit_FlagUp = ""
				Execute "GraphSurfaceScreenUp()"
				DoWindow/C GraphSurfaceUp1
				createRatios("GraphSurfaceUp1")
				Wave widRatio, heiRatio, vPosRatio, hPosRatio
				Duplicate/O widRatio, GraphSurfaceUp1_sR
				Duplicate/O heiRatio, GraphSurfaceUp1_zR
				Duplicate/O hPosRatio, GraphSurfaceUp1_hR
				Duplicate/O vPosRatio, GraphSurfaceUp1_vR
			endif

			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ProfilesOtherUp()
	NVAR ds, dz, ns, nz, background, extrapH
	Variable si, uref, zi, slope, zref, zsur, intercept
	Wave ScreenU, ScreenPosZ
	
	Make/o/n=(2,2) up_Profile_pnts_C_Z
	Make/O/N=(4,(floor(ns/ds))) up_Profile_pnts_C_Z_All
	Make/o/n=(2,2) up_Profile_pnts_C_ZC
	Make/O/N=(4,(floor(ns/ds))) up_Profile_pnts_C_ZC_All	
	Make/o/n=(2,2) up_Profile_pnts_C_C
	Make/O/N=(4,(floor(ns/ds))) up_Profile_pnts_C_C_All
	Make/o/n=(2,2) maxHeight
	Make/O/N=(4,(floor(ns/ds))) maxHeight_All
	
	//Constant Value
	for (si=0; si<floor(ns/ds); si+=1)
		zi = dimSize(ScreenU,1) - 1
		if (si >= dimSize(ScreenU,0))
			break
		endif
		
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi + 2)*dz		
	//	zref = nz
	//	uref = ScreenU[si][zi]
		
		up_Profile_pnts_C_C[][1] = uref
		up_Profile_pnts_C_C[0][0] = zref
		up_Profile_pnts_C_C[1][0] = extrapH
		up_Profile_pnts_C_C_All[0][si] = up_Profile_pnts_C_C[0][0]
		up_Profile_pnts_C_C_All[1][si] = up_Profile_pnts_C_C[0][1]
		up_Profile_pnts_C_C_All[2][si] = up_Profile_pnts_C_C[1][0]	
		up_Profile_pnts_C_C_All[3][si] = up_Profile_pnts_C_C[1][1]	
	
	//Linear Between Constant and Background

		up_Profile_pnts_C_ZC[0][0] = zref
		up_Profile_pnts_C_ZC[0][1] = uref
		up_Profile_pnts_C_ZC[1][0] = extrapH
		up_Profile_pnts_C_ZC[1][1] = background
		up_Profile_pnts_C_ZC_All[0][si] = up_Profile_pnts_C_ZC[0][0]
		up_Profile_pnts_C_ZC_All[1][si] = up_Profile_pnts_C_ZC[0][1]
		up_Profile_pnts_C_ZC_All[2][si] = up_Profile_pnts_C_ZC[1][0]	
		up_Profile_pnts_C_ZC_All[3][si] = up_Profile_pnts_C_ZC[1][1]		
		
		maxHeight[][0] = zref
		maxHeight[0][1] = 0
		maxHeight[1][1] = 500	
		maxHeight_All[0][si] = maxHeight[0][0]
		maxHeight_All[1][si] = maxHeight[0][1]
		maxHeight_All[2][si] = maxHeight[1][0]	
		maxHeight_All[3][si] = maxHeight[1][1]	
		
	//Background
		
		up_Profile_pnts_C_Z[][1] = background
		up_Profile_pnts_C_Z[0][0] = zref
		up_Profile_pnts_C_Z[1][0] = extrapH
		up_Profile_pnts_C_Z_All[0][si] = up_Profile_pnts_C_Z[0][0]
		up_Profile_pnts_C_Z_All[1][si] = up_Profile_pnts_C_Z[0][1]
		up_Profile_pnts_C_Z_All[2][si] = up_Profile_pnts_C_Z[1][0]	
		up_Profile_pnts_C_Z_All[3][si] = up_Profile_pnts_C_Z[1][1]		
		
	endfor

End

Function ProfilesLineUp(heightDownFromTop)
	Variable heightDownFromTop
	Variable height
	variable i, s, z, si, zi, n
	variable/g ds, dz, ns, nz
	variable/g bg
	variable sx, sy, sxx, sxy, syy
	Variable ztop, zref, uref
	wave ScreenU, ScreenPosZ
	NVAR extrapH
	
	make/o/n=(floor(ns/ds)) FitaUp=nan, FitbUp=nan, FitR2Up=nan
	setscale/p x, 0, ds, FitaUp, FitbUp, FitR2Up
  
	make/o/n=(extrapH) up_Profile_pnts_C_L
	Make/O/N=(extrapH,(floor(ns/ds))) up_Profile_pnts_C_L_All

	for (si=0; si<floor(ns/ds); si+=1)
		zi = dimSize(ScreenU,1) - 1
		ztop = (dimSize(ScreenU,1)-1)*dz
		
    // Find highest data point
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi + 2)*dz
		height = zref - heightDownFromTop
  
		sx = 0; sy = 0; sxx = 0; sxy = 0; syy = 0; n = 0

		for(zi=0; zi<floor(nz/dz); zi+=1)
			z = zi*dz
			if (numtype(ScreenU[si][zi])==0 && z> height)
				sx += z
				sy += ScreenU[si][zi]
				sxx += z^2
				sxy += z*ScreenU[si][zi]
				syy += ScreenU[si][zi]^2
				n += 1
			endif
		endfor
		FitR2Up[si] = (n*sxy - sx*sy)^2/((n*sxx - sx*sx)*(n*syy - sy*sy))
		FitbUp[si] = (n*sxy - sx*sy)/(n*sxx - sx*sx)
		FitaUp[si] = sy/n - FitbUp[si]*sx/n
		
		up_Profile_pnts_C_L = FitaUp[si] + FitbUp[si]*x
		
		up_Profile_pnts_C_L_All[][si] = up_Profile_pnts_C_L[p]
	endfor

End

Function ProfilesExpUp(heightDownFromTop)
	Variable heightDownFromTop
	Variable height
	variable i, s, z, si, zi, n
	variable/g ds, dz, ns, nz
	variable/g bg
	variable sx, sy, sxx, sxy, syy, xval, yval
	wave ScreenU, ScreenPosZ
	NVAR extrapH

	Make/D/N=3/O W_coef
	make/o/n=(floor(ns/ds)) FitExpCbgUp=nan, FitExpAUp=nan, FitExpBUp=nan, FitExpR2Up=nan
	setscale/p x, 0, ds, FitExpCbgUp, FitExpAUp, FitExpBUp, FitExpR2Up
  
	Make/o/n=(extrapH) up_Profile_pnts_C
	Make/O/N=(extrapH,(floor(ns/ds))) up_Profile_pnts_C_All
	Make/o/n=(80,(floor(ns/ds))) Profile_pnts_z_AllUp, Profile_pnts_C_AllUp = NaN
	Make/O/N=(floor(ns/ds)) Profile_C_maxUp

	for (si=0; si<floor(ns/ds); si+=1)

		W_coef[0] = 0
		n = 0
		if (si >= dimSize(ScreenU,0))
			break
		endif
		
		zi = dimSize(ScreenU,1) - 1
		Variable uref, zref
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi + 2)*dz
		height = zref - heightDownFromTop
		
		for (zi=0; zi<floor(nz/dz); zi+=1)
			z = zi*dz
			if (numtype(ScreenU[si][zi])==0 && z > height)
				W_coef[0] += ScreenU[si][zi]
				n += 1
			endif
		endfor
		W_coef[0] /= n
		W_coef[1] = 0.1
		W_coef[2] = 200
  
		make/o/n=(80) Profile_pnts_zUp, Profile_pnts_CUp = NaN
		n = 0
		
		for (zi=0; zi<floor(nz/dz); zi+=1)
//			z = zi*dz - ScreenPosZ[si*ds/2]
			z = zi*dz
			if (numtype(ScreenU[si][zi])==0 && z> height)
				Profile_pnts_zUp[n] = z
				Profile_pnts_CUp[n] = ScreenU[si][zi]
				n += 1
			endif
		endfor

		deletepoints (n), (80-n), Profile_pnts_zUp, Profile_pnts_CUp
		Variable/G V_fitError = 0
		FuncFit/W=2/Q/NTHR=0/H="100" ExpxUp W_coef Profile_pnts_CUp /X=Profile_pnts_zUp

		FitExpCbgUp[si] = W_coef[0]
 		FitExpAUp[si] = W_coef[1]
		FitExpBUp[si] = W_coef[2]

		up_Profile_pnts_C = W_coef[0] + W_coef[1]*exp(-((extrapH-x)/W_coef[2])^2)

		sx = 0; sy = 0; sxx = 0; sxy = 0; syy = 0
		for (i=0; i<n; i+=1)
			xval = Profile_pnts_CUp[i]
			yval = W_coef[0] + W_coef[1]*exp(-((extrapH-Profile_pnts_zUp[i])/W_coef[2])^2)
			sx += xval
			sy += yval
			sxx += xval^2
			sxy += xval*yval
			syy += yval^2
		endfor
		FitExpR2Up[si] = (n*sxy - sx*sy)^2/((n*sxx - sx*sx)*(n*syy - sy*sy))
		
		up_Profile_pnts_C_All[][si] = up_Profile_pnts_C[p]
		Profile_C_maxUp[si] = wavemax(Profile_pnts_CUp)
		for (i = 0; i < dimSize(Profile_pnts_CUp,0); i += 1)
			Profile_pnts_C_AllUp[i][si] = Profile_pnts_CUp[i]
			Profile_pnts_z_AllUp[i][si] = Profile_pnts_zUp[i]
		endfor

	endfor	

End

Window GraphProfilesUp() : Graph
	PauseUpdate; Silent 1		// building window...
	Display/VERT /W=(25.5,20,495,372.5) maxHeight[*][1] vs maxHeight[*][0]
	AppendToGraph/VERT Profile_pnts_CUp vs Profile_pnts_zUp
	AppendToGraph/VERT up_Profile_pnts_C_L,up_Profile_pnts_C
	AppendToGraph/VERT up_Profile_pnts_C_C[*][1] vs up_Profile_pnts_C_C[*][0]
	AppendToGraph/VERT up_Profile_pnts_C_ZC[*][1] vs up_Profile_pnts_C_ZC[*][0]
	AppendToGraph/VERT up_Profile_pnts_C_Z[*][1] vs up_Profile_pnts_C_Z[*][0]
	ModifyGraph margin(bottom)=110
	ModifyGraph mode(Profile_pnts_CUp)=3
	ModifyGraph marker(Profile_pnts_CUp)=19
	ModifyGraph lSize(maxHeight)=2
	ModifyGraph rgb(maxHeight)=(0,0,0),rgb(up_Profile_pnts_C_L)=(0,52224,0),rgb(up_Profile_pnts_C)=(65280,0,0)
	ModifyGraph rgb(up_Profile_pnts_C_Z)=(44032,29440,58880),rgb(up_Profile_pnts_C_C)=(0,0,0)
	ModifyGraph rgb(up_Profile_pnts_C_ZC)=(39168,39168,0)
	ModifyGraph msize(Profile_pnts_CUp)=2
	ModifyGraph mirror=1
	ModifyGraph nticks=20
	ModifyGraph font="Times New Roman"
	ModifyGraph fSize=12
	ModifyGraph highTrip(bottom)=1e+06
	ModifyGraph lowTrip(bottom)=0.0001
	ModifyGraph lblMargin=5
	ModifyGraph standoff=0
	SetAxis bottom 0,10
	SetAxis left nz-300,extrapH
	Label left "Height (m)"
	Label bottom "Concentration"
	ModifyGraph lblMargin(bottom)=70,lblLatPos(bottom)=-40
	Legend/C/N=text0/J/X=-4.26/Y=113.65 "\\Z10\\s(Profile_pnts_CUp) Points\r\\s(up_Profile_pnts_C_C) Constant\r\\s(up_Profile_pnts_C_L) Linear"
	AppendText "\\s(up_Profile_pnts_C) Exponential\r\\s(up_Profile_pnts_C_Z) Background\r\\s(up_Profile_pnts_C_ZC) Linear Between Constant and BG"
	TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*index) + " m"
	ControlBar/R 100
	Button button0,pos={534,23},size={90,50},proc=ProfilePrevUp,title="Previous"
	Button button1,pos={534,75},size={90,50},proc=ProfileNextUp,title="Next"
	SetVariable setvar0,pos={534,175},size={90,16},proc=ProfileVarUp,title=" "
	SetVariable setvar0,limits={0,dimSize(ScreenU,0),1},value= indexUp
	SetVariable SetHeight,pos={533,309},size={90,16},proc=NewHeightUp,title=" "
	SetVariable SetHeight,limits={100,2000,10},value= heightDownFromTop
	Button button2,pos={534,330},size={90,50},proc=RerunFitsUp,title="Rerun"
	TitleBox title0,pos={543,139},size={64,34},title="Horizontal\rGrid Square"
	TitleBox title1,pos={545,260},size={39,21},title="Distance\rto Fit Down"
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro


Window GraphSurfaceUp() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(511.5,43.25,1407.75,714.5) PositionSZC[*][1] vs PositionSZC[*][0]
	AppendToGraph ScreenPosZ
	AppendToGraph Frame[*][1] vs Frame[*][0]
	AppendToGraph/L=l1 BaseUp[*][0],BaseUp[*][1],BaseUp[*][2],BaseUp[*][3],BaseUp[*][4]
	AppendToGraph/L=l2 UserBaseUp
	AppendToGraph currLeftUp[*][1] vs currLeftUp[*][0]
	AppendToGraph currRightUp[*][1] vs currRightUp[*][0]
	AppendToGraph currTopUp[*][1] vs currTopUp[*][0]
	AppendToGraph currBotUp[*][1] vs currBotUp[*][0]
	AppendImage/T ScreenU
	ModifyImage ScreenU ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=30,margin(bottom)=30,margin(top)=30,margin(right)=50
	ModifyGraph mode(PositionSZC)=2,mode(ScreenPosZ)=7,mode(Frame)=1,mode(BaseUp#2)=4
	ModifyGraph lSize(PositionSZC)=2,lSize(Frame)=1.2,lSize(BaseUp)=1.2,lSize(BaseUp#1)=1.2
	ModifyGraph lSize(BaseUp#3)=1.2,lSize(BaseUp#4)=1.2
	ModifyGraph rgb(PositionSZC)=(0,0,0),rgb(ScreenPosZ)=(26112,26112,26112),rgb(Frame)=(0,0,0)
	ModifyGraph rgb(BaseUp)=(0,0,0),rgb(BaseUp#1)=(0,52224,0),rgb(BaseUp#3)=(44032,29440,58880)
	ModifyGraph rgb(BaseUp#4)=(39168,39168,0),rgb(UserBaseUp)=(0,0,0)
	ModifyGraph msize(BaseUp#2)=2
	ModifyGraph hbFill(ScreenPosZ)=2
	ModifyGraph mirror(left)=2,mirror(bottom)=0,mirror(l1)=2,mirror(l2)=2,mirror(top)=0
	ModifyGraph nticks(left)=2,nticks(bottom)=18,nticks(l1)=2,nticks(l2)=2,nticks(top)=18
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
	ModifyGraph axisEnab(left)={0,0.49}
	ModifyGraph axisEnab(l1)={0.7,0.99}
	ModifyGraph axisEnab(l2)={0.5,0.69}
	Label left "\\Z10Altitude (m)"
	Label bottom "\\Z10\\f02s\\f00 [m]"
	Label l1 "\\Z10Top Value"
	SetAxis left 0,nz
	SetAxis l1 -10,50
	Cursor/P/S=1/C=(0,15872,65280) A BaseUp 0;Cursor/P/S=1/C=(16384,16384,65280) B BaseUp 100;Cursor/P/S=1/C=(65280,0,52224) C PositionSZC 0
	ShowInfo
	Legend/C/N=text0/J/X=2.83/Y=1.96 "\\F'times'\\Z12\r\\s(BaseUp) Constant\r\\s(BaseUp#1) Linear Fit\r\\s(BaseUp#2) Exponential\r\\s(BaseUp#3) Background"
	AppendText "\\s(BaseUp#4) Linear Between Constant and Background"
	ColorScale/C/N=text1/F=0/M/A=RT/X=-6.47/Y=56.56 image=ScreenU, heightPct=40
	ColorScale/C/N=text1 width=10, fsize=10, logLTrip=0.0001, lowTrip=0.1
	ControlBar/R 100
	TitleBox title0,pos={1095,192},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title1,pos={1095,428},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title2,pos={1095,610},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	Button button0,pos={1102,28},size={90,50},proc=DispScreens,title="Show Wind/\rAir Screens"
	Button button1,pos={1102,80},size={90,50},proc=PlotTS,title="Show Time\r Series"
	Button button2,pos={1102,132},size={90,50},proc=PlotVP,title="Show Vertical\r Profile"
	Button button3,pos={1102,212},size={90,50},proc=ResetAxis,title="Reset Axis"
	Button button4,pos={1102,264},size={90,50},proc=PrintTime,title="Print Values"
	Button button5,pos={1102,316},size={90,50},proc=SelEmis,title="Obtain Emission\rSelected Section"
	Button button6,pos={1102,368},size={90,50},proc=SelAvg,title="Obtain Average\rSelected Section"
	Button button7,pos={1102,448},size={90,50},proc=TopMix,title="Change Top \rMixing Ratio",disable=2
	Button button8,pos={1102,500},size={90,50},proc=changeBG,title="Change \rBackground"
	Button button9,pos={1102,552},size={90,50},proc=upExtrap,title="Extrapolate\r Upward",disable=2
	Button button10,pos={1102,632},size={90,50},proc=SaveProfUp,title="Set Profiles"
	Button button11,pos={1102,684},size={90,50},proc=DoneProfUp,title="Done"
	Button button12,pos={1102,835},size={90,50},proc=Help,title="Help"
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro

Window GraphSurfaceScreenUp() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(511.5,43.25,1407.75,714.5) PositionSZC[*][1] vs PositionSZC[*][0]
	AppendToGraph ScreenPosZ
	AppendToGraph/L=l1 BaseUp[*][0],BaseUp[*][1],BaseUp[*][2],BaseUp[*][3],BaseUp[*][4]
	AppendToGraph/L=l2 UserBaseUp
	AppendToGraph currLeftUp[*][1] vs currLeftUp[*][0]
	AppendToGraph currRightUp[*][1] vs currRightUp[*][0]
	AppendToGraph currTopUp[*][1] vs currTopUp[*][0]
	AppendToGraph currBotUp[*][1] vs currBotUp[*][0]
	AppendImage/T ScreenU
	ModifyImage ScreenU ctab= {*,*,Rainbow,1}
	ModifyGraph margin(left)=30,margin(bottom)=30,margin(top)=30,margin(right)=50
	ModifyGraph mode(PositionSZC)=2,mode(ScreenPosZ)=7,mode(BaseUp#2)=4
	ModifyGraph lSize(PositionSZC)=2,lSize(BaseUp)=1.2,lSize(BaseUp#1)=1.2
	ModifyGraph lSize(BaseUp#3)=1.2,lSize(BaseUp#4)=1.2
	ModifyGraph rgb(PositionSZC)=(0,0,0),rgb(ScreenPosZ)=(26112,26112,26112)
	ModifyGraph rgb(BaseUp)=(0,0,0),rgb(BaseUp#1)=(0,52224,0),rgb(BaseUp#3)=(44032,29440,58880)
	ModifyGraph rgb(BaseUp#4)=(39168,39168,0),rgb(UserBaseUp)=(0,0,0)
	ModifyGraph msize(BaseUp#2)=2
	ModifyGraph hbFill(ScreenPosZ)=2
	ModifyGraph mirror(left)=2,mirror(bottom)=0,mirror(l1)=2,mirror(l2)=2,mirror(top)=0
	ModifyGraph nticks(left)=2,nticks(bottom)=18,nticks(l1)=2,nticks(l2)=2,nticks(top)=18
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
	ModifyGraph axisEnab(left)={0,0.49}
	ModifyGraph axisEnab(l1)={0.7,0.99}
	ModifyGraph axisEnab(l2)={0.5,0.69}
	Label left "\\Z10Altitude (m)"
	Label bottom "\\Z10\\f02s\\f00 [m]"
	Label l1 "\\Z10Top Value"
	SetAxis left 0,nz
	SetAxis l1 -10,50
	Cursor/P/S=1/C=(0,15872,65280) A BaseUp 0;Cursor/P/S=1/C=(16384,16384,65280) B BaseUp 100;Cursor/P/S=1/C=(65280,0,52224) C PositionSZC 0
	ShowInfo
	Legend/C/N=text0/J/X=2.83/Y=1.96 "\\F'times'\\Z12\r\\s(BaseUp) Constant\r\\s(BaseUp#1) Linear Fit\r\\s(BaseUp#2) Exponential\r\\s(BaseUp#3) Background"
	AppendText "\\s(BaseUp#4) Linear Between Constant and Background"
	ColorScale/C/N=text1/F=0/M/A=RT/X=-6.47/Y=56.56 image=ScreenU, heightPct=40
	ColorScale/C/N=text1 width=10, fsize=10, logLTrip=0.0001, lowTrip=0.1
	ControlBar/R 100
	TitleBox title0,pos={1095,192},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title1,pos={1095,428},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	TitleBox title2,pos={1095,610},fixedSize=1,size={120,10},title=" ",labelBack=(52224,52224,52224)
	Button button0,pos={1102,28},size={90,50},proc=DispScreens,title="Show Wind/\rAir Screens"
	Button button1,pos={1102,80},size={90,50},proc=PlotTS,title="Show Time\r Series"
	Button button2,pos={1102,132},size={90,50},proc=PlotVP,title="Show Vertical\r Profile"
	Button button3,pos={1102,212},size={90,50},proc=ResetAxis,title="Reset Axis"
	Button button4,pos={1102,264},size={90,50},proc=PrintTime,title="Print Values"
	Button button5,pos={1102,316},size={90,50},proc=SelEmis,title="Obtain Emission\rSelected Section"
	Button button6,pos={1102,368},size={90,50},proc=SelAvg,title="Obtain Average\rSelected Section"
	Button button7,pos={1102,448},size={90,50},proc=TopMix,title="Change Top \rMixing Ratio",disable=2
	Button button8,pos={1102,500},size={90,50},proc=changeBG,title="Change \rBackground"
	Button button9,pos={1102,552},size={90,50},proc=upExtrap,title="Extrapolate\r Upward",disable=2
	Button button10,pos={1102,632},size={90,50},proc=SaveProfUp,title="Set Profiles"
	Button button11,pos={1102,684},size={90,50},proc=DoneProfUpScreen,title="Done"
	Button button12,pos={1102,835},size={90,50},proc=Help,title="Help"
	SetWindow kwTopWin,hook(winResize)=resizeWindow
EndMacro



Function ResetProfilesUp()
	NVAR indexUp, maxC, ds, heightUp, extrapH
	Wave Profile_pnts_C_AllUp,  Profile_pnts_CUp, Profile_pnts_z_AllUp,  Profile_pnts_zUp, up_Profile_pnts_C_All,  up_Profile_pnts_C, up_Profile_pnts_C_L_All, up_Profile_pnts_C_L  
	Wave up_Profile_pnts_C_Z, up_Profile_pnts_C_Z_All, up_Profile_pnts_C_ZC_All, up_Profile_pnts_C_ZC, up_Profile_pnts_C_C_All, up_Profile_pnts_C_C  
	Wave Profile_C_maxUp, maxHeight, maxHeight_All
	
	Wave ScreenPosZ

	Make/O/N=(2,2) currLeftUp, currRightUp, currTopUp, currBotUp

	indexUp = indexUp - 1
	Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_C_AllUp,  Profile_pnts_CUp
	Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_z_AllUp,  Profile_pnts_zUp
	Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_All,  up_Profile_pnts_C
	Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_L_All,  up_Profile_pnts_C_L
	up_Profile_pnts_C_C[0][0] = up_Profile_pnts_C_C_All[0][indexUp]
	up_Profile_pnts_C_C[0][1] = up_Profile_pnts_C_C_All[1][indexUp]
	up_Profile_pnts_C_C[1][0] = up_Profile_pnts_C_C_All[2][indexUp]
	up_Profile_pnts_C_C[1][1] = up_Profile_pnts_C_C_All[3][indexUp]
	up_Profile_pnts_C_ZC[0][0] = up_Profile_pnts_C_ZC_All[0][indexUp]
	up_Profile_pnts_C_ZC[0][1] = up_Profile_pnts_C_ZC_All[1][indexUp]
	up_Profile_pnts_C_ZC[1][0] = up_Profile_pnts_C_ZC_All[2][indexUp]
	up_Profile_pnts_C_ZC[1][1] = up_Profile_pnts_C_ZC_All[3][indexUp]
	up_Profile_pnts_C_Z[0][0] = up_Profile_pnts_C_Z_All[0][indexUp]
	up_Profile_pnts_C_Z[0][1] = up_Profile_pnts_C_Z_All[1][indexUp]
	up_Profile_pnts_C_Z[1][0] = up_Profile_pnts_C_Z_All[2][indexUp]
	up_Profile_pnts_C_Z[1][1] = up_Profile_pnts_C_Z_All[3][indexUp]	
	maxHeight[0][0] = maxHeight_All[0][indexUp]
	maxHeight[0][1] = maxHeight_All[1][indexUp]
	maxHeight[1][0] = maxHeight_All[2][indexUp]
	maxHeight[1][1] = maxHeight_All[3][indexUp]	
	maxC = Profile_C_maxUp[indexUp]
	TextBox/K/N=text1
	TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*indexUp) + " m"
	SetAxis bottom 0, maxC		
	
	Variable uref, zref
	Wave ScreenU
	NVAR dz
	Variable zi = dimSize(ScreenU,1) - 1
	Variable ztop = zi*dz
	do
		uref = ScreenU[indexUp][zi]
		zi -= 1
	while(numtype(uref)!=0 && zi>0)
	zref = (zi + 2)*dz
	
	//Create current profile position box on GraphSurface
	currLeftUp[][0] = indexUp*ds
	currLeftUp[0][1] = heightUp - (ztop - zref)
	currLeftUp[1][1] = extrapH
	
	currRightUp[][0] = indexUp*ds + ds
	currRightUp[0][1] = heightUp - (ztop - zref)
	currRightUp[1][1] = extrapH
	
	//This is actually the bottom of the box for upward extrapolation
	currTopUp[0][0] = indexUp*ds
	currTopUp[1][0] = indexUp*ds + ds
	currTopUp[][1] = heightUp - (ztop - zref)
	
	//This is actually the top of the box for upward extrapolation
	currBotUp[0][0] = indexUp*ds
	currBotUp[1][0] = indexUp*ds + ds
	currBotUp[][1] = extrapH		
	
	SetAxis/W=GraphProfilesUp1 left heightUp - (ztop - zref),extrapH					

End

//Move to the next profile (if one exists)
Function ProfileNextUp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR indexUp, indmax, maxC, ds, heightUp, extrapH
	Wave Profile_pnts_C_AllUp,  Profile_pnts_CUp, Profile_pnts_z_AllUp,  Profile_pnts_zUp, up_Profile_pnts_C_All,  up_Profile_pnts_C, up_Profile_pnts_C_L_All, up_Profile_pnts_C_L  
	Wave up_Profile_pnts_C_Z, up_Profile_pnts_C_Z_All, up_Profile_pnts_C_ZC_All, up_Profile_pnts_C_ZC, up_Profile_pnts_C_C_All, up_Profile_pnts_C_C  
	Wave Profile_C_maxUp, maxHeight, maxHeight_All
	Wave ScreenPosZ, currLeftUp, currRightUp, currTopUp, currBotUp
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (indexUp < indmax - 1)
				indexUp = indexUp + 1
				Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_C_AllUp,  Profile_pnts_CUp
				Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_z_AllUp,  Profile_pnts_zUp
				Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_All,  up_Profile_pnts_C
				Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_L_All,  up_Profile_pnts_C_L
				up_Profile_pnts_C_C[0][0] = up_Profile_pnts_C_C_All[0][indexUp]
				up_Profile_pnts_C_C[0][1] = up_Profile_pnts_C_C_All[1][indexUp]
				up_Profile_pnts_C_C[1][0] = up_Profile_pnts_C_C_All[2][indexUp]
				up_Profile_pnts_C_C[1][1] = up_Profile_pnts_C_C_All[3][indexUp]
				up_Profile_pnts_C_ZC[0][0] = up_Profile_pnts_C_ZC_All[0][indexUp]
				up_Profile_pnts_C_ZC[0][1] = up_Profile_pnts_C_ZC_All[1][indexUp]
				up_Profile_pnts_C_ZC[1][0] = up_Profile_pnts_C_ZC_All[2][indexUp]
				up_Profile_pnts_C_ZC[1][1] = up_Profile_pnts_C_ZC_All[3][indexUp]
				up_Profile_pnts_C_Z[0][0] = up_Profile_pnts_C_Z_All[0][indexUp]
				up_Profile_pnts_C_Z[0][1] = up_Profile_pnts_C_Z_All[1][indexUp]
				up_Profile_pnts_C_Z[1][0] = up_Profile_pnts_C_Z_All[2][indexUp]
				up_Profile_pnts_C_Z[1][1] = up_Profile_pnts_C_Z_All[3][indexUp]	
				maxHeight[0][0] = maxHeight_All[0][indexUp]
				maxHeight[0][1] = maxHeight_All[1][indexUp]
				maxHeight[1][0] = maxHeight_All[2][indexUp]
				maxHeight[1][1] = maxHeight_All[3][indexUp]	
				maxC = Profile_C_maxUp[indexUp]
				TextBox/K/N=text1
				TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*indexUp) + " m"
				SetAxis bottom 0, maxC	
				
				Variable uref, zref
				Wave ScreenU
				NVAR dz
				Variable zi = dimSize(ScreenU,1) - 1
				Variable ztop = zi*dz
				do
					uref = ScreenU[indexUp][zi]
					zi -= 1
				while(numtype(uref)!=0 && zi>0)
				zref = (zi + 2)*dz
				
				currLeftUp[][0] = indexUp*ds
				currLeftUp[0][1] = heightUp - (ztop - zref)
				currLeftUp[1][1] = extrapH
				
				currRightUp[][0] = indexUp*ds + ds
				currRightUp[0][1] = heightUp - (ztop - zref)
				currRightUp[1][1] = extrapH
				
				currTopUp[0][0] = indexUp*ds
				currTopUp[1][0] = indexUp*ds + ds
				currTopUp[][1] = heightUp - (ztop - zref)
				
				currBotUp[0][0] = indexUp*ds
				currBotUp[1][0] = indexUp*ds + ds
				currBotUp[][1] = extrapH		
				
				SetAxis/W=GraphProfilesUp1 left heightUp - (ztop - zref),extrapH			

			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Move to the previous profile (if one exists)
Function ProfilePrevUp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR indexUp, maxC, ds, heightUp, extrapH
	Wave Profile_pnts_C_AllUp,  Profile_pnts_CUp, Profile_pnts_z_AllUp,  Profile_pnts_zUp, up_Profile_pnts_C_All,  up_Profile_pnts_C, up_Profile_pnts_C_L_All, up_Profile_pnts_C_L  
	Wave up_Profile_pnts_C_Z, up_Profile_pnts_C_Z_All, up_Profile_pnts_C_ZC_All, up_Profile_pnts_C_ZC, up_Profile_pnts_C_C_All, up_Profile_pnts_C_C  
	Wave Profile_C_maxUp, maxHeight, maxHeight_All
	Wave ScreenPosZ, currLeftUp, currRightUp, currTopUp, currBotUp
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if (indexUp > 0)
				indexUp = indexUp - 1
				Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_C_AllUp,  Profile_pnts_CUp
				Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_z_AllUp,  Profile_pnts_zUp
				Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_All,  up_Profile_pnts_C
				Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_L_All,  up_Profile_pnts_C_L
				up_Profile_pnts_C_C[0][0] = up_Profile_pnts_C_C_All[0][indexUp]
				up_Profile_pnts_C_C[0][1] = up_Profile_pnts_C_C_All[1][indexUp]
				up_Profile_pnts_C_C[1][0] = up_Profile_pnts_C_C_All[2][indexUp]
				up_Profile_pnts_C_C[1][1] = up_Profile_pnts_C_C_All[3][indexUp]
				up_Profile_pnts_C_ZC[0][0] = up_Profile_pnts_C_ZC_All[0][indexUp]
				up_Profile_pnts_C_ZC[0][1] = up_Profile_pnts_C_ZC_All[1][indexUp]
				up_Profile_pnts_C_ZC[1][0] = up_Profile_pnts_C_ZC_All[2][indexUp]
				up_Profile_pnts_C_ZC[1][1] = up_Profile_pnts_C_ZC_All[3][indexUp]
				up_Profile_pnts_C_Z[0][0] = up_Profile_pnts_C_Z_All[0][indexUp]
				up_Profile_pnts_C_Z[0][1] = up_Profile_pnts_C_Z_All[1][indexUp]
				up_Profile_pnts_C_Z[1][0] = up_Profile_pnts_C_Z_All[2][indexUp]
				up_Profile_pnts_C_Z[1][1] = up_Profile_pnts_C_Z_All[3][indexUp]	
				maxHeight[0][0] = maxHeight_All[0][indexUp]
				maxHeight[0][1] = maxHeight_All[1][indexUp]
				maxHeight[1][0] = maxHeight_All[2][indexUp]
				maxHeight[1][1] = maxHeight_All[3][indexUp]	
				maxC = Profile_C_maxUp[indexUp]
				TextBox/K/N=text1
				TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*indexUp) + " m"
				SetAxis bottom 0, maxC		
				
				Variable uref, zref
				Wave ScreenU
				NVAR dz
				Variable zi = dimSize(ScreenU,1) - 1
				Variable ztop = zi*dz
				do
					uref = ScreenU[indexUp][zi]
					zi -= 1
				while(numtype(uref)!=0 && zi>0)
				zref = (zi + 2)*dz				
				
				currLeftUp[][0] = indexUp*ds
				currLeftUp[0][1] = heightUp - (ztop - zref)
				currLeftUp[1][1] = extrapH
				
				currRightUp[][0] = indexUp*ds + ds
				currRightUp[0][1] = heightUp - (ztop - zref)
				currRightUp[1][1] = extrapH
				
				currTopUp[0][0] = indexUp*ds
				currTopUp[1][0] = indexUp*ds + ds
				currTopUp[][1] = heightUp - (ztop - zref)
				
				currBotUp[0][0] = indexUp*ds
				currBotUp[1][0] = indexUp*ds + ds
				currBotUp[][1] = extrapH			
				
				SetAxis/W=GraphProfilesUp1 left heightUp - (ztop - zref),extrapH				
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose a profile to move to
Function ProfileVarUp(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	NVAR indexUp, maxC, ds, heightUp, extrapH
	Wave Profile_pnts_C_AllUp,  Profile_pnts_CUp, Profile_pnts_z_AllUp,  Profile_pnts_zUp, up_Profile_pnts_C_All,  up_Profile_pnts_C, up_Profile_pnts_C_L_All, up_Profile_pnts_C_L  
	Wave up_Profile_pnts_C_Z, up_Profile_pnts_C_Z_All, up_Profile_pnts_C_ZC_All, up_Profile_pnts_C_ZC, up_Profile_pnts_C_C_All, up_Profile_pnts_C_C  
	Wave Profile_C_maxUp, maxHeight, maxHeight_All
	Wave ScreenPosZ, currLeftUp, currRightUp, currTopUp, currBotUp
	Variable uref, zref, zi, ztop
	switch( sva.eventCode )
		case 1: // mouse up
			indexUp = sva.dval
			Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_C_AllUp,  Profile_pnts_CUp
			Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_z_AllUp,  Profile_pnts_zUp
			Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_All,  up_Profile_pnts_C
			Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_L_All,  up_Profile_pnts_C_L
			up_Profile_pnts_C_C[0][0] = up_Profile_pnts_C_C_All[0][indexUp]
			up_Profile_pnts_C_C[0][1] = up_Profile_pnts_C_C_All[1][indexUp]
			up_Profile_pnts_C_C[1][0] = up_Profile_pnts_C_C_All[2][indexUp]
			up_Profile_pnts_C_C[1][1] = up_Profile_pnts_C_C_All[3][indexUp]
			up_Profile_pnts_C_ZC[0][0] = up_Profile_pnts_C_ZC_All[0][indexUp]
			up_Profile_pnts_C_ZC[0][1] = up_Profile_pnts_C_ZC_All[1][indexUp]
			up_Profile_pnts_C_ZC[1][0] = up_Profile_pnts_C_ZC_All[2][indexUp]
			up_Profile_pnts_C_ZC[1][1] = up_Profile_pnts_C_ZC_All[3][indexUp]
			up_Profile_pnts_C_Z[0][0] = up_Profile_pnts_C_Z_All[0][indexUp]
			up_Profile_pnts_C_Z[0][1] = up_Profile_pnts_C_Z_All[1][indexUp]
			up_Profile_pnts_C_Z[1][0] = up_Profile_pnts_C_Z_All[2][indexUp]
			up_Profile_pnts_C_Z[1][1] = up_Profile_pnts_C_Z_All[3][indexUp]	
			maxHeight[0][0] = maxHeight_All[0][indexUp]
			maxHeight[0][1] = maxHeight_All[1][indexUp]
			maxHeight[1][0] = maxHeight_All[2][indexUp]
			maxHeight[1][1] = maxHeight_All[3][indexUp]	
			maxC = Profile_C_maxUp[indexUp]
			TextBox/K/N=text1
			TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*indexUp) + " m"
			SetAxis bottom 0, maxC	
			
			Wave ScreenU
			NVAR dz
			zi = dimSize(ScreenU,1) - 1
			ztop = zi*dz
			do
				uref = ScreenU[indexUp][zi]
				zi -= 1
			while(numtype(uref)!=0 && zi>0)
			zref = (zi + 2)*dz			
			
			currLeftUp[][0] = indexUp*ds
			currLeftUp[0][1] = heightUp - (ztop - zref)
			currLeftUp[1][1] = extrapH
			
			currRightUp[][0] = indexUp*ds + ds
			currRightUp[0][1] = heightUp - (ztop - zref)
			currRightUp[1][1] = extrapH
			
			currTopUp[0][0] = indexUp*ds
			currTopUp[1][0] = indexUp*ds + ds
			currTopUp[][1] = heightUp - (ztop - zref)
			
			currBotUp[0][0] = indexUp*ds
			currBotUp[1][0] = indexUp*ds + ds
			currBotUp[][1] = extrapH	
			
			SetAxis/W=GraphProfilesUp1 left heightUp - (ztop - zref),extrapH		
		case 2: // Enter key
			indexUp = sva.dval
			Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_C_AllUp,  Profile_pnts_CUp
			Duplicate/O/R=(0, 1100)(indexUp,indexUp)  Profile_pnts_z_AllUp,  Profile_pnts_zUp
			Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_All,  up_Profile_pnts_C
			Duplicate/O/R=(0, extrapH)(indexUp,indexUp)  up_Profile_pnts_C_L_All,  up_Profile_pnts_C_L
			up_Profile_pnts_C_C[0][0] = up_Profile_pnts_C_C_All[0][indexUp]
			up_Profile_pnts_C_C[0][1] = up_Profile_pnts_C_C_All[1][indexUp]
			up_Profile_pnts_C_C[1][0] = up_Profile_pnts_C_C_All[2][indexUp]
			up_Profile_pnts_C_C[1][1] = up_Profile_pnts_C_C_All[3][indexUp]
			up_Profile_pnts_C_ZC[0][0] = up_Profile_pnts_C_ZC_All[0][indexUp]
			up_Profile_pnts_C_ZC[0][1] = up_Profile_pnts_C_ZC_All[1][indexUp]
			up_Profile_pnts_C_ZC[1][0] = up_Profile_pnts_C_ZC_All[2][indexUp]
			up_Profile_pnts_C_ZC[1][1] = up_Profile_pnts_C_ZC_All[3][indexUp]
			up_Profile_pnts_C_Z[0][0] = up_Profile_pnts_C_Z_All[0][indexUp]
			up_Profile_pnts_C_Z[0][1] = up_Profile_pnts_C_Z_All[1][indexUp]
			up_Profile_pnts_C_Z[1][0] = up_Profile_pnts_C_Z_All[2][indexUp]
			up_Profile_pnts_C_Z[1][1] = up_Profile_pnts_C_Z_All[3][indexUp]	
			maxHeight[0][0] = maxHeight_All[0][indexUp]
			maxHeight[0][1] = maxHeight_All[1][indexUp]
			maxHeight[1][0] = maxHeight_All[2][indexUp]
			maxHeight[1][1] = maxHeight_All[3][indexUp]	
			maxC = Profile_C_maxUp[indexUp]
			TextBox/K/N=text1
			TextBox/C/N=text1/F=0/M/A=MC/X=-45.42/Y=-81.18 "s =" + num2str(ds*indexUp) + " m"
			SetAxis bottom 0, maxC	
			
			Wave ScreenU
			NVAR dz
			zi = dimSize(ScreenU,1) - 1
			ztop = zi*dz
			do
				uref = ScreenU[indexUp][zi]
				zi -= 1
			while(numtype(uref)!=0 && zi>0)
			zref = (zi + 2)*dz
			
			currLeftUp[][0] = indexUp*ds
			currLeftUp[0][1] = heightUp - (ztop - zref)
			currLeftUp[1][1] = extrapH
			
			currRightUp[][0] = indexUp*ds + ds
			currRightUp[0][1] = heightUp - (ztop - zref)
			currRightUp[1][1] = extrapH
			
			currTopUp[0][0] = indexUp*ds
			currTopUp[1][0] = indexUp*ds + ds
			currTopUp[][1] = heightUp - (ztop - zref)
			
			currBotUp[0][0] = indexUp*ds
			currBotUp[1][0] = indexUp*ds + ds
			currBotUp[][1] = extrapH	
			
			SetAxis/W=GraphProfilesUp1 left heightUp - (ztop - zref),extrapH		
		case 3: // Live update
			indexUp = sva.dval
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Choose a new height to be used for fitting profiles
Function NewHeightUp(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	NVAR heightUp
	switch( sva.eventCode )
		case 1: // mouse up
			heightUp = sva.dval
		case 2: // Enter key
			heightUp = sva.dval
		case 3: // Live update
			heightUp = sva.dval
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Rerun the fits with a new height
Function RerunFitsUp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR heightUp, heightDownFromTop, nz
	switch( ba.eventCode )
		case 2: // mouse up
			heightUp = nz - heightDownFromTop
			UnfillUp()
			ProfilesExpUp(heightDownFromTop)
			ProfilesLineUp(heightDownFromTop)
		//	UnfillUp()
			FillUp()
			CompareBaselinesUp()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Unfill the screen above the flight path
Function UnfillUp()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref
	variable/g ds, dz, ns, nz
	variable/g bg
	wave ScreenPosZ
	nvar background
	
	wave ScreenU
	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots

	// ** Removal of points below lowest flight height **
	make/o/n=(ns/ds,nz/dz) ScreenTemp=0

	duplicate/o ScreenU, ScreenTempu

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

  
	duplicate/o ScreenTempu, ScreenU

	killwaves/Z ScreenTemp, ScreenTempu
	
End

Function FillUp()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref, ztop
	variable/g ds, dz, ns, nz
	variable/g bg
	NVAR extrapH
	variable c1, c2, c3
	wave ScreenU
	wave ScreenPosZ
	wave FitaUp, FitbUp, FitR2Up
	wave FitExpAUp, FitExpBUp, FitExpR2Up
	nvar background
	Wave ScreenWindNf, ScreenWindEf, ScreenAirf
	
	wave ScreenKrig
	wave PositionSZC

	width = 10  // Averaging width for connecting flight dots
	
	Duplicate/O ScreenU, Screenf0Up, ScreenfcUp, Screenf0cUp, ScreenflUp, ScreenfeUp
	
	Variable matrixSize = extrapH/dz - dimSize(ScreenU,1)
	
	for (i = 0; i < matrixSize+1; i += 1)
		InsertPoints/M=1 dimSize(ScreenU,1), 1, Screenf0Up, ScreenfcUp, Screenf0cUp, ScreenflUp, ScreenfeUp
//		InsertPoints/M=1 dimSize(ScreenU,1), 1, ScreenWindNf, ScreenWindEf, ScreenAirf
//		ScreenWindNf[][dimSize(ScreenU,1)] = NaN
//		ScreenWindEf[][dimSize(ScreenU,1)] = NaN
//		ScreenAirf[][dimSize(ScreenU,1)] = NaN
	endfor
	

  // Vertical Fill at Top and Bottom
	for(s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zi = dimSize(ScreenU,1) - 1
		ztop = (dimSize(ScreenU,1)-1)*dz
		
    // Find highest data point
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi + 2)*dz
		
    // Apply extrapolated data above highest data 
		for(z=zref; z<=extrapH; z+=dz)
			zi = floor(z/dz)
			Screenf0Up[si][zi] = background
			ScreenfcUp[si][zi] = uref
//			Screenf0c[si][zi] = (z - zsur)/zref*uref
			Screenf0cUp[si][zi] = (background - uref)/(extrapH - zref)*(z - extrapH) + background
		endfor

	endfor

  // ** Filling of points at sides and below **

  // Vertical Fill at Top and Bottom
	for (s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zi = dimSize(ScreenU,1) - 1
		ztop = (dimSize(ScreenU,1)-1)*dz
		
    // Find highest data point
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi + 2)*dz

    // Apply extrapolated data above highest data  
		for(z=zref; z<=extrapH; z+=dz)
			zi = floor(z/dz)
			if (numtype(FitaUp[si]) == 0)
				ScreenflUp[si][zi] = FitaUp[si] + FitbUp[si]*(z)
			else
				ScreenflUp[si][zi] = uref
			endif
			if (numtype(FitExpR2Up[si])==0)
				ScreenfeUp[si][zi] = bg + FitExpAUp[si]*exp(-((extrapH-z)/FitExpBUp[si])^2)
			else
				ScreenfeUp[si][zi] = uref
				c1 += 1
				if (s>26000 && s<38000)
					c2 += 1
				endif
			endif
			c3 += 1
		endfor

	endfor
  
End

function CompareBaselinesUp()

	variable w, si, zi
	variable/g ds, dz, ns, nz
	variable/g bg
	NVAR extrapH
	wave ScreenfcUp, ScreenflUp, ScreenfeUp, Screenf0Up, Screenf0cUp
  
	make/o/n=(floor(ns/ds),5) BaseUp
	setscale/p x, 0, ds, BaseUp
  
	for (w=0; w<5; w+=1)

		if (w==0)
			duplicate/o ScreenfcUp, ScreenTemp
		elseif (w==1)
			duplicate/o ScreenflUp, ScreenTemp
		elseif (w==2)
			duplicate/o ScreenfeUp, ScreenTemp
		elseif (w==3)
			duplicate/o Screenf0Up, ScreenTemp
		else
			duplicate/o Screenf0cUp, ScreenTemp
		endif
  
		for (si=0; si<floor(ns/ds); si+=1)
			if (si >= dimSize(ScreenTemp,0))
				break
			endif
			zi = dimSize(ScreenTemp,1) - 1
			BaseUp[si][w] = ScreenTemp[si][zi] //- bg
		endfor

	endfor

End

Function SaveProfUp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable csrA, csrB, fitType, i
	Wave/T Fit_FlagUp
	Wave UserBaseUp
	Wave BaseUp
	String flag
	Variable basenum

	switch( ba.eventCode )
		case 2: // mouse up
			csrA = pcsr(A)
			csrB = pcsr(B)
			Prompt fitType, "Which fit do you want to use in this region? ", popup, "Constant;Linear Between Constant and Background;Background Above Flight;Linear Fit;Exponential Fit"
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
					Fit_FlagUp[i] = flag
					UserBaseUp[i] = BaseUp[i][basenum]
				endfor
			else
				for (i = csrB; i < csrA; i += 1)
					Fit_FlagUp[i] = flag
					UserBaseUp[i] = BaseUp[i][basenum]
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
Function DoneProfUp(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave/T Fit_FlagUp
	NVAR nz, bg, totLat, totTop, Mc, units, massEm, heightUp, extrapH
	Wave labelLoc, Frame, totalAirF, totalAirFM
	SVAR unitStr
	Wave PositionSZC, ScreenU
	String graphlist
	
	Variable num = dimSize(Fit_FlagUp,0)
	Variable i
	switch( ba.eventCode )
		case 2: // mouse up
			for (i = 0; i < num; i += 1)
				if (strlen(Fit_FlagUp[i]) == 0)
					Fit_FlagUp[i] = "C"
				endif
			endfor
			FillFinalUp()
			Wave ScreenU_Up
			if (exists("ScreenU_original") == 0)
				Duplicate/O ScreenU, ScreenU_original
			endif
			
			Duplicate/O ScreenU_Up, ScreenU
			if (CmpStr(unitStr,"ug/m^3") == 0)
				Wave ScreenU_ugm3, ScreenU_ppb
				Duplicate/O ScreenU_ugm3, ScreenU_ugm3_original
				Duplicate/O ScreenU_Up, ScreenU_ugm3
				Duplicate/O ScreenU_ppb, ScreenU
				String wlist = WinList("GraphProfilesUp1", ";", "")
				if (strlen(wlist) > 0)
					KillWindow GraphProfilesUp1
				endif
				ProfilesLineUp (heightUp)
				ProfilesExpUp (heightUp)
				FillFinalUp()
				Duplicate/O ScreenU_ppb, ScreenU_ppb_original
				Duplicate/O ScreenU_Up, ScreenU_ppb
				
				Duplicate/O ScreenU_ugm3, ScreenU
				ProfilesLineUp (heightUp)
				ProfilesExpUp (heightUp)
				Execute "GraphProfilesUp()"
				DoWindow/C GraphProfilesUp1
			endif
			nz = extrapH
			TopValue()
			
			graphlist = WinList("GraphProfilesUp1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow GraphProfilesUp1
			endif
			graphlist = WinList("GraphSurfaceUp1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow GraphSurfaceUp1
			endif			
			
			SetAxis/W=GraphSurface1 left 0,nz
		
//			recordHistory()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Accept profile choices and create final screen plus flux calculation
Function DoneProfUpScreen(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Wave/T Fit_FlagUp
	NVAR nz, bg, totLat, Mc, units
	Wave totalAirF
	SVAR unitStr
	Wave PositionSZC, ScreenU
	String graphlist
	NVAR heightUp, extrapH
	
	Variable num = dimSize(Fit_FlagUp,0)
	Variable i
	switch( ba.eventCode )
		case 2: // mouse up
			for (i = 0; i < num; i += 1)
				if (strlen(Fit_FlagUp[i]) == 0)
					Fit_FlagUp[i] = "C"
				endif
			endfor
			FillFinalUp()
			Wave ScreenU_Up
			if (exists("ScreenU_original") == 0)
				Duplicate/O ScreenU, ScreenU_original
			endif
			
			Duplicate/O ScreenU_Up, ScreenU
			if (CmpStr(unitStr,"ug/m^3") == 0)
				Wave ScreenU_ugm3, ScreenU_ppb
				Duplicate/O ScreenU_ugm3, ScreenU_ugm3_original
				Duplicate/O ScreenU_Up, ScreenU_ugm3
				Duplicate/O ScreenU_ppb, ScreenU
				String wlist = WinList("GraphProfilesUp1", ";", "")
				if (strlen(wlist) > 0)
					KillWindow GraphProfilesUp1
				endif
				ProfilesLineUp (heightUp)
				ProfilesExpUp (heightUp)
				FillFinalUp()
				Duplicate/O ScreenU_ppb, ScreenU_ppb_original
				Duplicate/O ScreenU_Up, ScreenU_ppb
				
				Duplicate/O ScreenU_ugm3, ScreenU
				ProfilesLineUp (heightUp)
				ProfilesExpUp (heightUp)
				Execute "GraphProfilesUp()"
				DoWindow/C GraphProfilesUp1
			endif
			nz = extrapH
			TopValue()
			
			graphlist = WinList("GraphProfilesUp1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow GraphProfilesUp1
			endif
			graphlist = WinList("GraphSurfaceUp1", ";", "")
			if (strlen(graphlist) > 0)
				KillWindow GraphSurfaceUp1
			endif			
			
			SetAxis/W=GraphSurface1 left 0,nz
		
//			recordHistory()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function FillFinalUp()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref, ztop
	variable/g ds, dz, ns, nz
	variable/g bg
	variable c1, c2, c3
	wave ScreenU
	wave ScreenPosZ
	wave FitaUp, FitbUp, FitR2Up
	wave FitExpAUp, FitExpBUp, FitExpR2Up
	nvar background, extrapH
	Wave/T Fit_FlagUp

  // ** Filling of points at sides and below **
	duplicate/o ScreenU, ScreenU_Up
	
	Variable matrixSize = extrapH/dz - dimSize(ScreenU,1)
	
	for (i = 0; i < matrixSize+1; i += 1)
		InsertPoints/M=1 dimSize(ScreenU,1), 1, ScreenU_Up
	endfor

  // Vertical Fill at Top and Bottom
	for(s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		zi = dimSize(ScreenU,1) - 1
		ztop = (dimSize(ScreenU,1)-1)*dz
		
    // Find highest data point
		if (si >= dimSize(ScreenU,0))
			break
		endif
		do
			uref = ScreenU[si][zi]
			zi -= 1
		while(numtype(uref)!=0 && zi>0)
		zref = (zi+2)*dz

    // Apply extrapolated data above highest data 
		for(z=zref; z<=extrapH; z+=dz)
			zi = floor(z/dz)
			if (CmpStr(Fit_FlagUp[si], "Z") == 0)
				ScreenU_Up[si][zi] = background
			elseif (CmpStr(Fit_FlagUp[si], "ZC") == 0)
				ScreenU_Up[si][zi] = (background - uref)/(extrapH - zref)*(z - extrapH) + background
			elseif (CmpStr(Fit_FlagUp[si], "C") == 0)
				ScreenU_Up[si][zi] = uref
			elseif (CmpStr(Fit_FlagUp[si], "L") == 0)
				if (numtype(FitaUp[si]) == 0)
					ScreenU_Up[si][zi] = FitaUp[si] + FitbUp[si]*(z-zsur)
				else
					ScreenU_Up[si][zi] = uref
				endif
			else
				if (numtype(FitExpR2Up[si])==0)
					ScreenU_Up[si][zi] = bg + FitExpAUp[si]*exp(-((extrapH-z)/FitExpBUp[si])^2)
				else
					ScreenU_Up[si][zi] = uref
				endif
			endif
		endfor

	endfor

	killwaves/z ScreenTemp
//  print c1, c2, c3
  
End


Function ExpxUp(w,x) : FitFunc
	Wave w
	Variable x
	NVAR extrapH

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Cbg + A*exp(-((2000-x)/B)^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = Cbg
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = B

	return w[0] + w[1]*exp(-((extrapH-x)/w[2])^2)
End

//Function WindProfile(w,z) : FitFunc
//	Wave w
//	Variable z
//
//	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
//	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
//	//CurveFitDialog/ Equation:
//	//CurveFitDialog/ f(z) = ustar/0.4*ln(z - d) + f
//	//CurveFitDialog/ End of Equation
//	//CurveFitDialog/ Independent Variables 1
//	//CurveFitDialog/ z
//	//CurveFitDialog/ Coefficients 3
//	//CurveFitDialog/ w[0] = d
//	//CurveFitDialog/ w[1] = ustar
//	//CurveFitDialog/ w[2] = f
//
//	return w[1]/0.4*ln(z + w[0]) + w[2]
//End

Function FillWindUp()
	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff
	variable w, width, nans, zref, sref, d, f, ustar, uref, zsur, ztop
	variable/g ds, dz, ns, nz
	wave ScreenWindNf, ScreenWindEf
	wave ScreenPosZ
	Wave fitaWUp, fitbWUp, fitdWUp
	NVAR extrapH

	width = 10  // Averaging width for connecting flight dots

	// Wind Profile fit parameters: U = u*/k ln(z - d) + f
	// (See C:\Comp\Oilsands\OS_Airborne\Data\Winds)
	d = fitdWUp[0]
	f = fitaWUp[0]
	
	Variable matrixSize = extrapH/dz - dimSize(ScreenWindNf,1)
	Duplicate/O ScreenWindNf, ScreenWindNf_Up
	Duplicate/O ScreenWindEf, ScreenWindEf_Up
	
	for (i = 0; i < matrixSize+1; i += 1)
		InsertPoints/M=1 dimSize(ScreenWindNf,1), 1, ScreenWindNf_Up, ScreenWindEf_Up
	endfor

	for(w=0; w<2; w+=1)

		if(w==0)
			Wave ScreenWind = ScreenWindNf_Up
		else
			Wave ScreenWind = ScreenWindEf_Up
		endif

		// Vertical Fill at Top
		for(s=0; s<floor(ns/ds)*ds; s+=ds)
			si = floor(s/ds)
			if (si >= dimSize(ScreenWindNf,0))
				break
			endif
			zsur = ScreenPosZ[s/2]

			ztop = dz*dimSize(ScreenWindNf,1)
			zref = ztop - zsur
			uref = ScreenWind[si][dimSize(ScreenWindNf,1) - 1]
			ustar = (uref - f)*0.4/ln(zref-d)

			// Apply log-profile above highest data 
			for(z=ztop; z<=extrapH; z+=dz)
				zi = floor(z/dz)
				ScreenWind[si][zi] = ustar/0.4*ln((z-zsur)-d) + f
			endfor

		endfor

	endfor
  
End

Function FillAirUp()

	variable i, np, s, z, si, zi
	variable si_l, si_r, si_diff, sref
	variable width, nans, a, b, uref, zsur, zref, ztop
	variable/g ds, dz, ns, nz
	wave ScreenAirf
	//  wave ScreenAiru
	wave PositionSZA
	wave ScreenPosZ
	NVAR fitaAUp, fitbAUp, extrapH

	width = 10  // Averaging width for connecting flight dots

	// Air density profile fit parameters: rho = a + b z
	a = fitaAUp
	b = fitbAUp
	
	Variable matrixSize = extrapH/dz - dimSize(ScreenAirf,1)
	Duplicate/O ScreenAirf, ScreenAirf_Up
	
	for (i = 0; i < matrixSize+1; i += 1)
		InsertPoints/M=1 dimSize(ScreenAirf,1), 1, ScreenAirf_Up
	endfor

	// Vertical Fill at Top
	for(s=0; s<floor(ns/ds)*ds; s+=ds)
		si = floor(s/ds)
		if (si >= dimSize(ScreenAirf,0))
			break
		endif
		zsur = ScreenPosZ[s/2]

		ztop = dz*dimSize(ScreenAirf,1)
		zref = ztop - zsur

		// Apply linear profile below lowest data 
		for(z=ztop; z<=extrapH; z+=dz)
			zi = floor(z/dz)
			ScreenAirf_Up[si][zi] = a + b*(floor(z/dz)+0.5)*dz
		endfor

	endfor
  
End

Function highAltWS()
	Wave WindSpeed
	NVAR nz, extrapH
	Variable i
	Variable count = 0
	
	if (exists("Height_m") == 1)
		Wave Height_m
	else
		Wave Height_m = Alt
	endif

	Make/O/N=(dimSize(Height_m,0)) HighAlt, HighAlt_WS = NaN
	
	for (i = 0; i < dimSize(HighAlt,0); i += 1)
		if (Height_m[i] > nz && Height_m[i] <= extrapH)
			HighAlt[count] = Height_m[i]
			HighAlt_WS[count] = WindSpeed[i]
			count = count + 1
		endif
	endfor		
	
	DeletePoints count, dimSize(Height_m,0), HighAlt, HighAlt_WS
	
End

//Function binAlt()
//	Wave Alt = Alt_F15
//	Wave WS = WS_F15
//	Variable i, j
//	Variable binSize = 10
//	
//	Make/O/N=(1000/binSize) avgWS = 0
//	Make/O/N=(1000/binSize) numWS = 0
//	
////	for (i = 0; i < dimSize(Alt,0); i += 1)
//	for (i = 0; i < 120; i += 1)
//		for (j = 0; j < dimSize(avgWS,0); j += 1)
//			if (round(Alt[i]/binSize)*binSize > binSize*j && round(Alt[i]/binSize)*binSize <= binSize*(j + 1))
//				if (numtype(WS[i]) == 0)
//					avgWS[j] = avgWS[j] + WS[i]
//					numWS[j] = numWS[j] + 1
//				endif
//			endif
//		endfor
//	endfor	
//	
//	for (j = 0; j < dimSize(avgWS,0); j += 1)
//		if (avgWS[j] == 0)
//			avgWS[j] = NaN
//		endif
//	endfor
//	
//	avgWS = avgWS/numWS
//	setscale/p x, -320, binSize, avgWS
//	
//End

//Function checkCoef()
//	Variable f = -2.5
//	Variable ustar = 0.6
//	Variable d = exp(-0.4*f/ustar)
//	
//	Variable z = exp(-0.4*f/ustar) - d
//
//	Print d, z
//
//End

Function FitProfiles_Flight()

	// u = u*/k (ln(z/zo) - Phi)

	variable w, i, np, z, nz
	variable sx, sy, sxx, sxy, syy, n
	variable t1, t2, z1, z2
	variable a, b, height
	variable d, rms, rms_min
	wave WS = HighAlt_WS
	wave Alt = HighAlt
//	wave TimeMST = datetime_F15
	Wave WindSpeed
//	Wave T_Takeoff, T_Landing
	NVAR extrapH
  
	nz = dimsize(WS,0)
  
	make/o/n=(1) fitaWUp=nan, fitbWUp=nan, fitdWUp=nan, fitrmsWUp
	make/o/n=(extrapH,1) ProfileFitWUp
  
	make/o/n=(2000,1) rms_tempWUp
	setscale/p x, 0, 0.01, rms_tempWUp
  
//	for(w=0; w<15; w+=1)
	w = 0
//		z1 = 0
//		z2 = 17

		rms_min = 9e99  
		for(d=0; d<20; d+=0.01)
    
			sx = 0;  sy = 0;  sxx = 0;  sxy = 0;  syy = 0;  n = 0; 
			sx = ln(d); sxx = ln(d)^2; n = 1
			for(z=0; z<dimSize(WS,0); z+=1)
				height = Alt[z]
				if(numtype(WS[z])==0)
					sx += ln(height)
					sy += WS[z]
					sxx += ln(height)^2
					sxy += ln(height)*WS[z]
					syy += WS[z]^2
				endif
			endfor
			fitbWUp[w] = (n*sxy-sx*sy)/(n*sxx-sx*sx)
			fitaWUp[w] = sy/n - fitbWUp[w]*sx/n

			rms = 0
			n = 0
			for(z=0; z<dimSize(WS,0); z+=1)
				height = Alt[z]
				if(numtype(WS[z])==0)
					rms += (fitbWUp[w]*ln(height) + fitaWUp[w] - WS[z])^2
					n += 1
				endif
			endfor

			if(rms<rms_min)
				rms_min = rms
				fitdWUp[w] = d
			endif
  
			rms_tempWUp[d*100][w] = rms
    
		endfor

		sx = 0;  sy = 0;  sxx = 0;  sxy = 0;  syy = 0;  n = 1; 
		sx = ln(fitdWUp[w]); sxx = ln(fitdWUp[w])^2; n = 1
		for(z=0; z<dimSize(WS,0); z+=1)
			height = Alt[z]
			if(numtype(WS[z])==0)
				sx += ln(height)
				sy += WS[z]
				sxx += ln(height)^2
				sxy += ln(height)*WS[z]
				syy += WS[z]^2
				n += 1
			endif
		endfor
		fitbWUp[w] = (n*sxy-sx*sy)/(n*sxx-sx*sx)
		fitaWUp[w] = sy/n - fitbWUp[w]*sx/n
		ProfileFitWUp[*][w] = fitbWUp[w]*ln(x-fitdWUp[w]) + fitaWUp[w]

//		if(w==0)
//			t1 = Date2secs(2013,08,20) + 9*3600 + 58*60
//			t2 = Date2secs(2013,08,20) + 13*3600 + 34*60
//		else
//			t1 = Date2secs(2013,09,02) + 11*3600 + 18*60
//			t2 = Date2secs(2013,09,02) + 14*3600 + 43*60
//		endif

//		t1 = T_Takeoff[w]
//		t2 = T_Landing[w]

		fitrmsWUp[w] = 0
		n = 0
		for(i=0; i<np; i+=1)
//			if(TimeMST[i]>=t1 && TimeMST[i]<t2)
			for(z=0; z<dimSize(WS,0); z+=1)
				height = Alt[z]
			//		fitrmsF16[w] += (fitbF16[w]*ln(height) + fitaF16[w] - WindSpeed[i][z])^2
				n += 1
			endfor
//			endif
		endfor

		fitrmsWUp[w] /= n

//	endfor

End

Function fitAir()
	Wave PositionSZA
	
	CurveFit/M=2/W=0/Q line, PositionSZA[*][2]/X=PositionSZA[*][1]/D
	Wave W_coef
	
	Variable/G fitaAUp = W_coef[0]
	Variable/G fitbAUp = W_coef[1]

End

Function AirFluxCalc()
	Variable nsi, nzi
	variable/g ds, dz, Total
	variable s, z
	variable ux, uy, vx, vy, ws, zsur
	variable avg, rms, tot_in, tot_out
	wave ScreenWindNf, ScreenWindEf
	wave ScreenAirf
	wave ScreenPosXY, ScreenPosZ

	Total = 0
	
	nsi = dimsize(ScreenWindNf,0)
	nzi = dimsize(ScreenWindNf,1)

	make/o/n=(nsi,nzi) ScreenAirFlux
	Wave ScreenFlux = ScreenAirFlux
	make/o/n=(nsi) ScreenFlux_s
	make/o/n=(nzi) ScreenFlux_z, ScreenFlux_zc
	setscale/p x, 0, ds, ScreenFlux, ScreenFlux_s
	setscale/p y, 0, dz, ScreenFlux
	setscale/p x, 0, ds, ScreenFlux_z
	ScreenFlux_s = 0
	ScreenFlux_z = 0
	ScreenFlux_zc = 0

	for(s=0; s<nsi-1; s+=1)
		zsur = ScreenPosZ[s*ds]/dz
		for(z=0; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if(s==0 || s==nsi-1)
				ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi*ds-5][1]) // Lat Difference
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
				ScreenFlux_z[floor(z-zsur)] += ScreenFlux[s][z]
				ScreenFlux_zc[floor(z-zsur)] += 1
				Total += (ScreenFlux[s][z]*ds*dz) // kg/s
			endif
		endfor
	endfor
	
	ScreenFlux_s *= dz // kg/m/s
	ScreenFlux_z *= ds*abs(ScreenFlux_zc)/ScreenFlux_zc // kg/m/s
  
	make/o/n=2 ScreenFlux_s_avg
	setscale/p x, 0, nsi*ds, ScreenFlux_s_avg
	avg = 0; rms = 0; tot_in = 0; tot_out = 0
	for(s=0; s<nsi; s+=1)
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
	for(s=0; s<nsi; s+=1)
		for(z=0; z<nzi; z+=1)
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