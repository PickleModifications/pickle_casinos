Language = {}

function _L(name, ...)
    if name then 
        local str = Language[Config.Language][name]
        if str then 
            if (type(str) == "table") then
                return str[1]
            end
            return string.format(str, ...)
        else    
            return "ERR_TRANSLATE_"..(name).."_404"
        end
    else
        return "ERR_TRANSLATE_404"
    end
end

function toupper(str)
    return str:upper()
end