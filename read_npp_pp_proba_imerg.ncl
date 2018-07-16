load "./LoadIMERG.ncl"

begin
  start_cpu_time = get_cpu_time()

;----------------------------------------------------------
;---Calcula la probabilidad de que la precipitación
;---acumulada supere un dado valor umbral
;---Inputs:
;---1. threshold
;---2. y (year), m (month), d (day), h (hour), hf (forecast hour)
;---3. BASEDIR (Environment variable)
;----------------------------------------------------------

;---Precipitation threshold (mm)
  if(.not.isvar("threshold")) then
    threshold = 50
    print("threshold not defined, assuming " + threshold)
  end if

;---Filename (only forecast file)
  if(isvar("y") .and. isvar("m") .and. isvar("d") .and. isvar("h") .and. isvar("hf")) then
    fname = sprinti("NPP_%0.4i-", y) + \
            sprinti("%0.2i-", m) + \
            sprinti("%0.2i_", d) + \
            sprinti("%0.2i_", h) + \
            sprinti("FC%0.2i", hf)
    print("Working with forecast file " + fname)
  else
    print("Required input: y, m, d, h, hf. Closing...")
    exit()
  end if

;---Root directory
  BASEDIR = getenv("BASEDIR")
  if(ismissing(BASEDIR)) then
    BASEDIR = "/glade/scratch/mdillion/EXP/RRA_02/"
    print("BASEDIR not defined, assuming: " + BASEDIR)
  end if
  path     = BASEDIR + "POST/NPP/"
  path_out = BASEDIR + "POST/PLOT/"

;---Variable Name
  varname = "PP"

;---Open files using addfiles
  f = addfile(path+fname+".nc","r")

;---Open workstation
  wks_type = "png"
  wks      = gsn_open_wks(wks_type,path_out+fname+"_"+varname+"_th"+threshold+"_imerg")

;---Set some common resources
  res                       = True
  res@gsnDraw               = False
  res@gsnFrame              = False

;---Using Native projection
  res@tfDoNDCOverlay        = True
  res@gsnAddCyclic          = False

  res@gsnLeftString         = ""
  res@gsnRightString        = ""
  res@gsnCenterString       = ""
  
;---Map plot
  map_res                   = True
  map_res@gsnDraw           = False
  map_res@gsnFrame          = False
  map_res@gsnMaximize       = False

;---Set map resources based on projection on NPP output file
  map_res@mpProjection                = "LambertConformal"
  map_res@mpLambertParallel1F         = f@TRUELAT1
  map_res@mpLambertParallel2F         = f@TRUELAT2
  map_res@mpLambertMeridianF          = f@STAND_LON
  map_res@mpLimitMode                 = "Corners"
  map_res@mpLeftCornerLatF            = f@start_lat
  map_res@mpLeftCornerLonF            = f@start_lon
  map_res@mpRightCornerLatF           = f@end_lat
  map_res@mpRightCornerLonF           = f@end_lon

;---Map resources
  map_res@mpFillOn                    = False
  map_res@mpOutlineOn                 = True
  map_res@mpDataBaseVersion           = "MediumRes"
  map_res@mpDataSetName               = "Earth..4"
  map_res@mpOutlineDrawOrder          = "PostDraw"

  map_res@mpOutlineBoundarySets       = "National"
  map_res@mpNationalLineColor         = "Black"
  map_res@mpGeophysicalLineColor      = "Black"
  map_res@mpNationalLineThicknessF    = 2.0
  map_res@mpGeophysicalLineThicknessF = 2.0
  ;map_res@mpMaskOutlineSpecifiers     = "Argentina"
  
  map_res@tmXBLabelFontHeightF        = 0.012
  map_res@tmXTLabelFontHeightF        = 0.012
  map_res@tmYLLabelFontHeightF        = 0.012
  map_res@tmYRLabelFontHeightF        = 0.012
  map_res@tmYRLabelJust               = "CenterCenter"  
  map_res@tmYLLabelJust               = "CenterCenter"
  map_res@tmYRLabelAngleF             = 90
  map_res@tmYLLabelAngleF             = 90
  
  map_res@tmBorderThicknessF          = 1.2
  map_res@tmXBMajorThicknessF         = 1.2
  map_res@tmXTMajorThicknessF         = 1.2
  map_res@tmYRMajorThicknessF         = 1.2
  map_res@tmYLMajorThicknessF         = 1.2

  map_res@pmTickMarkDisplayMode       = "Always"

  map_res@tiMainString                = "Ensemble Probability of Exceedance"
  map_res@gsnCenterString             = "6-h Accumulated Precipitation > " + threshold + " mm"
