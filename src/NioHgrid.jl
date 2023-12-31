module NioHgrid

using Printf
using FortranFiles
using WriteVTK

export NioHgridFile
export NioHgridAllFiles
export nio_hgrid_open_panda
export nio_hgrid_open_panda_all
export nio_hgrid_open_sequential
export nio_hgrid_open_sequential_all
export nio_hgrid_read!
export nio_hgrid_read_all!
export nio_hgrid_set_vtkdata!

import ..NioPanda:
    NioFile,
    nio_open_panda,
    nio_read_panda

# per pe
# (pe=region if sequential format)
mutable struct NioHgridFile
    nio::NioFile
    type::String
    glevel::Integer
    rlevel::Integer
    gmr::Integer
    gall::Integer      # Number of grids per region including halo
    gall_in::Integer   # Number of grids per region without halo
    data::Dict{String,Any}
    lat::Array{Any,1}
    lon::Array{Any,1}
    vtk_points::Any
    vtk_cells::Any
    
#    function NioHgridFile( nio::NioFile )
    function NioHgridFile( fname::String; type::String="panda", glevel::Int=-1, rlevel::Int=-1 )
        self         = new()
        self.type    = type
        if type == "sequential"
	    self.nio = NioFile( fname )
            self.nio.info["glevel"] = glevel
            self.nio.info["rlevel"] = rlevel
	elseif type == "panda"
            self.nio     = nio_open_panda( fname )
	end
        self.glevel  = self.nio.info["glevel"]
        self.rlevel  = self.nio.info["rlevel"]
	self.gmr     = self.glevel - self.rlevel
        self.gall    = (2^self.gmr+2)^2
        self.gall_in = (2^self.gmr  )^2
	return self
    end
end

# all the regions including pole
mutable struct NioHgridAllFiles
    nioh::Array{NioHgridFile,1}  # array of regional file
    pe_num::Integer  # =region_num if sequential format
    glevel::Integer
    rlevel::Integer
    gmr::Integer
    gall::Integer      # Number of grids per region including halo
    gall_in::Integer   # Number of grids per region without halo

    data_np::Array{Dict{String,Any},1}
    data_sp::Array{Dict{String,Any},1}
    vtk_points_np::Any
    vtk_points_sp::Any
    vtk_cells_np::Any
    vtk_cells_sp::Any
    
    function NioHgridAllFiles( nioh::Array{NioHgridFile,1} )
        self            = new()
	self.nioh       = nioh          # array of NioFile
	self.pe_num     = length( nioh )
        self.glevel     = nioh[1].nio.info["glevel"]
        self.rlevel     = nioh[1].nio.info["rlevel"]
	# TODO: check glevel/rlevel
	self.gmr        = self.glevel - self.rlevel
        self.gall       = (2^self.gmr+2)^2
        self.gall_in    = (2^self.gmr  )^2
	return self
    end
end


# PANDA format
function nio_hgrid_open_panda( fname::String )
    return NioHgridFile( fname )
end


# sequential format
function nio_hgrid_open_sequential( fname::String, glevel::Int, rlevel::Int )
    return NioHgridFile( fname, type="sequential", glevel=glevel, rlevel=rlevel )
end


# PANDA format, all regions
function nio_hgrid_open_panda_all( fhead::String, pe_num::Integer )
    nioh = Array{NioHgridFile}(undef,pe_num)

    for pe=0:pe_num-1
        pe6 = @sprintf(".pe%06i", pe )
	fname = fhead * pe6
        nioh[pe+1] = nio_hgrid_open_panda( fname )
    end
    
    return NioHgridAllFiles( nioh )
end


# sequential format, all regions, assuming 1rgn/prc
function nio_hgrid_open_sequential_all( fhead::String, glevel::Int, rlevel::Int )
    pe_num = 10*4^rlevel
    nioh = Array{NioHgridFile}(undef,pe_num)

    for pe=0:pe_num-1
        re5 = @sprintf(".rgn%05i", pe )
	fname = fhead * re5
        nioh[pe+1] = nio_hgrid_open_sequential( fname, glevel, rlevel )
    end
    
    return NioHgridAllFiles( nioh )
end


