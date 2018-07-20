
;--------------------------------------------------------------------------------
; Get NPP data
;--------------------------------------------------------------------------------
undef ("get_NPP_data")
function get_NPP_data(nc_file[1]:file, variable_name[1]:string, iz[1]:integer)
local data, U, V
begin

  if(iz.ge.0) then

    if(variable_name.eq."SPD") then
      if (getfilevartypes(nc_file,"U").eq."short") then
        U = short2flt( nc_file->U(:,iz,:,:) )
        V = short2flt( nc_file->V(:,iz,:,:) )
      else
        U = nc_file->U(:,iz,:,:)
        V = nc_file->V(:,iz,:,:)
      end if
      data = sqrt(U^2+V^2)
      copy_VarMeta(U, data)
      data@long_name = "Wind Speed"
    else
      if (getfilevartypes(nc_file,variable_name).eq."short") then
        data = short2flt( nc_file->$variable_name$(:,iz,:,:) )
      else
        data = nc_file->$variable_name$(:,iz,:,:)
      end if
    end if

  else

    if(variable_name.eq."SPD10") then
      if (getfilevartypes(nc_file,"U10").eq."short") then
        U = short2flt( nc_file->U10 )
        V = short2flt( nc_file->V10 )
      else
        U = nc_file->U10
        V = nc_file->V10
      end if
      data = sqrt(U^2+V^2)
      copy_VarMeta(U, data)
      data@long_name = "Wind Speed at 10m"
    else
      if (getfilevartypes(nc_file,variable_name).eq."short") then
        data = short2flt( nc_file->$variable_name$ )
      else
        data = nc_file->$variable_name$
      end if
    end if

  end if

  if(variable_name.eq."T2" .or. variable_name.eq."T") then
    data = data - 273.15
    data@unit = "C"
  end if

  return(data)
end
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Set Resources for filled contour
;--------------------------------------------------------------------------------
undef("contour_resources")
procedure contour_resources(variable_name[1]:string, pressure[1]:numeric, opt_arg[1]:logical)
local cmap
begin

  if(pressure.gt.0) then

    if(variable_name.eq."Q") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      if(pressure.le.500) then  
        opt_arg@cnMinLevelValF  = 0.25
        opt_arg@cnMaxLevelValF  = 4
        opt_arg@cnLevelSpacingF = 0.25
      else
        opt_arg@cnMinLevelValF  = 3
        opt_arg@cnMaxLevelValF  = 16
        opt_arg@cnLevelSpacingF = 1
      end if
    end if

    if(variable_name.eq."SPD") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      if(pressure.lt.500) then
        opt_arg@cnMinLevelValF  = 30
        opt_arg@cnMaxLevelValF  = 50
        opt_arg@cnLevelSpacingF = 2
      else if(pressure.le.850) then
        opt_arg@cnMinLevelValF  = 2
        opt_arg@cnMaxLevelValF  = 26
        opt_arg@cnLevelSpacingF = 2
      else
        opt_arg@cnMinLevelValF  = 1
        opt_arg@cnMaxLevelValF  = 15
        opt_arg@cnLevelSpacingF = 1
      end if
      end if
    end if  

    if(variable_name.eq."T") then
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      if(pressure.le.300) then
        opt_arg@cnMinLevelValF  = -70
        opt_arg@cnMaxLevelValF  = -55
        opt_arg@cnLevelSpacingF = 1
      else if(pressure.le.500) then
        opt_arg@cnMinLevelValF  = -34
        opt_arg@cnMaxLevelValF  = -20
        opt_arg@cnLevelSpacingF = 1
      else if(pressure.le.700) then
        opt_arg@cnMinLevelValF  = -4
        opt_arg@cnMaxLevelValF  = 14
        opt_arg@cnLevelSpacingF = 1
      else if(pressure.le.850) then
        opt_arg@cnMinLevelValF  = -1
        opt_arg@cnMaxLevelValF  = 22
        opt_arg@cnLevelSpacingF = 1
      else if(pressure.le.925) then
        opt_arg@cnMinLevelValF  = 2
        opt_arg@cnMaxLevelValF  = 26
        opt_arg@cnLevelSpacingF = 2
      else
        opt_arg@cnMinLevelValF  = 6
        opt_arg@cnMaxLevelValF  = 36
        opt_arg@cnLevelSpacingF = 2
      end if
      end if
      end if
      end if
      end if
    end if  

    if(variable_name.eq."HGT") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 6
      opt_arg@cnMaxLevelValF  = 30
      opt_arg@cnLevelSpacingF = 2
    end if  

  else

    if(variable_name.eq."PP") then
      opt_arg@cnRasterModeOn  = True
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 1
      opt_arg@cnMaxLevelValF  = 15
      opt_arg@cnLevelSpacingF = 1
      opt_arg@cnFillPalette   = "precip2_17lev"
    end if

    if( any( variable_name .eq. (/"MDBZ","REFL1KM","REFL4KM"/) ) ) then
      cmap = read_colormap_file("./palettes/radar_new.rgb")
      opt_arg@cnRasterModeOn  = True
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = -25
      opt_arg@cnMaxLevelValF  = 70
      opt_arg@cnLevelSpacingF = 5.0
      opt_arg@cnFillPalette   = cmap
    end if

    if(variable_name.eq."Q2") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 3
      opt_arg@cnMaxLevelValF  = 16
      opt_arg@cnLevelSpacingF = 1
    end if

    if(variable_name.eq."SPD10") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 1
      opt_arg@cnMaxLevelValF  = 14
      opt_arg@cnLevelSpacingF = 1
    end if

    if(variable_name.eq."T2") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 6
      opt_arg@cnMaxLevelValF  = 36
      opt_arg@cnLevelSpacingF = 2.0
    end if

    if(variable_name.eq."PSFC") then
      opt_arg@cnRasterModeOn  = False
      opt_arg@cnLevelSelectionMode = "ManualLevels"
      opt_arg@cnMinLevelValF  = 900
      opt_arg@cnMaxLevelValF  = 1040
      opt_arg@cnLevelSpacingF = 10
      ;opt_arg@cnFillPalette   = "MPL_viridis"
    end if

    if(variable_name.eq."spread") then
      opt_arg@cnRasterModeOn       = False
      opt_arg@cnLevelSelectionMode = "AutomaticLevels"
      opt_arg@cnFillPalette        = "MPL_viridis"
    end if

  end if

