begin
  start_cpu_time = get_cpu_time()

;---Variable Name
if(.not.isvar("varname")) then
  varname = "T"
  print("varname not defined, assuming " + varname)
end if

;---Level
if(.not.isvar("level")) then
  level = 0
  print("level not defined, assuming " + level)
end if

BASEDIR = getenv("BASEDIR")
if(ismissing(BASEDIR)) then
  BASEDIR = "/glade/scratch/mdillion/EXP/RRA_02/"
;    print("BASEDIR not defined, assuming: " + BASEDIR)
end if

;---NPP output file
path = BASEDIR + "POST/NPP/"
if(.not.isvar("fname")) then
  fname = "npp_out"
  print("fname not defined, assuming " + fname)
end if
path_out = BASEDIR + "POST/PLOT/"

;---Number of rows?
  nrows    = 5

;---Open files using addfiles
  f = addfile(path+fname+".nc","r")

;---Open workstation
  wks_type = "pdf"
  wks_type@wkPaperHeightF = 40
  wks_type@wkPaperWidthF  = 57
  wks = gsn_open_wks(wks_type,path_out+fname+"_panel_"+varname+"_"+level)

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
  map_res@mpNationalLineThicknessF    = 0.2
  map_res@mpGeophysicalLineThicknessF = 0.2
  ;map_res@mpMaskOutlineSpecifiers     = "Argentina"
  
  map_res@tmXBLabelFontHeightF        = 0.012
  map_res@tmXTLabelFontHeightF        = 0.012
  map_res@tmYLLabelFontHeightF        = 0.012
  map_res@tmYRLabelFontHeightF        = 0.012
  map_res@tmYRLabelJust               = "CenterCenter"  
  map_res@tmYLLabelJust               = "CenterCenter"
  map_res@tmYRLabelAngleF             = 90
  map_res@tmYLLabelAngleF             = 90
  
  map_res@tmBorderThicknessF          = 0.1
  map_res@tmXBMajorThicknessF         = 0.1
  map_res@tmXTMajorThicknessF         = 0.1
  map_res@tmYRMajorThicknessF         = 0.1
  map_res@tmYLMajorThicknessF         = 0.1

  map_res@pmTickMarkDisplayMode       = "Always"

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
  
  con_res@lbLabelBarOn                = False

;---Panel resources
  pnlres                              = True
  pnlres@gsnPanelMainString           = ""
  pnlres@gsnPanelLabelBar             = True

  pnlres@lbLabelBarOn                 = True  
  pnlres@lbTitleFontHeightF           = 0.015
  pnlres@lbLabelFontHeightF           = 0.01

  pnlres@pmLabelBarWidthF             = 0.35
  pnlres@pmLabelBarHeightF            = 0.07
  pnlres@pmLabelBarOrthogonalPosF     = -0.02
  pnlres@gsnPanelRight                = 0.992
  pnlres@gsnPanelDebug                = False

  pnlres@gsnMaximize                  = True
  pnlres@gsnPaperMargin               = 0.1
  pnlres@gsnPaperOrientation          = "portrait"