# read region(s) of a process
function nio_hgrid_read!( nioh::NioHgridFile )
    nioh.data = Dict(
        "hx"  => [], "hy"  => [], "hz"  => [],
        "hix" => [], "hiy" => [], "hiz" => [],
        "hjx" => [], "hjy" => [], "hjz" => [] )

    if nioh.type == "sequential"
        fin = FortranFile( nioh.nio.fname, convert="big-endian" )
	read( fin )  # skip
        idef = 2^( nioh.nio.info["glevel"] - nioh.nio.info["rlevel"] ) + 2
        jdef = idef
	tmpbuf = Array{Float64}( undef, idef, jdef, 1, 1 )
	read( fin, tmpbuf )
        nioh.data["hx"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
	read( fin, tmpbuf )
        nioh.data["hy"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
	read( fin, tmpbuf )
        nioh.data["hz"] = reshape(tmpbuf[2:idef-1,2:jdef-1,1,1],:)
	tmpbuf = Array{Float64}( undef, idef, jdef, 2, 1 )
	read( fin, tmpbuf )
        nioh.data["hix"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
        nioh.data["hjx"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)
	read( fin, tmpbuf )
        nioh.data["hiy"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
        nioh.data["hjy"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)
	read( fin, tmpbuf )
        nioh.data["hiz"] = reshape(tmpbuf[1:idef,1:jdef,1,1],:)
        nioh.data["hjz"] = reshape(tmpbuf[1:idef,1:jdef,2,1],:)
	close(fin)
	
    elseif nioh.type == "panda"
        nioh.data["hx"] = nio_read_panda( nioh.nio, "grd_x_x" )  # TODO: unify halo treatment with hix, ...
        nioh.data["hy"] = nio_read_panda( nioh.nio, "grd_x_y" )
        nioh.data["hz"] = nio_read_panda( nioh.nio, "grd_x_z" )
        #
        nioh.data["hix"] = nio_read_panda( nioh.nio, "grd_xt_ix", flag_halo=true )
        nioh.data["hiy"] = nio_read_panda( nioh.nio, "grd_xt_iy", flag_halo=true )
        nioh.data["hiz"] = nio_read_panda( nioh.nio, "grd_xt_iz", flag_halo=true )
        nioh.data["hjx"] = nio_read_panda( nioh.nio, "grd_xt_jx", flag_halo=true )
        nioh.data["hjy"] = nio_read_panda( nioh.nio, "grd_xt_jy", flag_halo=true )
        nioh.data["hjz"] = nio_read_panda( nioh.nio, "grd_xt_jz", flag_halo=true )

    end

    # set latlon
    latlon = xyz2latlon.( nioh.data["hx"], nioh.data["hy"], nioh.data["hz"] )
    nioh.lat = first.(latlon)
    nioh.lon = last.(latlon)
end


# read all the regions
function nio_hgrid_read_all!( nioh_all::NioHgridAllFiles )
    hz_max = Array{Any}(undef,nioh_all.pe_num)  # for searching pole
    for pe=0:nioh_all.pe_num-1
        nio_hgrid_read!( nioh_all.nioh[pe+1] )
        hz_max[pe+1] = maximum( nioh_all.nioh[pe+1].data["hz"] )
    end

    pei_np = sortperm(hz_max,rev=true )[1:5]   # PE indices for NP
    pei_sp = sortperm(hz_max,rev=false)[1:5]   # PE indices for SP
    println(pei_np)
    println(pei_sp)
    lon_np = Array{Any}(undef,5)
    lon_sp = Array{Any}(undef,5)
    for i=1:5
        lon_np[i] = nioh_all.nioh[pei_np[i]].lon[(2^nioh_all.gmr)*(2^nioh_all.gmr-1)+1]  # next to NP grid
        lon_sp[i] = nioh_all.nioh[pei_sp[i]].lon[2^nioh_all.gmr]                         # next to SP grid
    end
    display(lon_np)
    #display(lon_sp)
    pei2_np = sortperm(lon_np,rev=false)[1:5]
    pei2_sp = sortperm(lon_sp,rev=false)[1:5]
    display(pei2_np)
    #display(pei2_sp)

    nioh_all.data_np = Array{Dict{String,Any}}(undef,5)
    nioh_all.data_sp = Array{Dict{String,Any}}(undef,5)

    for i=1:5
        nioh_all.data_np[i] = Dict()
        nioh_all.data_sp[i] = Dict()
        nioh_all.data_np[i]["cellx"] = nioh_all.nioh[pei_np[pei2_np[i]]].data["hjx"][(2^nioh_all.gmr+2)*(2^nioh_all.gmr)+2]
        nioh_all.data_np[i]["celly"] = nioh_all.nioh[pei_np[pei2_np[i]]].data["hjy"][(2^nioh_all.gmr+2)*(2^nioh_all.gmr)+2]
        nioh_all.data_np[i]["cellz"] = nioh_all.nioh[pei_np[pei2_np[i]]].data["hjz"][(2^nioh_all.gmr+2)*(2^nioh_all.gmr)+2]
        nioh_all.data_sp[i]["cellx"] = nioh_all.nioh[pei_sp[pei2_sp[i]]].data["hix"][(2^nioh_all.gmr+2)*2-1]
        nioh_all.data_sp[i]["celly"] = nioh_all.nioh[pei_sp[pei2_sp[i]]].data["hiy"][(2^nioh_all.gmr+2)*2-1]
        nioh_all.data_sp[i]["cellz"] = nioh_all.nioh[pei_sp[pei2_sp[i]]].data["hiz"][(2^nioh_all.gmr+2)*2-1]
    end

    display(nioh_all.data_np[1:5])
#    display(nioh_all.data_sp[1:5])
	
end


function nio_hgrid_set_vtkdata!( nioh_all::NioHgridAllFiles )
    ij2p(T)      = T[1] + (T[2]-1) * (2^nioh_all.gmr)
    p2ij(p)      = (p-1) % (2^nioh_all.gmr) + 1, (p-1) ÷ (2^nioh_all.gmr) + 1
    ij2p_halo(T) = (T[1]+1) + T[2] * (2^nioh_all.gmr+2)
    p2ij_halo(p) = (p-1) % (2^nioh_all.gmr+2), (p-1) ÷ (2^nioh_all.gmr+2)

    ijm(T)   = T[1]  , T[2]-1
    imj(T)   = T[1]-1, T[2]
    imjm(T)  = T[1]-1, T[2]-1

    for pe=0:nioh_all.pe_num-1
        nioh_all.nioh[pe+1].vtk_points = Float32.(
	    [ nioh_all.nioh[pe+1].data["hix"]' nioh_all.nioh[pe+1].data["hjx"]' ;
              nioh_all.nioh[pe+1].data["hiy"]' nioh_all.nioh[pe+1].data["hjy"]' ;
	      nioh_all.nioh[pe+1].data["hiz"]' nioh_all.nioh[pe+1].data["hjz"]' ])
        nioh_all.nioh[pe+1].vtk_cells = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, nioh_all.gall_in )  # TODO: add halo cell if necessary
  
	joffset = nioh_all.gall

	for p=1 : nioh_all.gall_in  # p: no halo  px: with halo
            p1 = ij2p_halo(p2ij(p)) + joffset
	    p2 = ij2p_halo(p2ij(p))
	    p3 = ij2p_halo(ijm(p2ij(p))) + joffset
	    p4 = ij2p_halo(imjm(p2ij(p)))
	    p5 = ij2p_halo(imjm(p2ij(p))) + joffset
	    p6 = ij2p_halo(imj(p2ij(p)))
            nioh_all.nioh[pe+1].vtk_cells[p] = MeshCell(VTKCellTypes.VTK_POLYGON, [ p1,p2,p3,p4,p5,p6 ])
        end
    end

    nioh_all.vtk_points_np = Float32.(
	    [ nioh_all.data_np[1]["cellx"] nioh_all.data_np[2]["cellx"] nioh_all.data_np[3]["cellx"] nioh_all.data_np[4]["cellx"] nioh_all.data_np[5]["cellx"] ;
              nioh_all.data_np[1]["celly"] nioh_all.data_np[2]["celly"] nioh_all.data_np[3]["celly"] nioh_all.data_np[4]["celly"] nioh_all.data_np[5]["celly"] ;
              nioh_all.data_np[1]["cellz"] nioh_all.data_np[2]["cellz"] nioh_all.data_np[3]["cellz"] nioh_all.data_np[4]["cellz"] nioh_all.data_np[5]["cellz"] ])
    nioh_all.vtk_cells_np = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, 1 )
    nioh_all.vtk_cells_np[1] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 1, 2, 3, 4, 5 ])
    #
    nioh_all.vtk_points_sp = Float32.(
	    [ nioh_all.data_sp[1]["cellx"] nioh_all.data_sp[2]["cellx"] nioh_all.data_sp[3]["cellx"] nioh_all.data_sp[4]["cellx"] nioh_all.data_sp[5]["cellx"] ;
              nioh_all.data_sp[1]["celly"] nioh_all.data_sp[2]["celly"] nioh_all.data_sp[3]["celly"] nioh_all.data_sp[4]["celly"] nioh_all.data_sp[5]["celly"] ;
              nioh_all.data_sp[1]["cellz"] nioh_all.data_sp[2]["cellz"] nioh_all.data_sp[3]["cellz"] nioh_all.data_sp[4]["cellz"] nioh_all.data_sp[5]["cellz"] ])
    nioh_all.vtk_cells_sp = Array{MeshCell{VTKCellType,Array{Int64,1}}}( undef, 1 )
    nioh_all.vtk_cells_sp[1] = MeshCell(VTKCellTypes.VTK_POLYGON, [ 1, 2, 3, 4, 5 ])

end


# From NICAM/share/mod_vector.f90
function xyz2latlon( x, y, z )
    length = sqrt( x*x + y*y + z*z )
    EPS = 1.e-16
    lat = 0.0
    lon = 0.0

    if length < EPS
       lat = 0.0
       lon = 0.0
       return lat, lon

    elseif z / length >= 1.0  # vector is parallele to z axis.
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

    elseif x / length_h >= 1.0
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
