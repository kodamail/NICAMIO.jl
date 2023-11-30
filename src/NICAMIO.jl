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
export nio_hgrid_open
export nio_hgrid_open_all
export nio_hgrid_read
export nio_hgrid_read_all!
export nio_hgrid_set_vtkdata!
export nio_hgrid_set_latlon!

export xyz2latlon  # -> private




include( "NICAMIOvtk.jl" )
using .NICAMIOvtk
export NICAMIOvtkData



#function niopenLegacy( fname::String )
#end


end  # module


