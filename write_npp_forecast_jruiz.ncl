begin
  start_write_time = get_cpu_time()

;---NETCDF4 configuration
  NC4       = True
  NCround   = False
  NCchunk   = True
  NCcompr   = True
  nm_chunck = 1
  nz_chunck = 1

;---Required inputs
  if(.not.isvar("hf")) then
    hf = 0
    print("hf not defined, assuming: " + hf)
  end if

  if(isvar("y") .and. isvar("m") .and. isvar("d") .and. isvar("h")) then
    hf@units = sprinti("hours since %0.4i-", y) + \
               sprinti("%0.2i-", m) + \
               sprinti("%0.2i ", d) + \
               sprinti("%0.2i:00:00", h) 
  else
    print("Required input: y, m, d, h. Closing...")
    exit()
  end if

  BASEDIR = getenv("BASEDIR")
  if(ismissing(BASEDIR)) then
    BASEDIR = "/glade/scratch/jruiz/EXP/PRONOGFS/"
    print("BASEDIR not defined, assuming: " + BASEDIR)
  end if

  fdate = ut_calendar(hf, 0)
  y2    = tointeger(fdate(:,0))
  m2    = tointeger(fdate(:,1))
  d2    = tointeger(fdate(:,2))
  h2    = tointeger(fdate(:,3))

  path_in   = sprinti("%0.4i-", y) + \
              sprinti("%0.2i-", m) + \
              sprinti("%0.2i_", d) + \
              sprinti("%0.2i_00_00/", h)
  fname_in  = "wrfout_d01_" + \
              sprinti("%0.4i-", y2) + \
              sprinti("%0.2i-", m2) + \
              sprinti("%0.2i_", d2) + \
              sprinti("%0.2i:00:00", h2)
  path_out  = "./"
  fname_out = sprinti("NPP_%0.4i-", y) + \
              sprinti("%0.2i-", m) + \
              sprinti("%0.2i_", d) + \
              sprinti("%0.2i_", h) + \
              sprinti("FC%0.2i.nc", hf) 

;---List of WRF output files
  nfiles    = 60
  dd        = ispan(1,nfiles,1)  
;----
;Parche: to be removed !!
;---
  dd(19) = 19
  dd(39) = 39
  dd(59) = 59
  print(dd)
;---
;
;---
  files     = BASEDIR + "FCST/" + \
              path_in + \
              sprinti("%0.5i/", dd) + \
              fname_in

