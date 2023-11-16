module NICAMIO

include( "NioType.jl" )
using .NioType
export NioFile

include( "NioMisc.jl" )

include( "NioPanda.jl" )
using .NioPanda
export nio_open_panda
export nio_read_panda

include( "NioHgrid.jl" )
using .NioHgrid
export NioHgridInfo
export nio_hgrid_read
export xyz2latlon  # -> private




include( "NICAMIOvtk.jl" )
using .NICAMIOvtk
export NICAMIOvtkData



#function niopenLegacy( fname::String )
#end


end  # module


