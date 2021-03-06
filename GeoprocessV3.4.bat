@echo off
REM ********
rem batch file to calculate multiple terrain derivatives given a DEM and shapefile of HUC watersheds 
rem author Colby W. Brungard PhD
REM Plant and Environmental Sciences Dept.  
REM New Mexico State University 
REM Las Cruces, NM 88003
REM cbrung@nmsu.edu
REM +1-575-646-1907
REM ********* (in case you are wondering; rem = remark)

REM Set needed paths. 
REM I found it easiest to install SAGA directly on the C drive. 
REM modify the following paths to match your saga install
REM path to saga_cmd.exe
set PATH=%PATH%;C:\saga-6.2.0_x64
set SAGA_MLB=C:\saga-6.2.0_x64\tools

REM name of base DEM from which to calculate derivatives
set DEM=C:\DEM\NM_5m_dtm.tif

REM path to HUC8 watershed files. Both are needed because I clip by the unprojected shapefile and then trim with the projected shapefile. Use the following to gdal command to reproject shapefile if needed: ogr2ogr -f "ESRI Shapefile" wbdhu10_a_us_september2017_proj.shp wbdhu10_a_us_september2017.shp -t_srs EPSG:10200
set indexA=C:\DEM\wbdhu8_a_us_september2017_USboundCONUS.shp
set indexB=C:\DEM\wbdhu8_a_us_september2017_USboundCONUS_proj.shp

rem The column name of the shapefiles attribute table with the HUC values. Use HUC8 for 10m DEM and HUC6 for 30m DEM
set fieldname=HUC8

rem tiles are the names/values of each polygon. These must be manually input and can be identified as the watersheds that overlay your area of interest. 
set tiles=13020211 13030103 13030101 13030102 13030202 13020210

rem Set a primary and secondary buffer distance in number of pixels. The primary will be used when clipping the DEM by HUC8 watersheds. The secondary will be used to trim off edge effects of each derivative, but leave enough to feather the edges when mosaicking.
set bufferA=100
set bufferB=20


REM start time 
set startTime=%date%:%time%

REM the following script is one that is "embarrassingly parallel", but it runs rather quickly (saga already parallelizes DEM derivative calculations). I decided to include each calculation within it's own for loop. This is very inelegant, but it allows me to calculate a derivative for each watershed, stitch them all together, and then delete the individual derivatives for each watershed to save space (which quickly became an issue for large DEMs).

REM please note that this code does NOT fill the DEMs. I found that filling by watershed resulted in very flat areas in the bottom of valleys.

REM 1. Preprocessing
REM Create subfolders to hold derivatives
REM for %%i in (%tiles%) do (
 REM mkdir %%i
 REM )

REM REM Clip DEM to HUC watershed boundary. Note: I tried multi-threaded warping -multi -wo NUM_THREADS=val/ALL_CPUS http://www.gdal.org/gdalwarp.html), but it didn't really seem to speed things up.
REM for %%i in (%tiles%) do (
 REM echo now subsetting %fieldname% %%i
  REM gdalwarp -t_srs EPSG:102008 -tr 10 10 -r bilinear -dstnodata -9999 -cutline %indexA% -cwhere "%fieldname% = '%%i'" -crop_to_cutline -cblend %bufferA% -of SAGA %DEM% %%i\%%i.sdat
REM )
  
REM REM Smooth DEM to remove data artifacts using circle-shaped smooting filter with radius of 4 cells 
REM for %%i in (%tiles%) do (
 REM echo now smoothing %fieldname% %%i
  REM saga_cmd grid_filter 0 -INPUT=%%i\%%i.sdat -RESULT=%%i\%%i_s.sgrd -METHOD=0 -KERNEL_TYPE=1 -KERNEL_RADIUS=4
REM )
   
	REM REM REM Remove intermediate files
	REM REM for %%i in (%tiles%) do (	   
	 REM REM del %%i\%%i.prj
	 REM REM del %%i\%%i.sdat
	 REM REM del %%i\%%i.sdat.aux.xml
	 REM REM del %%i\%%i.sgrd
	REM )   
   