;---Open files using addfiles
  f         = addfiles(files,"r")

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
  opts              = True
  opts@logP         = True 
  opts@extrapolate  = True 
  opts@field_type   = "none"

  vert_coord = "pressure"
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
  delete_VarAtts(XLAT, -1)
  XLAT@long_name  = "Latitude"
  XLAT@unit       = "degree_north"

  delete_VarAtts(XLON, -1)
  XLON@long_name  = "Longitude"
  XLON@unit       = "degree_east"

  delete_VarAtts(PSFC, -1)
  PSFC            = PSFC*1E-2
  PSFC@long_name  = "Surface Pressure"
  PSFC@unit       = "hPa"

  delete_VarAtts(T2, -1)
  ;T2              = T2 - 273.15
  T2@long_name    = "2-m Temperature"
  T2@unit         = "K"

  delete_VarAtts(Q2, -1)
  Q2              = 1E3*Q2
  Q2@long_name    = "2-m Water Vapor mixing ratio"
  Q2@unit         = "g kg-1"

  delete_VarAtts(U10, -1)
  U10@long_name   = "10-m x-wind component"
  U10@unit        = "m s-1"
  
  delete_VarAtts(V10, -1)
  V10@long_name   = "10-m y-wind component"
  V10@unit        = "m s-1"

  PP              = rain_exp + rain_con
  PP@long_name    = "Accumulated total precipitation"
  PP@unit         = "mm"

  rmAtts = (/"FieldType","MemoryOrder",\
             "description","units",\
             "stagger","coordinates"/)
  
  delete_VarAtts(U_intrp, rmAtts)
  U_intrp@long_name   = "x-wind component"
  U_intrp@unit        = "m s-1"

  delete_VarAtts(V_intrp, rmAtts)
  V_intrp@long_name   = "y-wind component"
  V_intrp@unit        = "m s-1"

  delete_VarAtts(T_intrp, rmAtts)
  T_intrp@long_name   = "Temperature"
  T_intrp@unit        = "K"

  delete_VarAtts(Q_intrp, rmAtts)
  Q_intrp             = 1E3*Q_intrp
  Q_intrp@long_name   = "Water vapor mixing ratio"
  Q_intrp@unit        = "g kg-1"

  delete_VarAtts(G_intrp, rmAtts)
  G_intrp             = G_intrp/9.81
  G_intrp@long_name   = "Geopotential Height"
  G_intrp@unit        = "m"

  delete_VarAtts(REFL, rmAtts)
  REFL1KM             = REFL(:,0,:,:)
  REFL1KM@long_name   = "Reflectivity at 1km agl"
  REFL1KM@unit        = "dBZ"

  REFL4KM             = REFL(:,1,:,:)  
  REFL4KM@long_name   = "Reflectivity at 4km agl"
  REFL4KM@unit        = "dBZ"

  MDBZ                = dim_max_n_Wrap(DBZ,1)
  delete_VarAtts(MDBZ, rmAtts)
  MDBZ@long_name      = "Max Reflectivity"
  MDBZ@unit           = "dBZ"

  if(NC4 .and. NCround) then
    bin_exp = 16
    scale   = 2^bin_exp
    dec_exp = toshort(floor(bin_exp*0.30103))

    PSFC@least_significant_digit = dec_exp
    PSFC = round(PSFC*scale,0)/scale
    
    T2@least_significant_digit = dec_exp
    T2 = round(T2*scale,0)/scale

    Q2@least_significant_digit = dec_exp
    Q2 = round(Q2*scale,0)/scale

    U10@least_significant_digit = dec_exp
    U10 = round(U10*scale,0)/scale
    
    V10@least_significant_digit = dec_exp
    V10 = round(V10*scale,0)/scale
    
    PP@least_significant_digit = dec_exp
    PP = round(PP*scale,0)/scale

    REFL1KM@least_significant_digit = dec_exp
    REFL1KM = round(REFL1KM*scale,0)/scale

    REFL4KM@least_significant_digit = dec_exp
    REFL4KM = round(REFL4KM*scale,0)/scale

    MDBZ@least_significant_digit = dec_exp
    MDBZ = round(MDBZ*scale,0)/scale

    U_intrp@least_significant_digit = dec_exp
    U_intrp = round(U_intrp*scale,0)/scale

    V_intrp@least_significant_digit = dec_exp
    V_intrp = round(V_intrp*scale,0)/scale

    T_intrp@least_significant_digit = dec_exp
    T_intrp = round(T_intrp*scale,0)/scale

    Q_intrp@least_significant_digit = dec_exp
    Q_intrp = round(Q_intrp*scale,0)/scale

    G_intrp@least_significant_digit = dec_exp
    G_intrp = round(G_intrp*scale,0)/scale
  end if

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
  system("rm -f " + path_out + fname_out)
  fout = addfile(path_out + fname_out,"c")

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
  fAtt@start_lat     = XLAT(0,0)
  fAtt@start_lon     = XLON(0,0)
  fAtt@end_lat       = XLAT(ny-1,nx-1)
  fAtt@end_lon       = XLON(ny-1,nx-1)
  fAtt@MAP_PROJ      = f[0]@MAP_PROJ
  fAtt@MAP_PROJ_CHAR = f[0]@MAP_PROJ_CHAR
  fAtt@STAND_LON     = f[0]@STAND_LON
  fAtt@CEN_LON       = f[0]@CEN_LON
  fAtt@TRUELAT1      = f[0]@TRUELAT1
  fAtt@TRUELAT2      = f[0]@TRUELAT2
  fAtt@FORECAST_HOUR = hf
  fAtt@FORECAST      = True
  fAtt@ANALYSIS      = False
  fAtt@START_DATE    = f[0]@START_DATE
  fAtt@title         = "NCL PostProcessing for WRF-ARW Ensemble"
  fileattdef(fout,fAtt)

