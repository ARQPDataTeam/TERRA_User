#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//#include "KrigData" 

Function mapEdgeImage(su)
	Wave su
	Variable i, j
	
	ImageEdgeDetection/M=1/S=1 frei su
	Wave im = M_ImageEdges
	
	Duplicate/O im, Edges_col
	
	WaveStats/Q su
	Variable/G maxConc = V_max
	Variable/G minConc = V_min
	
	for (i = 0; i < dimSize(im, 0); i += 1)
		for (j = 0; j < dimSize(im, 1); j += 1)
			if (im[i][j] == 255)
				Edges_col[i][j] = su[i][j]
			else
				Edges_col[i][j] = NaN
			endif
		endfor
	endfor

End

Function selectEdgeImage()
	Wave im = Edges_col
	Variable i, j
	Variable ds = dimDelta(im,0)
	Variable dz = dimDelta(im,1)
	Variable sOff = dimOffset(im,0)
	Variable zOff = dimOffset(im,1)
	
	GetMarquee left, bottom
	
	for (i = 0; i < dimSize(im, 0); i += 1)
		for (j = 0; j < dimSize(im, 1); j += 1)
			if (sOff + i*ds >= V_left && sOff + i*ds <= V_right)
				if (zOff + j*dz >= V_bottom && zOff + j*dz <= V_top)
					im[i][j] = NaN
				endif
			endif
		endfor
	endfor

End

Function removeEdgeImage(su)
	Wave su
	Wave im = Edges_col
	Variable i, j
	Variable ds = dimDelta(im,0)
	Variable dz = dimDelta(im,1)
	Variable sOff = dimOffset(im,0)
	Variable zOff = dimOffset(im,1)
	
	GetMarquee left, bottom
	
	for (i = 0; i < dimSize(im, 0); i += 1)
		for (j = 0; j < dimSize(im, 1); j += 1)
			if (sOff + i*ds >= V_left && sOff + i*ds <= V_right)
				if (zOff + j*dz >= V_bottom && zOff + j*dz <= V_top)
					im[i][j] = su[i][j]
				endif
			endif
		endfor
	endfor

End

Function fillEdgeImage(su)
	Wave su
	Wave im = Edges_col
	Variable i, j
	Variable c, d, edge, lval, rval, tval, bval
	Variable ds = dimDelta(im,0)
	Variable dz = dimDelta(im,1)
	Variable sOff = dimOffset(im,0)
	Variable zOff = dimOffset(im,1)
		
	for (i = 0; i < dimSize(im, 0); i += 1)
		for (j = 0; j < dimSize(im, 1); j += 1)
			edge = 1
			if (numtype(im[i][j]) == 0)
				c = i
				do 
					c = c + 1
					if (c >= dimSize(im,0))
						edge = 0
						break
					endif
				while (numtype(im[c][j]) == 0)
				rval = su[c-1][j]
				c = i
				do 
					c = c - 1
					if (c <= 0)
						edge = 0
						break
					endif
				while (numtype(im[c][j]) == 0)
				lval = su[c+1][j]
				d = j
				do 
					d = d + 1
					if (d >= dimSize(im,1))
						edge = 0
						break
					endif
				while (numtype(im[i][d]) == 0)
				tval = su[i][d-1]
				d = j
				do 
					d = d - 1
					if (d <= 0)
						edge = 0
						break
					endif
				while (numtype(im[i][d]) == 0)
				bval = su[i][d+1]
				
				if (edge == 1)
					if (im[i][j] >= rval && im[i][j] >= lval && im[i][j] >= tval && im[i][j] >= bval)
						im[i][j] = NaN
					endif
				endif
		
//			if (sOff + i*ds >= V_left && sOff + i*ds <= V_right)
//				if (zOff + j*dz >= V_bottom && zOff + j*dz <= V_top)
//					im[i][j] = NaN
//				endif
			endif
		endfor
	endfor	

End

Function FluxCalcPlume(sst, zst, send, zend, ScreenWv)
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

	make/o/n=(nsi,nzi) ScreenFlux
	make/o/n=(nsi) ScreenFlux_s
	make/o/n=(nzi) ScreenFlux_z, ScreenFlux_zc
	setscale/p x, 0, ds, ScreenFlux, ScreenFlux_s
	setscale/p y, 0, dz, ScreenFlux
	setscale/p x, 0, ds, ScreenFlux_z
	ScreenFlux_s = 0
	ScreenFlux_z = 0
	ScreenFlux_zc = 0

	for (s=ns; s<nsi - 1; s+=1)
		zsur = ScreenPosZ[s/2*ds]/dz
		for (z=nz; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if (s==0 || s==nsi-1)
				ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi/2*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi/2*ds-5][1]) // Lat Difference
			else
				ux = (ScreenPosXY[s/2*ds+5][0] - ScreenPosXY[s/2*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s/2*ds+5][1] - ScreenPosXY[s/2*ds-5][1]) // Lat Difference
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
			
		endfor
	endfor

	ScreenFlux_s *= (dz*3600) // kg/m/Hr
	ScreenFlux_z *= (ds*3600)*abs(ScreenFlux_zc)/ScreenFlux_zc // kg/m/Hr
	
	NVAR totLat
	totLat = Total*3600		//kg/Hr

	print " "
	print "Total lateral emission rate is ", abs(totLat), "kg/Hr ", abs(totLat*24/1000), "T/d"
  
	ScreenFlux *= 10^(units) //ug/m2/s
  