REM REM 2. Calculate Derivatives
REM REM each code chunk follows the same format: 
 REM REM 1. Calculate one or more derivatives
 REM REM 2. Trim off the edges of each derivative by a fraction of the original buffer to remove cells effected by edge artifacts
 REM REM 3. Remove intermediate files to save space.

REM REM REM analytical hillshade ##########	   
REM for %%i in (%tiles%) do (
 REM echo now calculating analytical hillshade of %fieldname% %%i 
  REM saga_cmd ta_lighting 0 -ELEVATION=%%i\%%i_s.sgrd -SHADE=%%i\%%i_hsA.sgrd -METHOD=0 -UNIT=1
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming analytical hillshade of %fieldname% %%i
	 	REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_hsA.sdat %%i\%%i_hs.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_hsA.mgrd
		 REM del %%i\%%i_hsA.prj
		 REM del %%i\%%i_hsA.sdat
		 REM del %%i\%%i_hsA.sdat.aux.xml
		 REM del %%i\%%i_hsA.sgrd
		REM )

		
REM REM Profile, plan, longitudinal, cross-sectional, minimum, maximum, and total curvature ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Profile, plan, longitudinal, cross-sectional, minimum, maximum, and total curvature of %fieldname% %%i 
  REM saga_cmd ta_morphometry 0 -ELEVATION=%%i\%%i_s.sgrd -C_PROF=%%i\%%i_profcA.sgrd -C_PLAN=%%i\%%i_plancA.sgrd -C_LONG=%%i\%%i_lcA.sgrd -C_CROS=%%i\%%i_ccA.sgrd -C_MINI=%%i\%%i_mcA.sgrd  -C_MAXI=%%i\%%i_mxcA.sgrd -C_TOTA=%%i\%%i_tcA.sgrd -METHOD=6 -UNIT_SLOPE=2
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Profile Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_profcA.sdat %%i\%%i_profc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_profcA.mgrd
		 REM del %%i\%%i_profcA.prj
		 REM del %%i\%%i_profcA.sdat
		 REM del %%i\%%i_profcA.sdat.aux.xml
		 REM del %%i\%%i_profcA.sgrd
		REM )

	REM for %%i in (%tiles%) do (
	 REM echo now trimming Plan Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_plancA.sdat %%i\%%i_planc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_plancA.mgrd
		 REM del %%i\%%i_plancA.prj
		 REM del %%i\%%i_plancA.sdat
		 REM del %%i\%%i_plancA.sdat.aux.xml
		 REM del %%i\%%i_plancA.sgrd
		REM )	
			
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Longitudinal Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_lcA.sdat %%i\%%i_lc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_lcA.mgrd
		 REM del %%i\%%i_lcA.prj
		 REM del %%i\%%i_lcA.sdat
		 REM del %%i\%%i_lcA.sdat.aux.xml
		 REM del %%i\%%i_lcA.sgrd
		REM )		
		
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Cross Sectional Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_ccA.sdat %%i\%%i_cc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_ccA.mgrd
		 REM del %%i\%%i_ccA.prj
		 REM del %%i\%%i_ccA.sdat
		 REM del %%i\%%i_ccA.sdat.aux.xml
		 REM del %%i\%%i_ccA.sgrd
		REM )
		
	REM for %%i in (%tiles%) do (
	 REM echo now Minimum Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mcA.sdat %%i\%%i_mc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mcA.mgrd
		 REM del %%i\%%i_mcA.prj
		 REM del %%i\%%i_mcA.sdat
		 REM del %%i\%%i_mcA.sdat.aux.xml
		 REM del %%i\%%i_mcA.sgrd
		REM )
		
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Maximum Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mxcA.sdat %%i\%%i_mxc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mxcA.mgrd
		 REM del %%i\%%i_mxcA.prj
		 REM del %%i\%%i_mxcA.sdat
		 REM del %%i\%%i_mxcA.sdat.aux.xml
		 REM del %%i\%%i_mxcA.sgrd
		REM )		
		
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Total Curvature of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_tcA.sdat %%i\%%i_tc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_tcA.mgrd
		 REM del %%i\%%i_tcA.prj
		 REM del %%i\%%i_tcA.sdat
		 REM del %%i\%%i_tcA.sdat.aux.xml
		 REM del %%i\%%i_tcA.sgrd
		REM )
		

