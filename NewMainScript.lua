local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end

local delfile = delfile or function(file)
    pcall(function() writefile(file, '') end)
end

local function readFileSafe(file)
    local suc, res = pcall(readfile, file)
    if suc then return res end
    return nil
end

local function getCommitFromFile()
    if isfile('newvape/profiles/commit.txt') then
        local commit = readFileSafe('newvape/profiles/commit.txt')
        if commit and commit ~= '' then
            return commit
        end
    end
    return nil
end

local function downloadFile(path, func)
    if not isfile(path) then
        local commit = getCommitFromFile()
        if not commit then
            error("No commit hash found")
        end
        
        local relativePath = path:gsub('newvape/', '')
        local url = 'https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/' .. commit .. '/' .. relativePath
        
        local suc, res = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if not suc or res == '404: Not Found' then
            error(tostring(res))
        end
        
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end
        
        pcall(function() writefile(path, res) end)
    end
    return (func or readfile)(path)
end

local function wipeFolder(path)
    if not isfolder(path) then return end
    
    local files = listfiles(path)
    if not files then return end
    
    for _, file in ipairs(files) do
        if file:find('loader') then
            goto continue
        end
        
        if isfile(file) then
            local content = readFileSafe(file)
            if content and content:find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.') then
                pcall(function() delfile(file) end)
            end
        end
        
        ::continue::
    end
end

local function createFolders()
    local folders = {
        'newvape',
        'newvape/games', 
        'newvape/profiles',
        'newvape/assets',
        'newvape/libraries',
        'newvape/guis'
    }
    
    for _, folder in ipairs(folders) do
        if not isfolder(folder) then
            pcall(function() makefolder(folder) end)
        end
    end
end

local function getLatestCommit()
    local suc, subbed = pcall(function()
        return game:HttpGet('https://api.github.com/repos/imcomingforyou6959-gif/RPL/commits/main', true)
    end)
    
    if not suc or not subbed then
        return 'main'
    end
    
    local success, data = pcall(function()
        return game:GetService('HttpService'):JSONDecode(subbed)
    end)
    
    if success and data and data.sha then
        return data.sha
    end
    
    local commit = subbed:match('"sha":"(%w+)"')
    if commit and #commit == 40 then
        return commit
    end
    
    return 'main'
end

createFolders()

if not shared.VapeDeveloper then
    local currentCommit = getCommitFromFile()
    local latestCommit = getLatestCommit()
    
    if latestCommit and currentCommit ~= latestCommit then
        wipeFolder('newvape')
        wipeFolder('newvape/games')
        wipeFolder('newvape/guis')
        wipeFolder('newvape/libraries')
        pcall(function() writefile('newvape/profiles/commit.txt', latestCommit) end)
    elseif not currentCommit then
        pcall(function() writefile('newvape/profiles/commit.txt', latestCommit or 'main') end)
    end
end

local mainCode = downloadFile('newvape/main.lua', nil)
if not mainCode then
    error("Failed to load main.lua")
end

local success, result = pcall(loadstring, mainCode, 'main')
if not success then
    error("Failed to load main.lua: " .. tostring(result))
end

return result()