;  map_res@tiMainFontHeightF           = 0.015
  map_res@gsnCenterStringFontHeightF  = 0.015

;---Color Palette
;  cmap = read_colormap_file("MPL_RdYlBu")
;  cmap = cmap(::-1,:) ; reverse the color map 

;---CONTOUR filled contour plot
  con_res                             = res
  con_res@cnFillOn                    = True
  con_res@cnLinesOn                   = False
  con_res@cnLineLabelsOn              = False
  con_res@cnInfoLabelOn               = False
  con_res@cnRasterModeOn              = False

  con_res@cnLevelSelectionMode        = "ManualLevels"
  con_res@cnMinLevelValF              = 10
  con_res@cnMaxLevelValF              = 90
  con_res@cnLevelSpacingF             = 10
  ; con_res@cnFillPalette               = "precip2_17lev"
  con_res@cnFillPalette               = "WhiteBlue"

  con_res@lbLabelBarOn                = True
  con_res@lbOrientation               = "Vertical"
  ; con_res@lbTitlePosition             = "Right"
  ; con_res@lbTitleDirection            = "Across"
  ; con_res@lbTitleAngleF               = 90. 
  con_res@lbTitleString               = "[%]"
  con_res@lbTitleFontHeightF          = 0.018
  con_res@lbLabelFontHeightF          = 0.018
  ; con_res@lbBoxEndCapStyle            = "TriangleBothEnds"

  ; con_res@pmLabelBarWidthF             = 0.35
  ; con_res@pmLabelBarHeightF            = 0.07
  ; con_res@pmLabelBarOrthogonalPosF     = -0.02

;---CONTOUR for IMERG
  con_asc                             = res
  con_asc@tfDoNDCOverlay              = False

  con_asc@cnFillOn                    = False
  con_asc@cnLinesOn                   = True
  con_asc@cnLineLabelsOn              = True

  con_asc@cnInfoLabelOn               = True
  con_asc@cnInfoLabelString           = "Contour Lines: IMERG"

  con_asc@cnLevelSelectionMode        = "ExplicitLevels"
  con_asc@cnLevels                    = (/ threshold /)
  con_asc@cnLineColor                 = "red"
  con_asc@cnLineThicknessF            = 2.0

;---Section to add polylines to map.
  lnres                  = True           ; resource list for polylines
  lnres@gsLineColor      = "gray50"
  lnres@gsLineThicknessF = 1.0

;---Get variables to be read
  print("Working for variable: " + varname)
  if (getfilevartypes(f,varname).eq."short") then
    data = short2flt( f->$varname$ )
  else
    data = f->$varname$
  end if

  dims    = dimsizes(data)
  nm      = dims(0)
  ny      = dims(1)
  nx      = dims(2)

  proba   = 100.0*dim_num_n(data.ge.threshold,0)/nm

;---Get IEMRG ASCII data
  fname_ascii = "IMERG_FR_201709261800-201709270000.txt"
  data_asc    = LoadIMERG(fname_ascii)

  map         = gsn_csm_map(wks,map_res)
  contour     = gsn_csm_contour(wks,proba,con_res)
  contour_asc = gsn_csm_contour(wks,data_asc,con_asc)
  id          = gsn_add_shapefile_polylines(wks,map,"interprovincial/interprovinciales.shp",lnres)

  ;---Overlay plots on map and draw.
  overlay(map,contour)
  overlay(map,contour_asc)

  draw(map)
  frame(wks)
 
  end_cpu_time = get_cpu_time()
  print(get_script_prefix_name() + " for " +varname+ ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")
end