REM REM Convergence Index ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Convergence Index of %fieldname% %%i 
  REM saga_cmd ta_morphometry 1 -ELEVATION=%%i\%%i_s.sgrd -RESULT=%%i\%%i_ciA.sgrd -METHOD=1 -NEIGHBOURS=1
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Convergence Index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_ciA.sdat %%i\%%i_ci.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_ciA.mgrd
		 REM del %%i\%%i_ciA.prj
		 REM del %%i\%%i_ciA.sdat
		 REM del %%i\%%i_ciA.sdat.aux.xml
		 REM del %%i\%%i_ciA.sgrd
		REM )
		
		
REM REM Diurnal Anisotropic Heating ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Diurnal Anisotropic Heating of %fieldname% %%i 
  REM saga_cmd ta_morphometry 12 -DEM=%%i\%%i_s.sgrd -DAH=%%i\%%i_dahA.sgrd -ALPHA_MAX=225
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Diurnal Anisotropic Heating of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_dahA.sdat %%i\%%i_dah.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_dahA.mgrd
		 REM del %%i\%%i_dahA.prj
		 REM del %%i\%%i_dahA.sdat
		 REM del %%i\%%i_dahA.sdat.aux.xml
		 REM del %%i\%%i_dahA.sgrd
		REM )
		

REM REM MultiScale Topographic Position Index ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating MultiScale Topographic Position Index of %fieldname% %%i 
  REM saga_cmd ta_morphometry 28 -DEM=%%i\%%i_s.sgrd -TPI=%%i\%%i_tpiA.sgrd -SCALE_MIN=1 -SCALE_MAX=8 -SCALE_NUM=3
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming MultiScale Topographic Position Index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_tpiA.sdat %%i\%%i_tpi.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_tpiA.mgrd
		 REM del %%i\%%i_tpiA.prj
		 REM del %%i\%%i_tpiA.sdat
		 REM del %%i\%%i_tpiA.sdat.aux.xml
		 REM del %%i\%%i_tpiA.sgrd
		REM )
		

REM REM MRVBF and MRRTF ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating MRVBF and MRRTF of %fieldname% %%i 
  REM saga_cmd ta_morphometry 8 -DEM=%%i\%%i_s.sgrd -MRVBF=%%i\%%i_mrvbfA.sgrd -MRRTF=%%i\%%i_mrrtfA.sgrd -T_SLOPE=32 
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming MRVBF of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mrvbfA.sdat %%i\%%i_mrvbf.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mrvbfA.mgrd
		 REM del %%i\%%i_mrvbfA.prj
		 REM del %%i\%%i_mrvbfA.sdat
		 REM del %%i\%%i_mrvbfA.sdat.aux.xml
		 REM del %%i\%%i_mrvbfA.sgrd
		REM )

	REM for %%i in (%tiles%) do (
	 REM echo now trimming MRRTF of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mrrtfA.sdat %%i\%%i_mrrtf.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mrrtfA.mgrd
		 REM del %%i\%%i_mrrtfA.prj
		 REM del %%i\%%i_mrrtfA.sdat
		 REM del %%i\%%i_mrrtfA.sdat.aux.xml
		 REM del %%i\%%i_mrrtfA.sgrd
		REM )


REM REM Terrain Ruggedness Index ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Terrain Ruggedness Index of %fieldname% %%i 
  REM saga_cmd ta_morphometry 16 -DEM=%%i\%%i_s.sgrd -TRI=%%i\%%i_triA.sgrd -MODE=1 -RADIUS=10
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Terrain Ruggedness Index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_triA.sdat %%i\%%i_tri.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_triA.mgrd
		 REM del %%i\%%i_triA.prj
		 REM del %%i\%%i_triA.sdat
		 REM del %%i\%%i_triA.sdat.aux.xml
		 REM del %%i\%%i_triA.sgrd
		REM )
		

