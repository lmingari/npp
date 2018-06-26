begin
  start_write_time = get_cpu_time()

;---Output Filename
  if(.not.isvar("fname")) then
    fname = "npp_out_short.nc"
    print("fname not defined, assuming: " + fname)
  end if

;---NETCDF4 configuration
  NC4       = True
  NCchunk   = True
  NCcompr   = True
  nm_chunck = 1
  nz_chunck = 1

;---List of WRF output files
  if(.not.isvar("basepath")) then
    basepath = "./"
    print("basepath not defined, assuming: " + basepath)
  end if

  if(.not.isvar("ftime")) then
    ftime = 0
    print("ftime not defined, assuming: " + ftime)
  end if

  nfiles    = 60
  dd        = ispan(1,nfiles+1,1)
  files     = basepath + sprinti("%0.2i/", dd) + sprinti("wrfout%0.2i.nc", ftime)

;---Open files using addfiles
  f         = addfiles(basepath+files,"r")

;---Get variables to be read
  XLAT      = wrf_user_getvar(f[0],"lat",0)
  XLON      = wrf_user_getvar(f[0],"lon",0)

  PSFC      = wrf_user_getvar(f,"PSFC",-1)
  T2        = wrf_user_getvar(f,"T2", -1)
  Q2        = wrf_user_getvar(f,"Q2", -1)
  V10       = wrf_user_getvar(f,"V10",-1)
  U10       = wrf_user_getvar(f,"U10",-1)
  rain_exp  = wrf_user_getvar(f,"RAINNC",-1)
  rain_con  = wrf_user_getvar(f,"RAINC", -1)

  V         = wrf_user_getvar(f,"va",-1)
  U         = wrf_user_getvar(f,"ua",-1)
  T         = wrf_user_getvar(f,"tk",-1)
  Q         = wrf_user_getvar(f,"QVAPOR",-1)
  G         = wrf_user_getvar(f,"geopotential",-1)
  DBZ       = wrf_user_getvar(f,"dbz", -1)

;---Define variable levels
  LEV               = (/1000,975,925,850,700,500,300,200/)
  LEV@unit          = "hPa"
  LEV@long_name     = "Pressure"

  LEV_AGL           = (/1.,4./)
  LEV_AGL@unit      = "m"
  LEV_AGL@long_name = "Height (agl)"

;---Vertical interpolation
  opts             = True
  opts@logP        = True 
  opts@extrapolate = True 
  opts@field_type  = "none"

  vert_coord       = "pressure"
  U_intrp = wrf_user_vert_interp(f,U,vert_coord,LEV,opts)
  V_intrp = wrf_user_vert_interp(f,V,vert_coord,LEV,opts)
  T_intrp = wrf_user_vert_interp(f,T,vert_coord,LEV,opts)
  Q_intrp = wrf_user_vert_interp(f,Q,vert_coord,LEV,opts)
  G_intrp = wrf_user_vert_interp(f,G,vert_coord,LEV,opts)

  vert_coord = "ght_agl"
  REFL    = wrf_user_vert_interp(f,DBZ,vert_coord,LEV_AGL,opts)

