using Printf
using DelimitedFiles
using WriteVTK

using NICAMIO

#gmr = 5 - 2  # glevel - rlevel

#ij2p(T) = T[1] + (T[2]-1) * (2^gmr)
#p2ij(p) = (p-1) % (2^gmr) + 1, (p-1) ÷ (2^gmr) + 1
#ij2p_halo(T) = (T[1]+1) + T[2] * (2^gmr+2)
#p2ij_halo(p) = (p-1) % (2^gmr+2), (p-1) ÷ (2^gmr+2)

#ijm(T)   = T[1]  , T[2]-1
#imj(T)   = T[1]-1, T[2]
#imjm(T)  = T[1]-1, T[2]-1

io = open("test.csv", "w")
write( io, "hx,hy,hz,lat,lon,landfrc,lakefrc,tem,riv_liq,riv_ice\n" )

#niohd = NioHgridInfo( 5, 2 )


fhead = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78"
nioh = nio_hgrid_open_all( fhead, 160 )
nio_hgrid_read_all!( nioh )

nio_hgrid_set_vtkdata!( nioh )



# TODO: r and pe are mixed. remove implicit assumption of 1prc-1rgn.
for r=0:159
#for r=0:3
#r=0
    pe6 = @sprintf(".pe%06i", r )

    fname1 = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/output/NICOCO_cruise/gl05rl02_m52_5year_test05/20120101-20170101/history" * pe6
    println( fname1 )
    ni1 = nio_open_panda( fname1 )
    tem     = nio_read_panda( ni1, "T", step=1, r=1, k=5 )
    riv_liq = nio_read_panda( ni1, "rl_runoff_ocean", step=1, r=1, k=1 )
    riv_ice = nio_read_panda( ni1, "rl_runoff_ocean", step=1, r=1, k=2 )

    fname2 = "/home/kodama/data/make_NICAM_DATABASE_CMIP6/NICAM_DATABASE_CMIP6/raw_data/aerosol_nat/NICOCO_kodama/input_NICAM/PANDA/boundary/gl05rl02Az78pe160_m52/boundary_GL05RL02Az78" * pe6
#    nioh = nio_hgrid_open( fname2 )
#    hgrid = nio_hgrid_read( nioh )

    ni2 = nio_open_panda( fname2 )
    landfrc = nio_read_panda( ni2, "landfrc" )
    lakefrc = nio_read_panda( ni2, "lakefrc" )


#    points = Float32.([ hgrid["hix"]' hgrid["hjx"]' ;
#                        hgrid["hiy"]' hgrid["hjy"]' ;
#			hgrid["hiz"]' hgrid["hjz"]' ])  # only Float32 is accepted
#    joffset=length( hgrid["hix"] )
#    joffset = nioh.gall

#    cells = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, length(hgrid["hx"]) )
#    cells = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, nioh.gall_in )  # TODO: add halo cell if necessary
    
#    for p=1 : length(hgrid["hx"])  # p: no halo  px: with halo
#    for p=1 : nioh.gall_in  # p: no halo  px: with halo
#        p1 = ij2p_halo(p2ij(p)) + joffset
#	p2 = ij2p_halo(p2ij(p))
#	p3 = ij2p_halo(ijm(p2ij(p))) + joffset
#	p4 = ij2p_halo(imjm(p2ij(p)))
#	p5 = ij2p_halo(imjm(p2ij(p))) + joffset
#	p6 = ij2p_halo(imj(p2ij(p)))
#        cells[p] = MeshCell(VTKCellTypes.VTK_POLYGON, [ p1,p2,p3,p4,p5,p6 ])
#    end

    #latlon = xyz2latlon.( hgrid["hx"], hgrid["hy"], hgrid["hz"] )
    #lat = first.(latlon)
    #lon = last.(latlon)

    riv_liq = Float32.(riv_liq)
    riv_ice = Float32.(riv_ice)
    tem = Float32.(tem)
    landfrc = Float32.(landfrc)
    lakefrc = Float32.(lakefrc)

    riv_liq[riv_liq.<=-9.99e33] .= NaN32
    riv_ice[riv_ice.<=-9.99e33] .= NaN32
    tem[tem.<=-9.99e33] .= NaN32
    #writedlm( io, [ hgrid["hx"] hgrid["hy"] hgrid["hz"] lat lon landfrc lakefrc tem riv_liq riv_ice  ], ',' )

#    vtk_grid("test3/test3"*pe6*".vtu", points, cells ) do vtk
    vtk_grid("test3/test3"*pe6*".vtu", nioh.vtk_points[r+1], nioh.vtk_cells[r+1] ) do vtk
        vtk["tem"]     = tem 
        vtk["riv_liq"] = riv_liq
        vtk["riv_ice"] = riv_ice 
        vtk["landfrc"] = landfrc
        vtk["lakefrc"] = lakefrc
    end

end
close(io)