REM REM Terrain Surface Convexity ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Terrain Surface Convexity of %fieldname% %%i 
  REM saga_cmd ta_morphometry 21 -DEM=%%i\%%i_s.sgrd -CONVEXITY=%%i\%%i_tscA.sgrd -KERNEL=1 -TYPE=0 -EPSILON=0.0 -SCALE=10 -METHOD=1 -DW_WEIGHTING=3 -DW_BANDWIDTH=0.7
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Terrain Surface Convexity of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_tscA.sdat %%i\%%i_tsc.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_tscA.mgrd
		 REM del %%i\%%i_tscA.prj
		 REM del %%i\%%i_tscA.sdat
		 REM del %%i\%%i_tscA.sdat.aux.xml
		 REM del %%i\%%i_tscA.sgrd
		REM )
	
		
REM REM Saga wetness index, catchment area, modified catchment area, and catchment slope ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Saga wetness index catchment area, modificed catchment area, and catchment slope of %fieldname% %%i 
  REM saga_cmd ta_hydrology 15 -DEM=%%i\%%i_s.sgrd -TWI=%%i\%%i_swiA.sgrd -AREA=%%i\%%i_caA.sgrd -AREA_MOD=%%i\%%i_mcaA.sgrd -SLOPE=%%i\%%i_csA.sgrd
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Saga wetness index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_swiA.sdat %%i\%%i_swi.tif
	REM )   
	
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_swiA.mgrd
		 REM del %%i\%%i_swiA.prj
		 REM del %%i\%%i_swiA.sdat
		 REM del %%i\%%i_swiA.sdat.aux.xml
		 REM del %%i\%%i_swiA.sgrd
		REM )
		
		
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Catchment Slope of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_csA.sdat %%i\%%i_cs.tif
	REM )
	
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_csA.mgrd
		 REM del %%i\%%i_csA.prj
		 REM del %%i\%%i_csA.sdat
		 REM del %%i\%%i_csA.sdat.aux.xml
		 REM del %%i\%%i_csA.sgrd
		REM )
	
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Modified Catchment Area of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mcaA.sdat %%i\%%i_mca.tif
	REM )
	 
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mcaA.mgrd
		 REM del %%i\%%i_mcaA.prj
		 REM del %%i\%%i_mcaA.sdat
		 REM del %%i\%%i_mcaA.sdat.aux.xml
		 REM del %%i\%%i_mcaA.sgrd
		REM )		


REM REM Slope ##########			
REM for %%i in (%tiles%) do (
 REM echo now calculating Slope of %fieldname% %%i 
  REM saga_cmd ta_morphometry 0 -ELEVATION=%%i\%%i_s.sgrd -SLOPE=%%i\%%i_slA.sgrd -METHOD=2 -UNIT_SLOPE=2
   REM )

   
REM REM Stream power index - requires slope and catchment area as input ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating stream power index of %fieldname% %%i
  REM saga_cmd ta_hydrology 21 -SLOPE=%%i\%%i_slA.sgrd -AREA=%%i\%%i_caA.sgrd -SPI=%%i\%%i_spiA.sgrd
  REM )

    REM for %%i in (%tiles%) do (
	 REM echo now trimming stream power index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_spiA.sdat %%i\%%i_spi.tif
	REM ) 
	
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_spiA.mgrd
		 REM del %%i\%%i_spiA.prj
		 REM del %%i\%%i_spiA.sdat
		 REM del %%i\%%i_spiA.sdat.aux.xml
		 REM del %%i\%%i_spiA.sgrd
		REM )
		
			
REM REM Topographic wetness index - requires slope and catchment area as input ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating topographic wetness index of %fieldname% %%i
  REM saga_cmd ta_hydrology 20 -SLOPE=%%i\%%i_slA.sgrd -AREA=%%i\%%i_caA.sgrd -TWI=%%i\%%i_twiA.sgrd
  REM )

    REM for %%i in (%tiles%) do (
	 REM echo now trimming topographic wetness index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_twiA.sdat %%i\%%i_twi.tif
	REM ) 	
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_twiA.mgrd
		 REM del %%i\%%i_twiA.prj
		 REM del %%i\%%i_twiA.sdat
		 REM del %%i\%%i_twiA.sdat.aux.xml
		 REM del %%i\%%i_twiA.sgrd
		REM )
	
	
