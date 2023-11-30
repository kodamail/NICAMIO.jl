using Printf
using DelimitedFiles
using WriteVTK

using NICAMIO

io = open("test.csv", "w")
write( io, "hx,hy,hz,lat,lon,landfrc,lakefrc,tem,riv_liq,riv_ice\n" )


# load hgrid (all)
#fhead = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78"
fhead = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78"
#nioh = nio_hgrid_open_all( fhead, 160 )
nioh = nio_hgrid_open_all( fhead, 10 )
nio_hgrid_read_all!( nioh )
nio_hgrid_set_vtkdata!( nioh )
nio_hgrid_set_latlon!( nioh )



# TODO: r and pe are mixed. remove implicit assumption of 1prc-1rgn.
for pe=0:9
#for r=0:9
#for r=0:159
#for r=0:3
#r=0
    pe6 = @sprintf(".pe%06i", pe )

#    fname1 = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/output/NICOCO_cruise/gl05rl02_m52_5year_test05/20120101-20170101/history" * pe6
#    println( fname1 )
#    ni1 = nio_open_panda( fname1 )
#    tem     = Float32.( nio_read_panda( ni1, "T", step=1, r=1, k=2, flag_undef2nan=true ) )
#    riv_liq = Float32.( nio_read_panda( ni1, "rl_runoff_ocean", step=1, r=1, k=1, flag_undef2nan=true ) )
#    riv_ice = Float32.( nio_read_panda( ni1, "rl_runoff_ocean", step=1, r=1, k=2, flag_undef2nan=true ) )
##    println(tem)

#    fname2 = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78" * pe6
    fname2 = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl00Az78pe10_m52/boundary_GL05RL00Az78" * pe6
    ni2 = nio_open_panda( fname2 )
    landfrc = Float32.( nio_read_panda( ni2, "landfrc", flag_undef2nan=true ) )
    lakefrc = Float32.( nio_read_panda( ni2, "lakefrc", flag_undef2nan=true ) )

#    fname3 = "/home/kodama/data/project/202311_NICOCO/river/ico_panda/gl05/rl02/pe160/runoff_clim1958-2019" * pe6
    fname3 = "/home/kodama/data/project/202311_NICOCO/river/ico_panda_cmp/gl05/rl00/pe10/runoff_clim1958-2019" * pe6
    ni3 = nio_open_panda( fname3 )
    #testvar = Float32.( nio_read_panda( ni3, "grd_lat", flag_undef2nan=true ) )
#    runoff_liq = Float32.( nio_read_panda( ni3, "runoff_liq", flag_undef2nan=true ) )
#    runoff_ice = Float32.( nio_read_panda( ni3, "runoff_ice", flag_undef2nan=true ) )
    runoff_liq = Float32.( nio_read_panda( ni3, "runoff_liq", step=1, flag_undef2nan=true ) )
    runoff_ice = Float32.( nio_read_panda( ni3, "runoff_ice", step=1, flag_undef2nan=true ) )
#    println(testvar)

#.pe000000

#    writedlm( io, [ nioh.data[pe+1]["hx"] nioh.data[pe+1]["hy"] nioh.data[pe+1]["hz"] nioh.lat[pe+1] nioh.lon[pe+1] landfrc lakefrc tem riv_liq riv_ice  ], ',' )

    vtk_grid("test3/test3"*pe6*".vtu", nioh.vtk_points[pe+1], nioh.vtk_cells[pe+1] ) do vtk
#        vtk["tem"]     = tem 
#        vtk["riv_liq"] = riv_liq
#        vtk["riv_ice"] = riv_ice 
        vtk["landfrc"] = landfrc
        vtk["lakefrc"] = lakefrc
        vtk["runoff_liq"] = runoff_liq
        vtk["runoff_ice"] = runoff_ice
    end

end
close(io)
