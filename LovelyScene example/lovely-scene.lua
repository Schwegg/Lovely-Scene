local LovelyScene = {
  keywords = {},
  -- -- --
  finishedParsing = false,
  -- -- --
  sceneDirectory = "scenes/", -- default directory
  currentFile = "",
  currentPath = "",
  -- -- --
  actorSearchFunc = function( name ) print("No search function for actor given! set at runtime!") end,
  -- -- --
  DEBUG = false, -- set to true if you're getting errors
}
-- -- --
local function typeFromString( str ) -- returns type of var within string
  if string.find( str, "table:" ) or string.find( str, "{" ) then
    return "table"
  elseif string.find( str, "function" ) then
    return "function"
  elseif str:lower() == "true" or str:lower() == "false" then
    return "boolean"
  elseif tonumber( str ) then
    return "number"
  elseif str == "nil" then
    return "nil"
  else
    return "string"
  end
end
-- -- --
local function stringToType( s ) -- returns variable in intended type from given string
  local t = typeFromString(s)
  if t == "table" then
    s = Tserial.unpack( s, true )
  elseif t == "number" then
    s = tonumber( s )
  elseif t == "boolean" then
    s = (s:lower() == "true")
  end
  return s
end
-- -- --
local function getfield(v,f) -- gets the field of f
  v = v or _G    -- start with the table of globals
  for w in string.gfind(f, "[%w_]+") do
    v = v[w]
  end
  return v
end
-- -- --


-- -- --
function LovelyScene.new()
  local s = setmetatable( LovelyScene, { __index = LovelyScene } )
  s:init()
  return s
end
-- -- --
function LovelyScene:setSceneDirectory( path ) self.sceneDirectory = path end
function LovelyScene:setActorSearchFunc( func ) self.actorSearchFunc = func end
function LovelyScene:newKeyword( keyword, func, breaksParse ) self.keywords[keyword] = {func,bparse=breaksParse} end
-- -- --
function LovelyScene:init()
  -- command:
  --    actor = (current actor, if any. otherwise nil)
  --    vars = words after command in order of what was inputted.
  --      (words between quotation marks are grouped together.)
  self:newKeyword( "goto", function( command ) self:loadScene(self.currentFile,command.vars[1]) end, true )
  self:newKeyword( "break", function( command ) end, true )
  self:newKeyword( "print", function ( command ) print( unpack(command.vars) ) end )
end
-- -- --



-- -- --
function LovelyScene:loadScene( file, sceneID )
  local path = self.sceneDirectory..file..".lscene"
  self.currentFile = file
  self.currentPath = path
  sceneID = sceneID or ""
  self.finishedParsing = false
  -- -- --
  if love.filesystem.getInfo( path,"file" ) then
    -- gets all scenes from file
    local scenes = self:parse( path )
    -- if scene exists, will 
    if scenes[sceneID] then
      -- parses through line by line
      local bparse = false
      for i,command in ipairs( scenes[sceneID] ) do
        local commandName = command.name
        local check = true
        if type( command.tf ) == "string" then _,check = pcall(load(command.tf)) end
        -- -- --
        if check then -- checks if statement whether true or false at time of execution
          for c,v in pairs( self.keywords ) do
            if commandName == c then
              if command.actor then
                command.actor = self.actorSearchFunc( command.actor )
                v[1]( command )
              else
                v[1]( command )
              end
              if v.bparse then bparse = true break end
            end
            if bparse then break end
          end
        end
      end
      self.finishedParsing = true
    else -- if given scene doesn't exist, throws error
      error( "scene \""..sceneID.."\" in \""..path.."\" doesn't exist!" )
    end
  end
end
-- -- --



