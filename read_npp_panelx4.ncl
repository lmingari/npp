load "ensambleWRF.ncl"

/;
Genera mapas de maximo, minimo 
media y spread del ensamble
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
  ;print("Working with file " + fname)

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
    fname_out = fname+"_panelx4_"+varname+pressure+"hPa"
  else
    pressure = -1
    iz = -1
    fname_out = fname+"_panelx4_"+varname
  end if

;---Open workstation
  wks_type = "pdf"
  wks_type@wkPaperHeightF = 10
  wks_type@wkPaperWidthF  = 8
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
  map_resourcesx1(f,map_res)

;---CONTOUR filled contour plot
  con_res                             = res
  con_res@cnFillOn                    = True
  con_res@cnLinesOn                   = False
  con_res@cnLineLabelsOn              = False
  con_res@cnInfoLabelOn               = False
  con_res@lbLabelBarOn                = False

;---CONTOUR filled contour plot 2
  con_res2                            = con_res

  contour_resources(varname,pressure,con_res)
  contour_resources("spread",-1,con_res2)

;---Panel resources
  pnlres                                   = True
  pnlres@gsnFrame                          = False
  pnlres@gsnPanelMainString                = ""
  pnlres@gsnPanelLabelBar                  = True
  pnlres@lbLabelBarOn                      = True  
  pnlres@lbTitleFontHeightF                = 0.015
  pnlres@lbLabelFontHeightF                = 0.01
  pnlres@gsnMaximize                       = True
  pnlres@gsnPaperMargin                    = 0.1
  pnlres@gsnPaperOrientation               = "portrait"
  pnlres@gsnPanelDebug                     = False

;---Panel resources 2
  pnlres2                                  = pnlres

  pnlres@pmLabelBarWidthF                  = 0.35
  pnlres@pmLabelBarHeightF                 = 0.07
  pnlres@pmLabelBarOrthogonalPosF          = -0.02
  ; pnlres@gsnPanelRight                   = 0.992
  pnlres@gsnPanelBottom                    = 0.5
  pnlres@gsnPanelFigureStrings             = (/ "Min","Mean","Max" /)
  pnlres@gsnPanelFigureStringsFontHeightF  = 0.012
  labelbar_resources(varname,pressure,pnlres)

  pnlres2@pmLabelBarHeightF                = 0.4
  pnlres2@lbOrientation                    = "vertical"
  pnlres2@gsnPanelBottom                   = 0.0
  pnlres2@gsnPanelTop                      = 0.48
  pnlres2@gsnPanelFigureStrings            = (/ "Spread" /)
  pnlres2@gsnPanelFigureStringsFontHeightF = 0.012
  labelbar_resources("spread",-1,pnlres2)

;---Get variables to be read
  data = get_NPP_data(f, varname, iz)

  x_min   = dim_min_n_Wrap(data,0)
  x_max   = dim_max_n_Wrap(data,0)
  x_mean  = dim_avg_n_Wrap(data,0)
  x2_mean = dim_avg_n_Wrap(data^2,0)
  x_spd   = sqrt(x2_mean-x_mean^2)

  map     = new(3,graphic)
  contour = new(3,graphic)

  map_spd     = gsn_csm_map(wks,map_res)  
  contour_spd = gsn_csm_contour(wks,x_spd,con_res2)
  overlay(map_spd,contour_spd)

  map_res@tmYRLabelsOn = False
  map_res@tmYROn       = False  
  map(0)     = gsn_csm_map(wks,map_res)  
  contour(0) = gsn_csm_contour(wks,x_min,con_res)
  overlay(map(0),contour(0))

  map_res@tmYLLabelsOn = False
  map_res@tmYLOn       = False  
  map(1)     = gsn_csm_map(wks,map_res)  
  contour(1) = gsn_csm_contour(wks,x_mean,con_res)
  overlay(map(1),contour(1))

  map_res@tmYRLabelsOn = True
  map_res@tmYROn       = True  
  map(2)     = gsn_csm_map(wks,map_res)  
  contour(2) = gsn_csm_contour(wks,x_max,con_res)
  overlay(map(2),contour(2))

  gsn_panel(wks,map,(/1,3/),pnlres)
  gsn_panel(wks,map_spd,(/1,1/),pnlres2)
 
  end_cpu_time = get_cpu_time()
  print(get_script_prefix_name() + " for " +varname+ ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")
end