end
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Set Resources for labelbar
;--------------------------------------------------------------------------------
undef("labelbar_resources")
procedure labelbar_resources(variable_name[1]:string, pressure[1]:numeric, opt_arg[1]:logical)
begin

  if(pressure.gt.0) then

    if(variable_name.eq."Q") then
      opt_arg@lbTitleString    = "Water Vapor mixing ratio at " + pressure + " hPa (g/kg)"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if    

    if(variable_name.eq."SPD") then
      opt_arg@lbTitleString    = "Wind speed at " + pressure + " hPa (m/s)"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if  

    if(variable_name.eq."T") then
      opt_arg@lbTitleString    = "Temperature at " + pressure + " hPa (~F34~0~F~C)"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if  

    if(variable_name.eq."HGT") then
      opt_arg@lbTitleString    = "Geopotential Height at " + pressure + " hPa (m)"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if

  else

    if(variable_name.eq."MDBZ") then
      opt_arg@lbTitleString    = "Max Reflectivity (dBZ)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."REFL1KM") then
      opt_arg@lbTitleString    = "Reflectivity at 1km agl (dBZ)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."REFL4KM") then
      opt_arg@lbTitleString    = "Reflectivity at 4km agl (dBZ)"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if

    if(variable_name.eq."PP") then
      opt_arg@lbTitleString    = "Accumulated Precipitation (mm)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."PSFC") then
      opt_arg@lbTitleString    = "Surface Pressure (hPa)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."Q2") then
      opt_arg@lbTitleString    = "2-m Water Vapor mixing ratio (g/kg)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."SPD10") then
      opt_arg@lbTitleString    = "Wind speed at 10m (m/s)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."T2") then
      opt_arg@lbTitleString    = "Temperature (~F34~0~F~C)"
      opt_arg@lbBoxEndCapStyle = "TriangleHighEnd"
    end if

    if(variable_name.eq."spread") then
      opt_arg@lbTitleString    = "Spread"
      opt_arg@lbBoxEndCapStyle = "TriangleBothEnds"
    end if

  end if