;===================================================================
;---Define Variable attributes
;===================================================================
  sLEV             = toshort(LEV)
  sLEV@long_name   = "Pressure"
  sLEV@unit        = "hPa"

  delete_VarAtts(XLAT, -1)
  sXLAT            = pack_values(XLAT,"short",False)
  sXLAT@long_name  = "Latitude"
  sXLAT@unit       = "degree_north"

  delete_VarAtts(XLON, -1)
  sXLON            = pack_values(XLON,"short",False)
  sXLON@long_name  = "Longitude"
  sXLON@unit       = "degree_east"

  delete_VarAtts(PSFC, -1)
  PSFC             = PSFC*1E-2
  sPSFC            = pack_values(PSFC,"short",False)
  sPSFC@long_name  = "Surface Pressure"
  sPSFC@unit       = "hPa"

  delete_VarAtts(T2, -1)
  ;T2               = T2 - 273.15
  sT2              = pack_values(T2,"short",False)
  sT2@long_name    = "2-m Temperature"
  sT2@unit         = "K"

  delete_VarAtts(Q2, -1)
  Q2               = 1E3*Q2
  sQ2              = pack_values(Q2,"short",False)
  sQ2@long_name    = "2-m Water Vapor mixing ratio"
  sQ2@unit         = "g kg-1"

  delete_VarAtts(U10, -1)
  sU10             = pack_values(U10,"short",False)
  sU10@long_name   = "10-m x-wind component"
  sU10@unit        = "m s-1"
  
  delete_VarAtts(V10, -1)
  sV10             = pack_values(V10,"short",False)
  sV10@long_name   = "10-m y-wind component"
  sV10@unit        = "m s-1"

  PP               = rain_exp + rain_con
  sPP              = pack_values(PP,"short",False)
  sPP@long_name    = "Accumulated total precipitation"
  sPP@unit         = "mm"

  rmAtts = (/"FieldType","MemoryOrder",\
             "description","units",\
             "stagger","coordinates"/)
  
  delete_VarAtts(U_intrp, rmAtts)
  sU_intrp             = pack_values(U_intrp,"short",False)
  sU_intrp@long_name   = "x-wind component"
  sU_intrp@unit        = "m s-1"

  delete_VarAtts(V_intrp, rmAtts)
  sV_intrp             = pack_values(V_intrp,"short",False)
  sV_intrp@long_name   = "y-wind component"
  sV_intrp@unit        = "m s-1"

  delete_VarAtts(T_intrp, rmAtts)
  sT_intrp             = pack_values(T_intrp,"short",False)
  sT_intrp@long_name   = "Temperature"
  sT_intrp@unit        = "C"

  delete_VarAtts(Q_intrp, rmAtts)
  sQ_intrp             = pack_values(Q_intrp,"short",False)
  sQ_intrp@long_name   = "Water vapor mixing ratio"
  sQ_intrp@unit        = "kg kg-1"

  delete_VarAtts(G_intrp, rmAtts)
  G_intrp              = G_intrp/9.81
  sG_intrp             = pack_values(G_intrp,"short",False)
  sG_intrp@long_name   = "Geopotential Height"
  sG_intrp@unit        = "m"

  delete_VarAtts(REFL, rmAtts)
  REFL1KM              = REFL(:,0,:,:)
  sREFL1KM             = pack_values(REFL1KM,"short",False)
  sREFL1KM@long_name   = "Reflectivity at 1km agl"
  sREFL1KM@unit        = "dBZ"

  REFL4KM              = REFL(:,1,:,:)
  sREFL4KM             = pack_values(REFL4KM,"short",False)
  sREFL4KM@long_name   = "Reflectivity at 4km agl"
  sREFL4KM@unit        = "dBZ"

  MDBZ                 = dim_max_n_Wrap(DBZ,1)
  delete_VarAtts(MDBZ, rmAtts)
  sMDBZ                = pack_values(MDBZ,"short",False)
  sMDBZ@long_name      = "Max Reflectivity"
  sMDBZ@unit           = "dBZ"

;===================================================================
;---Create a new NetCDF file
;===================================================================
  setfileoption("nc","preFill",False)
  setfileoption("nc","defineMode",True)

  if(NC4) then
    setfileoption("nc","Format","NetCDF4Classic")
    if(NCcompr) then
      setfileoption("nc","CompressionLevel",1)
    end if
  else
    setfileoption("nc","Format","64BitOffset")
  end if
  
;---Open a new NetCDF file to write to
  system("rm -f " + fname)
  fout = addfile(fname,"c")

;---Define the dimension names and their sizes on the file
  dims           = dimsizes(U_intrp)
  nm             = dims(0)
  nz             = dims(1)
  ny             = dims(2)
  nx             = dims(3)

  dim_names1D    = (/"lev"/)
  dim_names2D    = (/"lat","lon"/)
  dim_names3D    = (/"ens","lat","lon"/)
  dim_names4D    = (/"ens","lev","lat","lon"/)
  dim_ints       = (/nm,nz,ny,nx/)
  dim_unlimited  = (/False,False,False,False/)
  filedimdef(fout,dim_names4D,dim_ints,dim_unlimited)

  if(NC4 .and. NCchunk) then
    chunk_sizes2D = (/ny,nx/)
    chunk_sizes3D = (/nm_chunck,ny,nx/)
    chunk_sizes4D = (/nm_chunck,nz_chunck,ny,nx/)
    filechunkdimdef(fout,dim_names4D,chunk_sizes4D,dim_unlimited)
  end if

;---Create global attributes of the file
  fAtt               = True
  fAtt@creation_date = systemfunc ("date")
  fAtt@MAP_PROJ      = f[0]@MAP_PROJ
  fAtt@MAP_PROJ_CHAR = f[0]@MAP_PROJ_CHAR
  fAtt@STAND_LON     = f[0]@STAND_LON
  fAtt@CEN_LON       = f[0]@CEN_LON
  fAtt@TRUELAT1      = f[0]@TRUELAT1
  fAtt@TRUELAT2      = f[0]@TRUELAT2
  fAtt@start_lat     = XLAT(0,0)
  fAtt@start_lon     = XLON(0,0)
  fAtt@end_lat       = XLAT(ny-1,nx-1)
  fAtt@end_lon       = XLON(ny-1,nx-1)
  fAtt@FORECAST_HOUR = ftime
  fAtt@ANALYSIS      = False
  fAtt@START_DATE    = f[0]@START_DATE
  fAtt@title         = "NCL PostProcessing for WRF-ARW Ensemble"
  fileattdef(fout,fAtt)

