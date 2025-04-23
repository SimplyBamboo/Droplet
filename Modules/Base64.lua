local Base64 = {}

local BaseTable = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Base64.Encode(Data)
    return ((Data:gsub('.', function(X) 
        local R, B = '', X:byte()
        for I = 8, 1, -1 do 
            R = R .. (B % 2^I - B % 2^(I-1) > 0 and '1' or '0') 
        end
        return R
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(X)
        if #X < 6 then return '' end
        local C = 0
        for I = 1, 6 do 
            C = C + (X:sub(I, I) == '1' and 2^(6-I) or 0) 
        end
        return BaseTable:sub(C+1, C+1)
    end) .. ({ '', '==', '=' })[#Data % 3 + 1])
end

function Base64.Decode(Data)
    Data = Data:gsub('[^'..BaseTable..'=]', '')
    return (Data:gsub('.', function(X)
        if X == '=' then return '' end
        local R, F = '', (BaseTable:find(X)-1)
        for I = 6, 1, -1 do 
            R = R .. (F % 2^I - F % 2^(I-1) > 0 and '1' or '0') 
        end
        return R
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(X)
        if #X ~= 8 then return '' end
        local C = 0
        for I = 1, 8 do 
            C = C + (X:sub(I, I) == '1' and 2^(8-I) or 0) 
        end
        return string.char(C)
    end))
end