-- -- --
function LovelyScene:parse( path )
  local file_lines = {}
  -- gets lines of file
  for lines in love.filesystem.lines( path ) do
    local indentation = 0
    for spaces in lines:gmatch( "(%s%s)" ) do indentation = indentation + 1 end
    table.insert( file_lines, {lines,indentation} )
  end
  -- -- --
  local scenes = {}
  local currentScene = ""
  local currentActor = {ID="",indent=0}
  local currentCheck = {checking=false,scene="",tf=false,indent=0}
  -- iterates through lines of file
  for _,v in ipairs(file_lines) do
    local indentation = v[2]
    local vars = self:breakDownLine( v[1] )
    --for i,v in ipairs( vars ) do print(v) end
    -- disables check if indentation < currentCheck.indent
    if (currentCheck.checking and currentCheck.indent >= indentation) or currentScene ~= currentCheck.scene then currentCheck.checking = false end
    -- removes actor if indentation < currentActor.indent
    if currentActor.ID ~= "" and currentActor.indent >= indentation then currentActor.ID = "" end
    -- -- --
    if #vars > 0 then
      local command = vars[1]
      -- -- --
      if command == "scene" then
        currentScene = vars[2]
        scenes[currentScene] = {}
        
      elseif command == "actor" then
        currentActor.ID = vars[2]
        currentActor.indent = indentation
        
      elseif command == "set" then
        local baseTabel = nil
        local v = nil
        local setTo = nil
        local condition = nil
        -- -- --
        if #vars == 4 or currentActor.ID == "" then -- set var = x
          v = vars[2]
          condition = vars[3]
          setTo = stringToType(vars[4])
        else -- set baseTable var = x
          baseTabel = self:actorSearchFunc(vars[2])
          v = vars[3]
          condition = vars[4]
          setTo = stringToType(vars[5])
        end
        local vars = {baseTabel,v,setTo}
        if currentActor.ID ~= "" and currentActor.indent < indentation then vars[1] = currentActor.ID end
        -- -- --
        local var = getfield( baseTabel, v )
        if condition == "=" then
          vars[3] = var
        elseif condition == "+=" then
          vars[3] = var+setTo
        elseif condition == "-=" then
          vars[3] = var-setTo
        elseif condition == "*=" then
          vars[3] = var*setTo
        elseif condition == "/=" then
          vars[3] = var/setTo
        elseif condition == "%=" then
          vars[3] = var%setTo
        end
        local tf = currentCheck.checking and currentCheck.tf or false
        table.insert( scenes[currentScene], { name="set",vars=vars,tf=tf } )
        
      elseif command == "if" then
        local v = nil
        local vcheck = nil
        local condition = nil
        -- -- --
        local f = "return"
        for i=1,#vars-1 do f = f.." "..vars[i+1] end
        currentCheck.tf = f
        currentCheck.checking = true
        currentCheck.indent = indentation
        currentCheck.scene = currentScene
        
      else
        local variables = {}
        variables.name = vars[1]
        variables.vars = {}
        variables.tf = currentCheck.checking and currentCheck.tf or false
        for i=2,#vars do table.insert( variables.vars,vars[i] ) end
        if currentActor.ID ~= "" and currentActor.indent < indentation then variables.actor = currentActor.ID end
        for i=1,#variables.vars do variables.vars[i] = stringToType(variables.vars[i]) end
        -- -- --
        table.insert( scenes[currentScene], variables )
      end
    end
  end
  return scenes
end
-- -- --
function LovelyScene:breakDownLine( line )
  local splitLine = {}
  line = line:gsub( "%s%s", "" ) -- removes tabs in front of line
  if line:find( "(%s*%-%-)" ) then line = line:sub( 0, line:find( "(%s*%-%-)" )-1 ) end -- removes comments
  -- splits line by alphanumeric/word/etc.
  for var in line:gmatch( "([%d%w%p%c\"().]+)" ) do
    table.insert( splitLine, var )
  end
  -- -- -- local function to get number of quotation marks in string
  local function getQuotationCount( str )
    local count = 0
    for c in str:gmatch( "\"" ) do count = count + 1 end
    return count
  end
  -- -- -- iterates over lines one more time to merge any quotation marked lines
  local finalSplitLine = {}
  local skip = 0 -- used to skip iterations
  for i,v in ipairs(splitLine) do -- groups quotation marks together
    local quotationCount = getQuotationCount( v )
    -- -- --
    if skip > 0 then
      skip = skip - 1
    elseif quotationCount == 1 then
      for o,b in ipairs( splitLine ) do if o > i then
        v = v.." "..b
        skip = skip + 1
        if getQuotationCount(b) == 1 then
          v = v:gsub( "\"", "" )
          table.insert( finalSplitLine, v )
          break
        end
      end end
    else
      v = v:gsub( "\"", "" )
      table.insert( finalSplitLine, v )
    end
  end
  return finalSplitLine
end
-- -- --
return LovelyScene.new()







