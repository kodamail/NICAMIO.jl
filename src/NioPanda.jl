module NioPanda

export nio_open_panda
export nio_read_panda


import ..NioMisc: uint2char
import ..NioType: NioFile

# temporary buffer
tmpHSHORT= Array{UInt8}(undef, 16)
tmpHMID  = Array{UInt8}(undef, 64)
tmpHLONG = Array{UInt8}(undef,256)



#function niopenPanda( fname::String )
function nio_open_panda( fname::String )
#    println("Hello11")
#    ni = NICAMIOFile( fname )
    ni = NioFile( fname )

    
    open( fname, "r" ) do fin

    	# Header
        readbytes!( fin, tmpHMID )
	ni.info["desc"] = join( uint2char.(tmpHMID) )

#    println(ni)
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
#	    println(i)
            ni.info["rgnid"][i] = ntoh( read( fin, Int32 ) )
	end

	ni.info["num_of_data"]    = ntoh( read( fin, Int32 ) )
#	info["dinfo"] = Array{Dict{String,Any}}( undef, info["num_of_data"] )
	ni.info["dinfo"] = Array{Dict}( undef, ni.info["num_of_data"] )

	ni.data_pos = position( fin )

        # Data
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

            ni.info["dinfo"][i]["datasize"]     = ntoh( read( fin, Int64 ) )
            ni.info["dinfo"][i]["datatype"]     = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["num_of_layer"] = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["step"]         = ntoh( read( fin, Int32 ) )
            ni.info["dinfo"][i]["time_start"]   = ntoh( read( fin, Int64 ) )
            ni.info["dinfo"][i]["time_end"]     = ntoh( read( fin, Int64 ) )


            ni.info["dinfo"][i]["data_pos"] = position( fin )
            skip( fin, ni.info["dinfo"][i]["datasize"] )

#        println(info["dinfo"][i]["data"][end-100:end])
#	break
        end
#info
#ni.info
    end

    return ni
end

function nio_read_panda(
#    ni::NICAMIOFile,
    ni::NioFile,
    varname::String;
    #----- optional -----#
    step::Integer=-1,
    r::Integer=-1,    # region
    k::Integer=-1,
    flag_halo::Bool=false
)
    vret = Array{Any}( undef, 0 )


    open( ni.fname, "r" ) do fin

        # Data
        for i=1 : ni.info["num_of_data"]
	    varname != ni.info["dinfo"][i]["varname"] && continue
	    step != ni.info["dinfo"][i]["step"] && step != -1 && continue

	    idef = 2^( ni.info["glevel"] - ni.info["rlevel"] ) + 2
	    jdef = idef
            kdef = ni.info["dinfo"][i]["num_of_layer"]
	    rdef = ni.info["num_of_rgn"]

            imin = 1 ; imax = idef
            jmin = 1 ; jmax = jdef
	    if ! flag_halo
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

            if ni.info["dinfo"][i]["datatype"] == 0 # REAL4
                tmpbuf = Array{Float32}( undef, idef, jdef, kdef, rdef )
#                read!( fin, tmpbuf )
#		append!( vret, ntoh.( tmpbuf[:,:,kmin:kmax,rmin:rmax] ) )
            elseif ni.info["dinfo"][i]["datatype"] == 1 # REAL8
                tmpbuf = Array{Float64}( undef, idef, jdef, kdef, rdef )
#                read!( fin, tmpbuf )
#		append!( vret, ntoh.( tmpbuf[:,:,kmin:kmax,rmin:rmax] ) )
            else

	        return nothing
	    end
	    
            read!( fin, tmpbuf )
            append!( vret, ntoh.( tmpbuf[imin:imax,jmin:jmax,kmin:kmax,rmin:rmax] ) )
        end
    end

    return vret  # all the region data are included

#    return nothing
end




end