;---Define each variable, its type, its dimension names, and its size
  filevardef(fout,"LEV",  typeof(LEV),  dim_names1D)

  filevardef(fout,"XLAT", typeof(XLAT), dim_names2D)
  filevardef(fout,"XLON", typeof(XLON), dim_names2D)

  filevardef(fout,"PSFC", typeof(PSFC), dim_names3D)
  filevardef(fout,"T2",   typeof(T2),   dim_names3D)
  filevardef(fout,"Q2",   typeof(Q2),   dim_names3D)
  filevardef(fout,"U10",  typeof(U10),  dim_names3D)
  filevardef(fout,"V10",  typeof(V10),  dim_names3D)
  filevardef(fout,"PP",   typeof(PP),   dim_names3D)

  filevardef(fout,"REFL1KM", typeof(REFL1KM), dim_names3D)
  filevardef(fout,"REFL4KM", typeof(REFL4KM), dim_names3D)
  filevardef(fout,"MDBZ",    typeof(MDBZ),    dim_names3D)

  filevardef(fout,"U",  typeof(U_intrp), dim_names4D)
  filevardef(fout,"V",  typeof(V_intrp), dim_names4D)
  filevardef(fout,"T",  typeof(T_intrp), dim_names4D)
  filevardef(fout,"Q",  typeof(Q_intrp), dim_names4D)
  filevardef(fout,"HGT", typeof(G_intrp), dim_names4D)

;---Define each variable's attributes.
  filevarattdef(fout,"LEV",  LEV)
  filevarattdef(fout,"XLAT", XLAT)
  filevarattdef(fout,"XLON", XLON)

  filevarattdef(fout,"PSFC", PSFC)
  filevarattdef(fout,"T2",   T2)
  filevarattdef(fout,"Q2",   Q2)
  filevarattdef(fout,"V10",  V10)
  filevarattdef(fout,"U10",  U10)
  filevarattdef(fout,"PP",   PP)

  filevarattdef(fout,"REFL1KM", REFL1KM)
  filevarattdef(fout,"REFL4KM", REFL4KM)
  filevarattdef(fout,"MDBZ",    MDBZ)

  filevarattdef(fout,"U",  U_intrp)
  filevarattdef(fout,"V",  V_intrp)
  filevarattdef(fout,"T",  T_intrp)
  filevarattdef(fout,"Q",  Q_intrp)
  filevarattdef(fout,"HGT", G_intrp)

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
  fout->LEV     = (/LEV/)

  fout->XLAT    = (/XLAT/)
  fout->XLON    = (/XLON/)

  fout->PSFC    = (/PSFC/)
  fout->T2      = (/T2/)
  fout->Q2      = (/Q2/)
  fout->U10     = (/U10/)
  fout->V10     = (/V10/)
  fout->PP      = (/PP/)

  fout->REFL1KM = (/REFL1KM/)
  fout->REFL4KM = (/REFL4KM/)
  fout->MDBZ    = (/MDBZ/)

  fout->U       = (/U_intrp/)
  fout->V       = (/V_intrp/)
  fout->T       = (/T_intrp/)
  fout->Q       = (/Q_intrp/)
  fout->HGT     = (/G_intrp/)

  end_write_time = get_cpu_time()
  print(get_script_prefix_name() + ": elapsed time = " + (end_write_time-start_write_time) + " seconds.")

;---Close file
  delete(fout)
  delete(f)
end
