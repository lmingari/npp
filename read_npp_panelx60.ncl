load "ensambleWRF.ncl"

/;
Genera mapas de todos los miembros del ensamble
para una dada variable
Inputs:
   1. varname:
      (PP), MDBZ, REFL1KM, REFL4KM,
      Q2, SPD10, T2, PSFC
      Q, SPD, T, HGT
   2. y (year), m (month), d (day), h (hour)
   3. hf (forecast hour):
      hf>=0        -> Forecast file
      hf<0         -> Guess file
      hf undefined -> Analysis file
   4. iz (vertical level)
   5. BASEDIR (Environment variable)
;/

begin
  start_cpu_time = get_cpu_time()

;---Variable Name
  if(.not.isvar("varname")) then
    varname = "PP"
    print("varname not defined, assuming " + varname)
  end if

;---Filename 
  if(isvar("y") .and. isvar("m") .and. isvar("d") .and. isvar("h")) then
    fname = sprinti("NPP_%0.4i-", y) + \
            sprinti("%0.2i-", m) + \
            sprinti("%0.2i_", d) + \
            sprinti("%0.2i_", h) 
  else
    print("Required input: y, m, d, h. Closing...")
    exit()
  end if

;---Checking for forecast hour
  if(isvar("hf")) then
    if(hf.ge.0) then
      fname = fname + sprinti("FC%0.2i", hf)
    else
      fname = fname + "GS"
    end if
  else
    fname = fname + "AN"
  end if
  ;print("Working with forecast file " + fname)

;---Root directory
  BASEDIR = getenv("BASEDIR")
  if(ismissing(BASEDIR)) then
    BASEDIR = "/glade/scratch/mdillion/EXP/RRA_02/"
;    print("BASEDIR not defined, assuming: " + BASEDIR)
  end if
  path     = BASEDIR + "POST/NPP/"
  path_out = BASEDIR + "POST/PLOT/"

;---Number of rows?
  nrows    = 5

;---Open files using addfiles
  f = addfile(path+fname+".nc","r")

;---Vertical level
  if( any(varname .eq. (/ "Q", "SPD", "T", "HGT" /) ) ) then
    if(.not.isvar("iz")) then
      iz = 0
      print("iz not defined, assuming " + iz)
    end if
    pressure = f->LEV(iz)
    fname_out = fname+"_panelx60_"+varname+pressure+"hPa"
  else
    pressure = -1
    iz = -1
    fname_out = fname+"_panelx60_"+varname
  end if

;---Open workstation
  wks_type = "pdf"
  wks_type@wkPaperHeightF = 40
  wks_type@wkPaperWidthF  = 57
  wks = gsn_open_wks(wks_type,path_out+fname_out)

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
  map_resourcesx60(f,map_res)

;---CONTOUR filled contour plot
  con_res                             = res
  con_res@cnFillOn                    = True
  con_res@cnLinesOn                   = False
  con_res@cnLineLabelsOn              = False
  con_res@cnInfoLabelOn               = False

  con_res@cnLevelSelectionMode        = "ManualLevels"
  con_res@lbLabelBarOn                = False
  contour_resources(varname,pressure,con_res)

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
  labelbar_resources(varname,pressure,pnlres)

;---Get variables to be read
  data = get_NPP_data(f, varname, iz)

  dims = dimsizes(data)
  nm   = dims(0)
  ny   = dims(1)
  nx   = dims(2)

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
