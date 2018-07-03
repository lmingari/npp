begin
  start_cpu_time = get_cpu_time()

;---NPP output file
path = "../"
fname = "npp_out"

;---Open files using addfiles
  f = addfile(path+fname+".nc","r")

;---Open workstation
  wks_type = "png"
  wks = gsn_open_wks(wks_type,"map-only")

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
  map_res@mpNationalLineColor         = "gray50"
  map_res@mpGeophysicalLineColor      = "gray50"
  map_res@mpNationalLineThicknessF    = 1.5
  map_res@mpGeophysicalLineThicknessF = 1.5
  map_res@mpMaskOutlineSpecifiers     = "Argentina"
  
  map_res@tmXBLabelFontHeightF        = 0.012
  map_res@tmXTLabelFontHeightF        = 0.012
  map_res@tmYLLabelFontHeightF        = 0.012
  map_res@tmYRLabelFontHeightF        = 0.012
  map_res@tmYRLabelJust               = "CenterCenter"  
  map_res@tmYLLabelJust               = "CenterCenter"
  map_res@tmYRLabelAngleF             = 90
  map_res@tmYLLabelAngleF             = 90
  
  map_res@tmBorderThicknessF          = 2.0
  map_res@tmXBMajorThicknessF         = 2.0
  map_res@tmXTMajorThicknessF         = 2.0
  map_res@tmYRMajorThicknessF         = 2.0
  map_res@tmYLMajorThicknessF         = 2.0

  map_res@pmTickMarkDisplayMode       = "Always"

  map_res@mpGridAndLimbOn             = True
  map_res@mpGridLatSpacingF           = 2
  map_res@mpGridLonSpacingF           = 2
  map_res@mpGridLineThicknessF        = 0.5
  map_res@mpGridLineDashPattern       = 1

;---Section to add polylines to map.
  lnres                  = True           ; resource list for polylines
  lnres@gsLineColor      = "gray50"
  lnres@gsLineThicknessF = 1.5
  
  map     = gsn_csm_map(wks,map_res)  
  id      = gsn_add_shapefile_polylines(wks,map,"provincias/ARG_adm1.shp",lnres)


  draw(map)   ; This will draw attached polylines and map
  frame(wks)   ; Advanced frame.

 end
