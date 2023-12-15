module NioDirect

using FortranFiles

export nio_open_direct
export nio_read_direct

import ..NioMisc: uint2char
import ..NioType: NioFile

# temporary buffer
#tmpHSHORT= Array{UInt8}(undef, 16)
#tmpHMID  = Array{UInt8}(undef, 64)
#tmpHLONG = Array{UInt8}(undef,256)

# constants
#CNST_UNDEF4 = -9.9999f30                # undefined value (REAL4)
#CNST_UNDEF8 = -9.9999e30                # undefined value (REAL8)
CNST_UNDEF4 = -9.99f34                # undefined value (REAL4), old NICAM
CNST_UNDEF8 = -9.99e34                # undefined value (REAL8), old NICAM


function nio_open_direct(
    fname::String,
    glevel::Int,
    rlevel::Int,
    precision::Int
)
    ni = NioFile( fname )
    ni.info["glevel"]   = glevel
    ni.info["rlevel"]   = rlevel
    ni.info["datatype"] = precision  # 4 or 8

    return ni
end

function nio_read_direct(
    ni::NioFile;
    #----- optional -----#
    step::Integer=1,
    flag_halo::Bool=false,
    flag_undef2nan=false
    )
    vret = Array{Any}( undef, 0 )

    idef = 2^( ni.info["glevel"] - ni.info["rlevel"] ) + 2
    jdef = idef

#    fin = FortranFile( ni.info["fname"], "r", access="direct", recl= )

#    open( ni.info["fname"], "r" ) do fin
    open( ni.fname, "r" ) do fin
        if ni.info["datatype"] == 4     # REAL4
            tmpbuf = Array{Float32}( undef, idef, jdef )
        elseif ni.info["datatype"] == 8     # REAL8
            tmpbuf = Array{Float64}( undef, idef, jdef )
	end
	
        seek( fin, (step-1)*idef*jdef )

        read!( fin, tmpbuf )
        tmpbuf .= ntoh.( tmpbuf )
	
        imin = 1 ; imax = idef
        jmin = 1 ; jmax = jdef
	if ! flag_halo
            # halo will be trimmed
	    imin = 2 ; imax = idef-1
	    jmin = 2 ; jmax = jdef-1
	end
	kmin = 1
	kmax = 1
	rmin = 1
	rmax = 1

        if flag_undef2nan == true
            if ni.info["datatype"] == 4     # REAL4
                tmpbuf[tmpbuf.==CNST_UNDEF4] .= NaN32

            elseif ni.info["datatype"] == 8 # REAL8
                tmpbuf[tmpbuf.==CNST_UNDEF8] .= NaN64
            end
        end
        append!( vret, tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax] )

    end

    return vret
end  # nio_read_direct

end
