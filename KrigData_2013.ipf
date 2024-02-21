#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "Covariance_Kriging"
#include "ExtrapolateUp"
#include "PlumeEmission"
#include <CustomControl Definitions>

// TERRA: Top-down Emission Rate Retrieval Algorithm
// Version 5.0
// Updated 2019-06-26


//Calculate the flux leaving the box laterally and in total
Function FluxCalc_2013()

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
		zsur = ScreenPosZ[s/2*ds]/dz
		for (z=0; z<nzi; z+=1)
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

Function FluxCalcAir_2013(sst, zst, send, zend)
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
		zsur = ScreenPosZ[s/2*ds]/dz
		for(z=nz; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if(s==0 || s==nsi-1)
				if (nsi/2*ds-5 > dimSize(ScreenPosXY,0))
					ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi/2*ds-5][0]) // Lon Difference 
					uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi/2*ds-5][1]) // Lat Difference
				endif
			else
				ux = (ScreenPosXY[s/2*ds+5][0] - ScreenPosXY[s/2*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s/2*ds+5][1] - ScreenPosXY[s/2*ds-5][1]) // Lat Difference
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


//Calculate exponential profiles to fit the data below the flight path
Function ProfilesExp_2013(height)
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
			z = zi*dz - ScreenPosZ[si*ds/2]
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

//Calculate linear profiles to fit the data below the flight path
Function ProfilesLine_2013(height)
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
			z = zi*dz - ScreenPosZ[si*ds/2]
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
Function ProfilesOther_2013()
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
		zsur = ScreenPosZ[si*ds/2]
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


//Fill the screen below the flight path using all profile methods
Function Fill_2013()

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
		zsur = ScreenPosZ[s/2]

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
		zsur = ScreenPosZ[s/2]

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
Function FillFinal_2013()

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
		zsur = ScreenPosZ[s/2]

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

//Change background value
Function chBG_2013()
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
	ProfilesOther_2013()
	Fill_2013()
	CompareBaselines()
	
	for (i = 0; i < dimSize(Fit_Flag,0); i += 1)
		if (StringMatch(Fit_Flag[i], "Z") == 1)
			UserBase[i] = Base[i][3]
		elseif (StringMatch(Fit_Flag[i], "ZC") == 1)
			UserBase[i] = Base[i][4]
		endif
	endfor
	
End

//Go back one profile from the end on GraphProfiles
Function ResetProfiles_2013()
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
End


//Rerun the fits with a new height
Function RerunFits_2013(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR height
	switch( ba.eventCode )
		case 2: // mouse up
			ProfilesExp_2013(height)
			ProfilesLine_2013(height)
			Fill_2013()
			CompareBaselines()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function GetScreen_2013()
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
		GetCoords_2013(screen)
		Wave latscreen, lonscreen
		ind1 = round(V_left/40)
		ind2 = round(V_right/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		FluxCalcAir_2013(V_left, V_bottom, V_right, V_top)
		FluxCalcScreen_2013(V_left, V_bottom, V_right, V_top, screen)
	
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
		GetCoords_2013(screen)
		Wave latscreen, lonscreen
		ind1 = round(sSt/40)
		ind2 = round(sEnd/40)
		print "Screen goes from", latscreen[ind1], ",", lonscreen[ind1], "to", latscreen[ind2], ",", lonscreen[ind2]
		FluxCalcAir_2013(sSt, zSt, sEnd, zEnd)
		FluxCalcScreen_2013(sSt, zSt, sEnd, zEnd, screen)
	
		SetDrawLayer UserFront								//Draw box around data
		SetDrawEnv xcoord= bottom,ycoord= left			
		SetDrawEnv	fillpat = 0, linethick = 2
		DrawRect round(sSt/ds)*ds, round(zSt/dz)*dz, round(sEnd/ds)*ds, round(zEnd/dz)*dz
	endif	
	
End

Function averageScreen_2013()
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
		GetCoords_2013(screen)
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
		GetCoords_2013(screen)
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

Function GetCoords_2013(screen)
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
		latscreen[count] = ScreenPosXY_deg[i*ds/2][1]
		lonscreen[count] = ScreenPosXY_deg[i*ds/2][0]
		count = count + 1
	endfor
	
End
	

Function FluxCalcScreen_2013(sst, zst, send, zend, ScreenWv)
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

Function AirFluxCalc_2013()
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
		zsur = ScreenPosZ[s/2*ds]/dz
		for(z=0; z<nzi; z+=1)
			ws = sqrt(ScreenWindEf[s][z]^2 + ScreenWindNf[s][z]^2)
			if(s==0 || s==nsi-1)
				if (nsi/2*ds-5 > dimSize(ScreenPosXY,0))
					ux = (ScreenPosXY[5][0] - ScreenPosXY[nsi/2*ds-5][0]) // Lon Difference 
					uy = (ScreenPosXY[5][1] - ScreenPosXY[nsi/2*ds-5][1]) // Lat Difference
				endif
			else
				ux = (ScreenPosXY[s/2*ds+5][0] - ScreenPosXY[s/2*ds-5][0]) // Lon Difference 
				uy = (ScreenPosXY[s/2*ds+5][1] - ScreenPosXY[s/2*ds-5][1]) // Lat Difference
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