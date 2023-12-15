module NioPanda

export nio_open_panda
export nio_read_panda

import ..NioMisc: uint2char
import ..NioType: NioFile

# temporary buffer
tmpHSHORT= Array{UInt8}(undef, 16)
tmpHMID  = Array{UInt8}(undef, 64)
tmpHLONG = Array{UInt8}(undef,256)

# constants
#CNST_UNDEF4 = -9.9999f30                # undefined value (REAL4)
#CNST_UNDEF8 = -9.9999e30                # undefined value (REAL8)
CNST_UNDEF4 = -9.99f34                # undefined value (REAL4), old NICAM
CNST_UNDEF8 = -9.99e34                # undefined value (REAL8), old NICAM


function nio_open_panda(
    fname::String; 
    #----- optional -----#
    flag_showinfo::Bool=false
)
    ni = NioFile( fname )
    
    open( fname, "r" ) do fin
        #
    	# Package header
	#
        readbytes!( fin, tmpHMID )
	ni.info["desc"] = join( uint2char.(tmpHMID) )

        readbytes!( fin, tmpHLONG )
	ni.info["note"] = join( uint2char.(tmpHLONG) )

	ni.info["fmode"]         = ntoh( read( fin, Int32 ) )
	ni.info["endiantype"]    = ntoh( read( fin, Int32 ) )
	ni.info["grid_topology"] = ntoh( read( fin, Int32 ) )
	ni.info["glevel"]        = ntoh( read( fin, Int32 ) )
	ni.info["rlevel"]        = ntoh( read( fin, Int32 ) )
	ni.info["num_of_rgn"]    = ntoh( read( fin, Int32 ) )

        ni.info["rgnid"] = Array{Int32}( undef, ni.info["num_of_rgn"] )
        for i=1 : ni.info["num_of_rgn"]
            ni.info["rgnid"][i] = ntoh( read( fin, Int32 ) )
	end

	ni.info["num_of_data"]    = ntoh( read( fin, Int32 ) )

        if flag_showinfo
	    println( fname * " header information:" )
            display( ni.info )
	end

	ni.info["dinfo"] = Array{Dict}( undef, ni.info["num_of_data"] )
#	ni.data_pos = position( fin )  # preserve

        #
        # Data Header
	#
        for i=1 : ni.info["num_of_data"]
#	    println(i)
            ni.info["dinfo"][i] = Dict()
	    
            readbytes!( fin, tmpHSHORT )
	    ni.info["dinfo"][i]["varname"] = join( uint2char.(tmpHSHORT) )

            readbytes!( fin, tmpHMID )
	    ni.info["dinfo"][i]["description"] = join( uint2char.(tmpHMID) )

            readbytes!( fin, tmpHSHORT )
	    ni.info["dinfo"][i]["unit"] = join( uint2char.(tmpHSHORT) )

            readbytes!( fin, tmpHSHORT )
	    ni.info["dinfo"][i]["layername"] = join( uint2char.(tmpHSHORT) )

            readbytes!( fin, tmpHLONG )
	    ni.info["dinfo"][i]["note"] = join( uint2char.(tmpHLONG) )

            ni.info["dinfo"][i]["datasize"]     = ntoh( read( fin, Int64 ) )  # sum of all the regions
            ni.info["dinfo"][i]["datatype"]     = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["num_of_layer"] = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["step"]         = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["time_start"]   = ntoh( read( fin, Int64 ) )
            ni.info["dinfo"][i]["time_end"]     = ntoh( read( fin, Int64 ) )

            if flag_showinfo
                println( "data-", i, " header information:" )
                display( ni.info["dinfo"][i] )
            end

            ni.info["dinfo"][i]["data_pos"] = position( fin )  # keep start position of each data content
            skip( fin, ni.info["dinfo"][i]["datasize"] )

        end
    end  # open

    return ni
end

function nio_read_panda(
    ni::NioFile,
    varname::String;
    #----- optional -----#
    step::Integer=-1,
    r::Integer=-1,    # region (>=1)
    k::Integer=-1,
    flag_halo::Bool=false,
    flag_undef2nan=false
    )
    vret = Array{Any}( undef, 0 )

    idef = 2^( ni.info["glevel"] - ni.info["rlevel"] ) + 2
    jdef = idef
    rdef = ni.info["num_of_rgn"]

    open( ni.fname, "r" ) do fin

        # Data
        for i=1 : ni.info["num_of_data"]
	    varname != ni.info["dinfo"][i]["varname"] && continue
	    step != ni.info["dinfo"][i]["step"] && step != -1 && continue

            kdef = ni.info["dinfo"][i]["num_of_layer"]

            imin = 1 ; imax = idef
            jmin = 1 ; jmax = jdef
	    if ! flag_halo
                # halo will be trimmed
	        imin = 2 ; imax = idef-1
	        jmin = 2 ; jmax = jdef-1
	    end
            kmin = 1 ; kmax = kdef
            if k > 0
                kmin = k ; kmax = k
            end
            rmin = 1 ; rmax = rdef
            if r > 0
                rmin = r ; rmax = r
            end

            seek( fin, ni.info["dinfo"][i]["data_pos"] )

            if ni.info["dinfo"][i]["datatype"] == 0     # REAL4
                tmpbuf = Array{Float32}( undef, idef, jdef, kdef, rdef )
            elseif ni.info["dinfo"][i]["datatype"] == 1 # REAL8
                tmpbuf = Array{Float64}( undef, idef, jdef, kdef, rdef )
            else
	        return nothing
	    end
	    
            read!( fin, tmpbuf )
	    tmpbuf .= ntoh.( tmpbuf )

            if flag_undef2nan == true
                if ni.info["dinfo"][i]["datatype"] == 0     # REAL4
                    tmpbuf[tmpbuf.==CNST_UNDEF4] .= NaN32
#                    tmpbuf[tmpbuf.<=9.99e33] .= NaN32

                elseif ni.info["dinfo"][i]["datatype"] == 1 # REAL8
                    tmpbuf[tmpbuf.==CNST_UNDEF8] .= NaN64
		end
            end
            append!( vret, tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax] )
        end
    end

    return vret
end  # nio_read_panda

end
