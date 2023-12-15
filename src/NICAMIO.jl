module NICAMIO

include( "NioType.jl" )
using .NioType
export NioFile

include( "NioMisc.jl" )

include( "NioDirect.jl" )
using .NioDirect
export nio_open_direct
export nio_read_direct

include( "NioPanda.jl" )
using .NioPanda
export nio_open_panda
export nio_read_panda

include( "NioHgrid.jl" )
using .NioHgrid
export NioHgridFile
export NioHgridAllFiles
export nio_hgrid_open_panda
export nio_hgrid_open_panda_all
export nio_hgrid_open_sequential
export nio_hgrid_open_sequential_all
export nio_hgrid_read!
export nio_hgrid_read_all!
export nio_hgrid_set_vtkdata!

include( "NICAMIOvtk.jl" )
using .NICAMIOvtk
export NICAMIOvtkData

end  # module


