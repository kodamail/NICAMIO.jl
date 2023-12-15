module NioType

export NioFile

mutable struct NioFile
    fname::String
    ftype::String
#    data_pos::UInt64
    info::Dict{String,Any}

    function NioFile( fname )
        self = new()
	self.fname    = fname
#	self.ftype    = "PANDA"
#	self.data_pos = 0
	self.info     = Dict()
	return self
    end
end  # NioFile

end