;---Get variables to be read
  ;print("Working for variable: " + varname)
  if(varname.eq."SPD") then
    if (getfilevartypes(f,"U").eq."short") then
      U = short2flt( f->U(:,level,:,:) )  
      V = short2flt( f->V(:,level,:,:) )  
    else
      U = f->U(:,level,:,:)
      V = f->V(:,level,:,:)
    end if
    data = sqrt(U^2+V^2)
  else
    if (getfilevartypes(f,varname).eq."short") then
      data = short2flt( f->$varname$(:,level,:,:) )  
    else
      data = f->$varname$(:,level,:,:)
    end if    
  end if

  height = f->LEV(level)

  if(varname.eq."Q") then
    pnlres@lbTitleString    = "Water Vapor mixing ratio at " + height + " hPa (g/kg)"
    con_res@cnMinLevelValF  = 3
    con_res@cnMaxLevelValF  = 15
    con_res@cnLevelSpacingF = 1
  else if(varname.eq."SPD") then
    pnlres@lbTitleString    = "Wind speed at " + height + " hPa (m/s)"
    pnlres@lbBoxEndCapStyle = "TriangleBothEnds"
    if (height.ge.900) then
      con_res@cnMinLevelValF  = 1
      con_res@cnMaxLevelValF  = 14
      con_res@cnLevelSpacingF = 1
    else if (height.eq.850) then
      con_res@cnMinLevelValF  = 10
      con_res@cnMaxLevelValF  = 24
      con_res@cnLevelSpacingF = 1
    else if (height.eq.500) then
      con_res@cnMinLevelValF  = 2
      con_res@cnMaxLevelValF  = 42
      con_res@cnLevelSpacingF = 4
    else
      con_res@cnMinLevelValF  = 30
      con_res@cnMaxLevelValF  = 50
      con_res@cnLevelSpacingF = 2
    end if
    end if
    end if
  else if(varname.eq."T") then
    data                    = data - 273.15
    pnlres@lbTitleString    = "Temperature at " + height + " hPa (~F34~0~F~C)"
    pnlres@lbBoxEndCapStyle = "TriangleBothEnds"
    if (height.ge.900) then
      con_res@cnMinLevelValF  = 6
      con_res@cnMaxLevelValF  = 30
      con_res@cnLevelSpacingF = 2.0
    else if (height.eq.850) then
      con_res@cnMinLevelValF  = -1
      con_res@cnMaxLevelValF  = 24
      con_res@cnLevelSpacingF = 2.0
    else if (height.eq.500) then
      con_res@cnMinLevelValF  = -22
      con_res@cnMaxLevelValF  = -6
      con_res@cnLevelSpacingF = 2.0
    else
      con_res@cnMinLevelValF  = -46
      con_res@cnMaxLevelValF  = -36
      con_res@cnLevelSpacingF = 1.0
    end if
    end if
    end if
  else if(varname.eq."HGT") then
    pnlres@lbTitleString    = "Geopotential Height at " + height + " hPa (m)"
    con_res@cnMinLevelValF  = 6
    con_res@cnMaxLevelValF  = 30
    con_res@cnLevelSpacingF = 2.0
  else
    print("Variable not recognized: "+varname)
  end if
  end if
  end if
  end if

  dims = dimsizes(data)
  nm   = dims(0)-1
  ny   = dims(1)
  nx   = dims(2)
  nm = 60

  ncols   = nm/nrows
  if(nm%nrows .gt. 0) then
    ncols = ncols + 1
  end if
    
  map     = new(nm,graphic)
  contour = new(nm,graphic)

;---Loop through each member and draw a panel
  do it=0,nm-1
    ;print("Working for member " + it)

    if (it .lt. ncols) then
      map_res@tmXTLabelsOn = True            
      map_res@tmXTOn       = True
    else
      map_res@tmXTLabelsOn = False           
      map_res@tmXTOn       = False
    end if

    if (it .ge. ncols*(nrows-1)) then
      map_res@tmXBLabelsOn = True            
      map_res@tmXBOn       = True            
    else
      map_res@tmXBLabelsOn = False           
      map_res@tmXBOn       = False
    end if

    if (it%ncols .eq. 0) then
      map_res@tmYLLabelsOn = True
      map_res@tmYLOn       = True
    else
      map_res@tmYLLabelsOn = False
      map_res@tmYLOn       = False
    end if

    if (it%ncols .eq. ncols-1 .or. it .eq. nm-1) then
      map_res@tmYRLabelsOn = True
      map_res@tmYROn       = True
    else
      map_res@tmYRLabelsOn = False
      map_res@tmYROn       = False
    end if
    
    map(it)     = gsn_csm_map(wks,map_res)  
    contour(it) = gsn_csm_contour(wks,data(it,:,:),con_res)

    ;---Overlay plots on map and draw.
    overlay(map(it),contour(it))
  end do

  gsn_panel(wks,map,(/nrows,ncols/),pnlres)
 
  end_cpu_time = get_cpu_time()
  print(get_script_prefix_name() + " for " +varname+ ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")
end
