module NICAMIOvtk

using WriteVTK

export NICAMIOvtkData

mutable struct NICAMIOvtkData
#    fname::String
#    ftype::String
#    data_pos::UInt64
#    info::Dict{String,Any}
    glevel::Integer
    rlevel::Integer
    gmr::Integer

    function NICAMIOvtkData( glevel, rlevel )
        self = new()
#	self.fname = fname
#	self.ftype = "PANDA"
#	self.data_pos = 0
#	self.info = Dict()
        self.glevel = glevel
        self.rlevel = rlevel
	self.gmr = glevel - rlevel
	return self
    end
    
end


end