end
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Set Resources for map
;--------------------------------------------------------------------------------
undef("map_resourcesx1")
procedure map_resourcesx1(nc_file:file, opt_arg[1]:logical)
begin

  opt_arg@mpProjection                = "LambertConformal"
  opt_arg@mpLambertParallel1F         = nc_file@TRUELAT1
  opt_arg@mpLambertParallel2F         = nc_file@TRUELAT2
  opt_arg@mpLambertMeridianF          = nc_file@STAND_LON
  opt_arg@mpLimitMode                 = "Corners"
  opt_arg@mpLeftCornerLatF            = nc_file@start_lat
  opt_arg@mpLeftCornerLonF            = nc_file@start_lon
  opt_arg@mpRightCornerLatF           = nc_file@end_lat
  opt_arg@mpRightCornerLonF           = nc_file@end_lon

  opt_arg@mpFillOn                    = False
  opt_arg@mpOutlineOn                 = True
  opt_arg@mpDataBaseVersion           = "MediumRes"
  opt_arg@mpDataSetName               = "Earth..4"
  opt_arg@mpOutlineDrawOrder          = "PostDraw"

  opt_arg@mpOutlineBoundarySets       = "National"
  opt_arg@mpNationalLineColor         = "Black"
  opt_arg@mpGeophysicalLineColor      = "Black"
  opt_arg@mpNationalLineThicknessF    = 2.0
  opt_arg@mpGeophysicalLineThicknessF = 2.0
  ;opt_arg@mpMaskOutlineSpecifiers     = "Argentina"

  opt_arg@tmXBLabelFontHeightF        = 0.012
  opt_arg@tmXTLabelFontHeightF        = 0.012
  opt_arg@tmYLLabelFontHeightF        = 0.012
  opt_arg@tmYRLabelFontHeightF        = 0.012
  opt_arg@tmYRLabelJust               = "CenterCenter"
  opt_arg@tmYLLabelJust               = "CenterCenter"
  opt_arg@tmYRLabelAngleF             = 90
  opt_arg@tmYLLabelAngleF             = 90

  opt_arg@tmBorderThicknessF          = 1.2
  opt_arg@tmXBMajorThicknessF         = 1.2
  opt_arg@tmXTMajorThicknessF         = 1.2
  opt_arg@tmYRMajorThicknessF         = 1.2
  opt_arg@tmYLMajorThicknessF         = 1.2

  opt_arg@pmTickMarkDisplayMode       = "Always"

end
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Set Resources for map - Panel x60 version
;--------------------------------------------------------------------------------
undef("map_resourcesx60")
procedure map_resourcesx60(nc_file:file, opt_arg[1]:logical)
begin

  opt_arg@mpProjection                = "LambertConformal"
  opt_arg@mpLambertParallel1F         = nc_file@TRUELAT1
  opt_arg@mpLambertParallel2F         = nc_file@TRUELAT2
  opt_arg@mpLambertMeridianF          = nc_file@STAND_LON
  opt_arg@mpLimitMode                 = "Corners"
  opt_arg@mpLeftCornerLatF            = nc_file@start_lat
  opt_arg@mpLeftCornerLonF            = nc_file@start_lon
  opt_arg@mpRightCornerLatF           = nc_file@end_lat
  opt_arg@mpRightCornerLonF           = nc_file@end_lon

  opt_arg@mpFillOn                    = False
  opt_arg@mpOutlineOn                 = True
  opt_arg@mpDataBaseVersion           = "MediumRes"
  opt_arg@mpDataSetName               = "Earth..4"
  opt_arg@mpOutlineDrawOrder          = "PostDraw"

  opt_arg@mpOutlineBoundarySets       = "National"
  opt_arg@mpNationalLineColor         = "Black"
  opt_arg@mpGeophysicalLineColor      = "Black"
  opt_arg@mpNationalLineThicknessF    = 0.2
  opt_arg@mpGeophysicalLineThicknessF = 0.2
  ;opt_arg@mpMaskOutlineSpecifiers     = "Argentina"

  opt_arg@tmXBLabelFontHeightF        = 0.012
  opt_arg@tmXTLabelFontHeightF        = 0.012
  opt_arg@tmYLLabelFontHeightF        = 0.012
  opt_arg@tmYRLabelFontHeightF        = 0.012
  opt_arg@tmYRLabelJust               = "CenterCenter"
  opt_arg@tmYLLabelJust               = "CenterCenter"
  opt_arg@tmYRLabelAngleF             = 90
  opt_arg@tmYLLabelAngleF             = 90

  opt_arg@tmBorderThicknessF          = 0.1
  opt_arg@tmXBMajorThicknessF         = 0.1
  opt_arg@tmXTMajorThicknessF         = 0.1
  opt_arg@tmYRMajorThicknessF         = 0.1
  opt_arg@tmYLMajorThicknessF         = 0.1

  opt_arg@pmTickMarkDisplayMode       = "Always"

end
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; Load IMERG data in a 2D array
;--------------------------------------------------------------------------------
undef ("LoadIMERG")
function LoadIMERG(fname:string)
local nlat, nlon, lat1d, lon1d, temp1D, temp2D
begin
  nlat  = 132
  nlon  = 122
  data  = asciiread(fname,(/nlat*nlon,3/),"float")

  lat1d = data(::nlon,1)
  lon1d = data(0:nlon-1,0)

  temp1D = data(:,2)
  temp2D = onedtond(temp1D,(/nlat,nlon/))

  temp2D!0 = "lat"
  temp2D!1 = "lon"

  temp2D&lat = lat1d
  temp2D&lon = lon1d

  temp2D = smth9_Wrap(temp2D, 0.50, 0.25, True)

  return temp2D
end
;--------------------------------------------------------------------------------
