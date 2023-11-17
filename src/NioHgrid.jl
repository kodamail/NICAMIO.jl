module NioHgrid
using Printf
using WriteVTK

export NioHgridInfo
#export readHgrid
export nio_hgrid_open
export nio_hgrid_open_all
export nio_hgrid_read
export nio_hgrid_read_all!
export nio_hgrid_set_vtkdata!

export xyz2latlon

import ..NioPanda:
    NioFile,
    nio_open_panda,
    nio_read_panda

mutable struct NioHgridInfo
    nio::NioFile
    glevel::Integer
    rlevel::Integer
    gmr::Integer
#    data::Dict{String,Any}
    gall::Integer      # Number of grids per region including halo
    gall_in::Integer   # Number of grids per region without halo

#    function NioHgridInfo( glevel, rlevel )
    function NioHgridInfo( nio )
        self = new()
	self.nio = nio
#        self.glevel = glevel
#        self.rlevel = rlevel
        self.glevel = nio.info["glevel"]
        self.rlevel = nio.info["rlevel"]
	self.gmr = self.glevel - self.rlevel
        self.gall    = (2^self.gmr+2)^2
        self.gall_in = (2^self.gmr  )^2

#	self.hx = Array()
#        self.data = Dict(
#	    "hx" => []
#	)
	return self
    end
end

mutable struct NioHgridAllData
    nio::Array{NioFile,1}
    pe_num::Integer
    glevel::Integer
    rlevel::Integer
    gmr::Integer
    gall::Integer      # Number of grids per region including halo
    gall_in::Integer   # Number of grids per region without halo
    data::Array{Dict{String,Any},1}
#    vtk_points::Array{Array{Float32,1},1}
    vtk_points::Array{Any,1}
#    vtk_cells::Array{MeshCell{VTKCellType,Array{Int64,2}}}
    vtk_cells::Array{Any,1}
    
    function NioHgridAllData( nio )
        self = new()
	self.nio = nio
	self.pe_num = length(nio)
        self.glevel = nio[1].info["glevel"]
        self.rlevel = nio[1].info["rlevel"]
	self.gmr = self.glevel - self.rlevel
        self.gall    = (2^self.gmr+2)^2
        self.gall_in = (2^self.gmr  )^2
	self.data = Array{Dict{String,Any}}(undef,self.pe_num)
	self.vtk_points = Array{Any}(undef,self.pe_num)
	self.vtk_cells = Array{Any}(undef,self.pe_num)
	return self
    end
end

function nio_hgrid_open( fname::String )
    nio = nio_open_panda( fname )
    nioh = NioHgridInfo( nio )
    return nioh
end
function nio_hgrid_open_all( fhead::String, pe_num::Integer )
#    nioh = NioHgridAllData( nio )
    nio = Array{NioFile}(undef,pe_num)
    
    for pe=0:pe_num-1
        pe6 = @sprintf(".pe%06i", pe )
	fname = fhead * pe6
        nio[pe+1] = nio_open_panda( fname )
    end
    
    nioh = NioHgridAllData( nio )

    return nioh
end

function nio_hgrid_read( nioh::NioHgridInfo )
    hgrid = Dict(
        "hx" => [],
        "hy" => [],
        "hz" => [],
        "hix" => [],
        "hiy" => [],
        "hiz" => [],
        "hjx" => [],
        "hjy" => [],
        "hjz" => []
    )

#    nio = nio_open_panda( fname )
    hgrid["hx"] = nio_read_panda( nioh.nio, "grd_x_x" )  # TODO: unify halo treatment with hix, ...
    hgrid["hy"] = nio_read_panda( nioh.nio, "grd_x_y" )
    hgrid["hz"] = nio_read_panda( nioh.nio, "grd_x_z" )

    hgrid["hix"] = nio_read_panda( nioh.nio, "grd_xt_ix", flag_halo=true )
    hgrid["hiy"] = nio_read_panda( nioh.nio, "grd_xt_iy", flag_halo=true )
    hgrid["hiz"] = nio_read_panda( nioh.nio, "grd_xt_iz", flag_halo=true )
    hgrid["hjx"] = nio_read_panda( nioh.nio, "grd_xt_jx", flag_halo=true )
    hgrid["hjy"] = nio_read_panda( nioh.nio, "grd_xt_jy", flag_halo=true )
    hgrid["hjz"] = nio_read_panda( nioh.nio, "grd_xt_jz", flag_halo=true )

    return hgrid
end

