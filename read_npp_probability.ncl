load "ensambleWRF.ncl"

/;
Calcula la probabilidad de superar un dado
valor umbral y genera un mapa
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
   4. threshold
   5. iz (vertical level)
   6. BASEDIR (Environment variable)
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
  ;print("Working with file " + fname)

;---Threshold
  if(.not.isvar("threshold")) then
    threshold = 50
    print("threshold not defined, assuming " + threshold)
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

;---Vertical level
  if( any(varname .eq. (/ "Q", "SPD", "T", "HGT" /) ) ) then
    if(.not.isvar("iz")) then
      iz = 0
      print("iz not defined, assuming " + iz)
    end if
    pressure = f->LEV(iz)
    fname_out = fname+"_probability"+threshold+"_"+varname+pressure+"hPa"
  else
    pressure = -1
    iz = -1
    fname_out = fname+"_probability"+threshold+"_"+varname
  end if

;---Open workstation
  wks_type = "png"
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
  map_res@gsnMaximize       = True
  map_resourcesx1(f,map_res)

;---CONTOUR filled contour plot
  con_res                             = res
  con_res@cnFillOn                    = True
  con_res@cnLinesOn                   = False
  con_res@cnLineLabelsOn              = False
  con_res@cnInfoLabelOn               = False
  contour_resources("probability",-1,con_res)

  con_res@lbLabelBarOn                = True
  con_res@lbOrientation               = "Vertical"
  con_res@lbTitleFontHeightF          = 0.018
  con_res@lbLabelFontHeightF          = 0.018
  labelbar_resources("probability",-1,con_res)

;---Section to add polylines to map.
  lnres                               = True
  lnres@gsLineColor                   = "gray50"
  lnres@gsLineThicknessF              = 1.0

;---Get variables to be read
  data    = get_NPP_data(f, varname, iz)

  dims    = dimsizes(data)
  nm      = dims(0)
  ny      = dims(1)
  nx      = dims(2)

  proba   = 100.0*dim_num_n(data.ge.threshold,0)/nm

  map_res@tiMainString = "Ensemble Probability of Exceedance"
  map_res@gsnCenterString = data@long_name + "~F34~3~F21~" + threshold + data@unit
  map_res@gsnCenterStringFontHeightF = 0.015

  map     = gsn_csm_map(wks,map_res)  
  contour = gsn_csm_contour(wks,proba,con_res)
  id      = gsn_add_shapefile_polylines(wks,map,"interprovincial/interprovinciales.shp",lnres)

  ;---Overlay plots on map and draw.
  overlay(map,contour)

  draw(map)
  frame(wks)
 
  end_cpu_time = get_cpu_time()
  print(get_script_prefix_name() + " for " +varname+ ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")
end
