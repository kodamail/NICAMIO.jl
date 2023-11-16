module NioMisc

export uint2char

"""
    uint2char( ui )
Convert data from UInt to Char with null fulfilled if necessary.
"""
function uint2char( ui )
    if ui == 0
        return ""
    else
        return Char(ui)
    end
end

end