End 

Window GraphPlume() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(316.5,95.75,1179.75,557) ScreenPosZ
	AppendToGraph Frame[*][1] vs Frame[*][0]
	AppendImage ScreenU
	ModifyImage ScreenU ctab= {*,*,Rainbow,1}
	AppendImage Edges_col
	ModifyImage Edges_col ctab= {minConc,maxConc,Grays,1}
	ModifyGraph mode(ScreenPosZ)=7,mode(Frame)=1
	ModifyGraph rgb(ScreenPosZ)=(34816,34816,34816),rgb(Frame)=(0,0,0)
	ModifyGraph hbFill(ScreenPosZ)=2
	ModifyGraph mirror=0
	SetAxis left 0,nz
	ControlBar/R 120
	PopupMenu popup0,pos={1042,48},value="Unfilled Screen;Filled Screen",proc=PopupChooseScreen,fSize=12,font="Arial"
	Button button0,pos={1042,100},size={100,50},proc=ButtonResetPlume,title="Reset Plume"
	Button button1,pos={1042,155},size={100,50},proc=ButtonFillPlume,title="Fill Plume"
	Button button2,pos={1042,210},size={100,50},proc=ButtonAddPlume,title="Add Section\r to Plume"
	Button button3,pos={1042,265},size={100,50},proc=ButtonRemovePlume,title="Remove Section\r from Plume"
	Button button4,pos={1042,400},size={100,50},proc=ButtonEmisPlume,title="Obtain Plume\r Emission"
EndMacro

Function ButtonResetPlume(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo popup0
			if (V_value == 1)
				Wave ScreenU
				mapEdgeImage(ScreenU)
			else
				Wave ScreenF
				mapEdgeImage(ScreenF)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonFillPlume(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo popup0
			if (V_value == 1)
				Wave ScreenU
				fillEdgeImage(ScreenU)
			else
				Wave ScreenF
				fillEdgeImage(ScreenF)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonAddPlume(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			selectEdgeImage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonRemovePlume(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo popup0
			if (V_value == 1)
				Wave ScreenU
				removeEdgeImage(ScreenU)
			else
				Wave ScreenF
				removeEdgeImage(ScreenF)
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonEmisPlume(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	Wave Edges_col
	Variable i, j
	NVAR ns, nz

	switch( ba.eventCode )
		case 2: // mouse up
			ControlInfo popup0
			if (V_value == 1)
				Wave screen = ScreenU
			else
				Wave screen = ScreenF
			endif
			Duplicate/O screen, screenPlume
			for (i = 0; i < dimSize(screen,0); i += 1)
				for (j = 0; j < dimSize(screen,1); j += 1)
					if (numtype(Edges_col[i][j]) == 0)
						screenPlume[i][j]  = NaN
					endif
				endfor
			endfor
//			FluxCalcAir(0,0, ns, nz)
			FluxCalcPlume(0,0,ns,nz,screenPlume)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopupChooseScreen(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	NVAR displayScreen
	NVAR minConc, maxConc
	Wave Edges_col
	SVAR unitStr

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			if (popNum == 1 && displayScreen == 2)
				if (CmpStr(unitStr,"ug/m3") == 0)
					Wave ScreenU = ScreenU_ppb
				else
					Wave ScreenU
				endif
				mapEdgeImage(ScreenU)
				RemoveImage/W=GraphPlume ScreenF
				RemoveImage/W=GraphPlume Edges_col
				AppendImage/W=GraphPlume ScreenU
				AppendImage/W=GraphPlume Edges_col
				ModifyImage ScreenU ctab= {*,*,Rainbow,1}
				ModifyImage Edges_col ctab= {minConc,maxConc,Grays,1}
			elseif (popNum == 2 && displayScreen == 1)
				if (exists("ScreenF") == 0)
					Abort "You must fill the screen to the ground before choosing this option."
				else
					if (CmpStr(unitStr,"ug/m3") == 0)
						Wave ScreenF = ScreenF_ppb
					else
						Wave ScreenF
					endif
					mapEdgeImage(ScreenF)
					RemoveImage/W=GraphPlume ScreenU
					RemoveImage/W=GraphPlume Edges_col
					AppendImage/W=GraphPlume ScreenF 
					AppendImage/W=GraphPlume Edges_col
					ModifyImage ScreenF ctab= {*,*,Rainbow,1}
					ModifyImage Edges_col ctab= {minConc,maxConc,Grays,1}
				endif
			endif
			displayScreen = popNum
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
