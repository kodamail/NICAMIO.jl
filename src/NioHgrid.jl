module NioHgrid

export NioHgridInfo
#export readHgrid
export nio_hgrid_read

export xyz2latlon

import ..NioPanda:
    nio_open_panda,
    nio_read_panda


#mutable struct NICAMIOhgridData
mutable struct NioHgridInfo
    glevel::Integer
    rlevel::Integer
    gmr::Integer
#    data::Dict{String,Any}

    function NioHgridInfo( glevel, rlevel )
        self = new()
        self.glevel = glevel
        self.rlevel = rlevel
	self.gmr = glevel - rlevel
#	self.hx = Array()
#        self.data = Dict(
#	    "hx" => []
#	)
	return self
    end
end

function nio_hgrid_read( niohd::NioHgridInfo, fname::String )
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

    nio = nio_open_panda( fname )
    hgrid["hx"] = nio_read_panda( nio, "grd_x_x" )  # TODO: unify halo treatment with hix, ...
    hgrid["hy"] = nio_read_panda( nio, "grd_x_y" )
    hgrid["hz"] = nio_read_panda( nio, "grd_x_z" )

    hgrid["hix"] = nio_read_panda( nio, "grd_xt_ix", flag_halo=true )
    hgrid["hiy"] = nio_read_panda( nio, "grd_xt_iy", flag_halo=true )
    hgrid["hiz"] = nio_read_panda( nio, "grd_xt_iz", flag_halo=true )
    hgrid["hjx"] = nio_read_panda( nio, "grd_xt_jx", flag_halo=true )
    hgrid["hjy"] = nio_read_panda( nio, "grd_xt_jy", flag_halo=true )
    hgrid["hjz"] = nio_read_panda( nio, "grd_xt_jz", flag_halo=true )

    return hgrid
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
