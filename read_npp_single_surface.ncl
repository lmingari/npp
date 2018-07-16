load "ensambleWRF.ncl"

/;
Genera un unico mapa de un miembro del ensamble
para una dada variable de superficie
Inputs:
   1. varname:
      (PP),
      MDBZ,
      PSFC,
      Q2,
      REFL1KM,
      REFL4KM,
      SPD10,
      T2
   2. y (year), m (month), d (day), h (hour)
   3. hf (forecast hour):
      hf>=0        -> Forecast file
      hf<0         -> Guess file
      hf undefined -> Analysis file
   4. im (ensamble member)
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
  print("Working with forecast file " + fname)

;---Ensamble member
  if(.not.isvar("im")) then
    im = 0
    print("im not defined, assuming " + im)
  end if

;---Root directory
  BASEDIR = getenv("BASEDIR")
  if(ismissing(BASEDIR)) then
    BASEDIR = "/glade/scratch/mdillion/EXP/RRA_02/"
;    print("BASEDIR not defined, assuming: " + BASEDIR)
  end if
  path     = BASEDIR + "POST/NPP/"
  path_out = BASEDIR + "POST/PLOT/"

;---Open files using addfiles
  f = addfile(path+fname+".nc","r")

;---Open workstation
  wks_type = "png"
  wks = gsn_open_wks(wks_type,path_out+fname+"_single_"+varname)

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
  map_resourcesx1(f,map_res)

;---CONTOUR filled contour plot
  con_res                             = res
  con_res@cnFillOn                    = True
  con_res@cnLinesOn                   = False
  con_res@cnLineLabelsOn              = False
  con_res@cnInfoLabelOn               = False

  con_res@cnLevelSelectionMode        = "ManualLevels"
  contour_resources(varname,con_res)
  
  con_res@lbLabelBarOn                = True
  con_res@lbOrientation               = "Vertical"
  con_res@lbTitleDirection            = "Across"
  con_res@lbTitleAngleF               = 90
  con_res@lbTitlePosition             = "Right"
  con_res@lbTitleFontHeightF          = 0.02
  con_res@lbLabelFontHeightF          = 0.015
  labelbar_resources(varname,con_res)

;---Section to add polylines to map.
  lnres                  = True           ; resource list for polylines
  lnres@gsLineColor      = "gray50"
  lnres@gsLineThicknessF = 1.0

;---Get variables to be read
  ;print("Working for variable: " + varname)
  if(varname.eq."SPD10") then
    if (getfilevartypes(f,"U10").eq."short") then
      U10 = short2flt( f->U10 )  
      V10 = short2flt( f->V10 )  
    else
      U10 = f->U10
      V10 = f->V10
    end if
    data = sqrt(U10^2+V10^2)
  else
    if (getfilevartypes(f,varname).eq."short") then
      data = short2flt( f->$varname$ )  
    else
      data = f->$varname$
    end if    
  end if

  if(varname.eq."T2") then
    data = data - 273.15
  end if

  print("Working for member " + im)
  map     = gsn_csm_map(wks,map_res)  
  contour = gsn_csm_contour(wks,data(im,:,:),con_res)
  id      = gsn_add_shapefile_polylines(wks,map,"interprovincial/interprovinciales.shp",lnres)

  ;---Overlay plots on map and draw.
  overlay(map,contour)

  draw(map)
  frame(wks)
 
  end_cpu_time = get_cpu_time()
  print(get_script_prefix_name() + " for " +varname+ ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")
end