;---Define each variable, its type, its dimension names, and its size
  varType = "short"
  filevardef(fout,"LEV",  varType, dim_names1D)

  filevardef(fout,"XLAT", varType, dim_names2D)
  filevardef(fout,"XLON", varType, dim_names2D)

  filevardef(fout,"PSFC", varType, dim_names3D)
  filevardef(fout,"T2",   varType, dim_names3D)
  filevardef(fout,"Q2",   varType, dim_names3D)
  filevardef(fout,"U10",  varType, dim_names3D)
  filevardef(fout,"V10",  varType, dim_names3D)
  filevardef(fout,"PP",   varType, dim_names3D)

  filevardef(fout,"REFL1KM", varType, dim_names3D)
  filevardef(fout,"REFL4KM", varType, dim_names3D)
  filevardef(fout,"MDBZ",    varType, dim_names3D)

  filevardef(fout,"U",    varType, dim_names4D)
  filevardef(fout,"V",    varType, dim_names4D)
  filevardef(fout,"T",    varType, dim_names4D)
  filevardef(fout,"Q",    varType, dim_names4D)
  filevardef(fout,"HGT",  varType, dim_names4D)

;---Define each variable's attributes.
  filevarattdef(fout,"LEV", sLEV)
  filevarattdef(fout,"XLAT", sXLAT)
  filevarattdef(fout,"XLON", sXLON)

  filevarattdef(fout,"PSFC", sPSFC)
  filevarattdef(fout,"T2",   sT2)
  filevarattdef(fout,"Q2",   sQ2)
  filevarattdef(fout,"V10",  sV10)
  filevarattdef(fout,"U10",  sU10)
  filevarattdef(fout,"PP",   sPP)

  filevarattdef(fout,"REFL1KM", sREFL1KM)
  filevarattdef(fout,"REFL4KM", sREFL4KM)
  filevarattdef(fout,"MDBZ",    sMDBZ)

  filevarattdef(fout,"U",   sU_intrp)
  filevarattdef(fout,"V",   sV_intrp)
  filevarattdef(fout,"T",   sT_intrp)
  filevarattdef(fout,"Q",   sQ_intrp)
  filevarattdef(fout,"HGT", sG_intrp)

;---Chunking
  if(NC4 .and. NCchunk) then
    filevarchunkdef(fout, "XLAT", chunk_sizes2D)
    filevarchunkdef(fout, "XLON", chunk_sizes2D)

    filevarchunkdef(fout, "PSFC", chunk_sizes3D)
    filevarchunkdef(fout, "T2",   chunk_sizes3D)
    filevarchunkdef(fout, "Q2",   chunk_sizes3D)
    filevarchunkdef(fout, "V10",  chunk_sizes3D)
    filevarchunkdef(fout, "U10",  chunk_sizes3D)
    filevarchunkdef(fout, "PP",   chunk_sizes3D)

    filevarchunkdef(fout,"REFL1KM", chunk_sizes3D)
    filevarchunkdef(fout,"REFL4KM", chunk_sizes3D)
    filevarchunkdef(fout,"MDBZ",    chunk_sizes3D)

    filevarchunkdef(fout, "U",   chunk_sizes4D)
    filevarchunkdef(fout, "V",   chunk_sizes4D)
    filevarchunkdef(fout, "T",   chunk_sizes4D)
    filevarchunkdef(fout, "Q",   chunk_sizes4D)
    filevarchunkdef(fout, "HGT", chunk_sizes4D)
  end if

;---NOW write the variables to the file.
  fout->LEV  = (/sLEV/)

  fout->XLAT = (/sXLAT/)
  fout->XLON = (/sXLON/)

  fout->PSFC = (/sPSFC/)
  fout->T2   = (/sT2/)
  fout->Q2   = (/sQ2/)
  fout->U10  = (/sU10/)
  fout->V10  = (/sV10/)
  fout->PP   = (/sPP/)

  fout->REFL1KM = (/sREFL1KM/)
  fout->REFL4KM = (/sREFL4KM/)
  fout->MDBZ    = (/sMDBZ/)

  fout->U    = (/sU_intrp/)
  fout->V    = (/sV_intrp/)
  fout->T    = (/sT_intrp/)
  fout->Q    = (/sQ_intrp/)
  fout->HGT   = (/sG_intrp/)

  end_write_time = get_cpu_time()
  print(get_script_prefix_name() + ": elapsed time = " + (end_write_time-start_write_time) + " seconds.")

;---Close file
  delete(fout)
  delete(f)
end