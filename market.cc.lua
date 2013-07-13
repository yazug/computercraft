--Market by: TurtleScripts.com
--This is a modified version of the PasteBin script to work directly with TurtleScript project files.
local tArgs = { ... }

local function printUsage()
  term.clear()
  term.setCursorPos(1,1)
    print( "TurtleMarket v1.0 BETA [#gjdgyl]" )
	print( "-------------------------------------------------" )
	print( "by: TurtleScripts.com (update file_key: #gjdgz7)" )
	print( " " )
	print( "Usages:" )
	print( " ==UPLOAD==" )
	print( "  market put (file_key) (filename) (write_pin)" )
	print( "  [pin req'd]" )
	print( " ==DOWNLOAD==" )
	print( "  market get (file_key) (filename) (read_pin) [y]" )
	print( "  [pin req'd for private/drafts]" )
	print( " " )
end

local function putFile(sCode, sFile, sPin, sOverride)
    local sPath = shell.resolve( sFile )
	if not fs.exists( sPath ) or fs.isDir( sPath ) then
            print( "No such file" )
            return
	end
	local sName = fs.getName( sPath )
	local file = fs.open( sPath, "r" )
	local sText = file.readAll()
	file.close()
	write( "Connecting to TurtleScripts.com... " )
	local response = http.post("http://api.turtlescripts.com/putFileRaw/"..textutils.urlEncode( sCode ),"pin="..sPin.."&".."data="..textutils.urlEncode(sText))
	if response then
		print( "Success." )
		local sResponse = response.readAll()
		response.close()
		print( " " )
		print( "Local: "..sFile )
		print( "Remote: #"..sCode )
		print( "[==========================================] 100%" )
		print(string.len(sText).." bytes")
		print( " " )
		print( "Upload Complete." )
	else
		print( "Failed." )
		print( " " )
		print( "ERROR: The file key is bad or project pin is wrong." )
	end
end
local function getFile(sCode, sFile, sPin, sOverride)
    local sPath = shell.resolve( sFile )
    if sCode == "" then
		print( "You must specify a File Key from TurtleScripts.com!" )
		return
	end
	if sFile == "" then
		print( "You must specify a Filename to write to!" )
		return
	end
	if fs.exists( sPath ) then
		print( "File already exists" )
        if sOverride == "" and (sPin ~= "y" or sOverride ~= "") then
		    return
        end
	end
	write( "Connecting to TurtleScripts.com... " )
	local response = http.post("http://api.turtlescripts.com/getFileRaw/"..textutils.urlEncode( sCode ),"pin="..sPin)
	if response then
		print( "Success." )
		local sResponse = response.readAll()
		response.close()
		local file = fs.open( sPath, "w" )
		file.write( sResponse )
		file.close()
		print( " " )
		print( "Remote: #"..sCode )
		print( "Local: "..sFile )
		print( "[==========================================] 100%" )
		print(string.len(sResponse).." bytes")
		print( " " )
		print( "Downloaded Complete." )
	else
		print( "Failed." )
		print( " " )
		print( "ERROR: The file key is bad or project is private (in which case, did you specify your project pin??)." )
	end
end

    local gui_mode = false
    if #tArgs < 3 then
		printUsage()
		return
	end
    local sCommand = tArgs[1]
    local sCode = tArgs[2] or ""
	local sFile = tArgs[3] or ""
    local sPin  = tArgs[4] or ""
    if sCommand == "put" then
    	putFile(sCode, sFile, sPin)
    elseif sCommand == "get" then
        local sOverride  = tArgs[5] or ""	
        getFile(sCode, sFile, sPin, sOverride)
    else
    	printUsage()
    	return
    end