function nio_hgrid_read_all!( nioh::NioHgridAllData )
    #pe_np = [ -1 -1 -1 -1 -1 ]
    #pe_sp = [ -1 -1 -1 -1 -1 ]
    #hz_np = [ 0.0 0.0 0.0 0.0 0.0 ]  # from closer to NP
    #hz_sp = [ 0.0 0.0 0.0 0.0 0.0 ]  # from closer to SP

    hz_max = Array{Any}(undef,nioh.pe_num)
    

    for pe=0:nioh.pe_num-1
        nioh.data[pe+1] = Dict(
            "hx" => [],
            "hy" => [],
            "hz" => [],
            "hix" => [],
            "hiy" => [],
            "hiz" => [],
            "hjx" => [],
            "hjy" => [],
            "hjz" => []
	)
        nioh.data[pe+1]["hx"] = nio_read_panda( nioh.nio[pe+1], "grd_x_x" )  # TODO: unify halo treatment with hix, ...
        nioh.data[pe+1]["hy"] = nio_read_panda( nioh.nio[pe+1], "grd_x_y" )
        nioh.data[pe+1]["hz"] = nio_read_panda( nioh.nio[pe+1], "grd_x_z" )

        nioh.data[pe+1]["hix"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_ix", flag_halo=true )
        nioh.data[pe+1]["hiy"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_iy", flag_halo=true )
        nioh.data[pe+1]["hiz"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_iz", flag_halo=true )
        nioh.data[pe+1]["hjx"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_jx", flag_halo=true )
        nioh.data[pe+1]["hjy"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_jy", flag_halo=true )
        nioh.data[pe+1]["hjz"] = nio_read_panda( nioh.nio[pe+1], "grd_xt_jz", flag_halo=true )

        hz_max[pe+1] = maximum( nioh.data[pe+1]["hz"] )
    end


    pe_np = sortperm(hz_max,rev=true)[1:5] .- 1
#    pe_np .= pe_np .- 1

    pe_sp = sortperm(hz_max)[1:5] .- 1
#    pe_sp .= pe_sp .- 1
    
    println(pe_np)
    println(pe_sp)
    println("ok")
end


function nio_hgrid_set_vtkdata!( nioh::NioHgridAllData )
#    nioh.vtk_points = Array{Array{Float32,1}}(undef,nioh.pe_num)
    for pe=0:nioh.pe_num-1
        nioh.vtk_points[pe+1] = Float32.(
	    [ nioh.data[pe+1]["hix"]' nioh.data[pe+1]["hjx"]' ;
              nioh.data[pe+1]["hiy"]' nioh.data[pe+1]["hjy"]' ;
	      nioh.data[pe+1]["hiz"]' nioh.data[pe+1]["hjz"]' ])
        nioh.vtk_cells[pe+1] = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, nioh.gall_in )  # TODO: add halo cell if necessary
  
	joffset = nioh.gall

        ij2p(T) = T[1] + (T[2]-1) * (2^nioh.gmr)
        p2ij(p) = (p-1) % (2^nioh.gmr) + 1, (p-1) ÷ (2^nioh.gmr) + 1
        ij2p_halo(T) = (T[1]+1) + T[2] * (2^nioh.gmr+2)
        p2ij_halo(p) = (p-1) % (2^nioh.gmr+2), (p-1) ÷ (2^nioh.gmr+2)

        ijm(T)   = T[1]  , T[2]-1
        imj(T)   = T[1]-1, T[2]
        imjm(T)  = T[1]-1, T[2]-1


	for p=1 : nioh.gall_in  # p: no halo  px: with halo
            p1 = ij2p_halo(p2ij(p)) + joffset
	    p2 = ij2p_halo(p2ij(p))
	    p3 = ij2p_halo(ijm(p2ij(p))) + joffset
	    p4 = ij2p_halo(imjm(p2ij(p)))
	    p5 = ij2p_halo(imjm(p2ij(p))) + joffset
	    p6 = ij2p_halo(imj(p2ij(p)))
            nioh.vtk_cells[pe+1][p] = MeshCell(VTKCellTypes.VTK_POLYGON, [ p1,p2,p3,p4,p5,p6 ])
        end


    end

end


# From NICAM/share/mod_vector.f90
function xyz2latlon( x, y, z )
    length = sqrt( x*x + y*y + z*z )
    EPS = 1.e-16
    lat = 0.0
    lon = 0.0

    if length < EPS  # 3D vector length is
       lat = 0.0
       lon = 0.0
       return lat, lon
    end

    if  z / length >= 1.0  # vector is parallele to z axis.
       lat = asin( 1.0 )
       lon = 0.0
       return lat, lon
    elseif z / length <= -1.0  # vector is parallele to z axis.
       lat = asin( -1.0 )
       lon = 0.0
       return lat, lon
    else
       lat = asin( z / length )
    end

    length_h = sqrt( x*x + y*y )

    if length_h < EPS
       lon = 0.0
       return lat, lon
    end

    if x / length_h >= 1.0
       lon = acos( 1.0 )
    elseif x / length_h <= -1.0
       lon = acos( -1.0 )
    else
       lon = acos( x / length_h )
    end

    if y < 0.0
        lon = -lon
    end

    return lat, lon
end


end