REM REM Trim Slope and catchment area, delete intermediate files (this is not done before because SPI and TWI need slope and catchment area as input
REM for %%i in (%tiles%) do (
 REM echo now trimming Slope of %fieldname% %%i
  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_slA.sdat %%i\%%i_sl.tif
REM ) 

REM for %%i in (%tiles%) do (
 REM echo now trimming Catchment Area index of %fieldname% %%i
  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_caA.sdat %%i\%%i_ca.tif
REM )	

 REM for %%i in (%tiles%) do (	   
  REM del %%i\%%i_slA.mgrd
  REM del %%i\%%i_slA.prj
  REM del %%i\%%i_slA.sdat
  REM del %%i\%%i_slA.sdat.aux.xml
  REM del %%i\%%i_slA.sgrd
 REM ) 
 
 REM for %%i in (%tiles%) do (	   
  REM del %%i\%%i_caA.mgrd
  REM del %%i\%%i_caA.prj
  REM del %%i\%%i_caA.sdat
  REM del %%i\%%i_caA.sdat.aux.xml
  REM del %%i\%%i_caA.sgrd
 REM )
 

		
REM REM Positive Topographic Openness ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Positive Topographic Openness of %fieldname% %%i 
  REM saga_cmd ta_lighting 5 -DEM=%%i\%%i_s.sdat -POS=%%i\%%i_poA.sgrd -RADIUS=%bufferA% -METHOD=1 -DLEVEL=3.0 -NDIRS=8
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Positive Topographic Openness of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_poA.sdat %%i\%%i_po.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_poA.mgrd
		 REM del %%i\%%i_poA.prj
		 REM del %%i\%%i_poA.sdat
		 REM del %%i\%%i_poA.sdat.aux.xml
		 REM del %%i\%%i_poA.sgrd
		REM )

REM REM Mass Balance Index ##########
REM for %%i in (%tiles%) do (
 REM echo now calculating Mass Balance Index of %fieldname% %%i 
  REM saga_cmd ta_morphometry 10 -DEM=%%i\%%i_s.sdat -MBI=%%i\%%i_mbiA.sgrd -TSLOPE=15.000000 -TCURVE=0.010000 -THREL=15.000000
   REM )
   
	REM for %%i in (%tiles%) do (
	 REM echo now trimming Mass Balance Index of %fieldname% %%i
	  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_mbiA.sdat %%i\%%i_mbi.tif
	REM )   
	   
		REM for %%i in (%tiles%) do (	   
		 REM del %%i\%%i_mbiA.mgrd
		 REM del %%i\%%i_mbiA.prj
		 REM del %%i\%%i_mbiA.sdat
		 REM del %%i\%%i_mbiA.sdat.aux.xml
		 REM del %%i\%%i_mbiA.sgrd
		REM )		

REM REM Trim the smoothed DEM ##########
REM for %%i in (%tiles%) do (
 REM echo now trimming elevation of %fieldname% %%i
  REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 -tr 10 10 %%i\%%i_s.sdat %%i\%%i_s.tif
	REM )   

	REM for %%i in (%tiles%) do (	   
	 REM del %%i\%%i_s.mgrd
	 REM del %%i\%%i_s.prj
	 REM del %%i\%%i_s.sdat
	 REM del %%i\%%i_s.sdat.aux.xml
	 REM del %%i\%%i_s.sgrd
	REM )

		
echo Start Time: %startTime%
echo Finish Time: %date%:%time%

REM This process takes ~ 73 hours. 

REM REM THIS IS THE BASE CODE BLOCK
REM REM X ##########
REM REM for %%i in (%tiles%) do (
 REM REM echo now calculating X of %fieldname% %%i 
  REM REM saga_cmd X
   REM REM )
   
	REM REM for %%i in (%tiles%) do (
	 REM REM echo now X of %fieldname% %%i
	  REM REM gdalwarp -cutline %indexB% -cwhere "%fieldname% = '%%i'" -cblend %bufferB% -crop_to_cutline -dstnodata -9999 %%i_X.sdat %%i_X.tif
	REM REM )   
	   
		REM REM for %%i in (%tiles%) do (	   
		 REM REM del %%i_X.mgrd
		 REM REM del %%i_X.prj
		 REM REM del %%i_X.sdat
		 REM REM del %%i_X.sdat.aux.xml
		 REM REM del %%i_X.sgrd
		REM REM )
		
	
