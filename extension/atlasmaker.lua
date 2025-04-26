-- version history
--
-- 0.1 initial version
--
-- 0.2
-- Added option to choose between saving to PNG or BMP   
-- Removed the "Convert to Indexed" choice since it is a required action anyways.
--
--
--
--

local MaxRectsPacker = {}
MaxRectsPacker.__index = MaxRectsPacker

local function nextPowerOfTwo(x)
  local n = 1
  while n < x do n = n * 2 end
  return n
end

function MaxRectsPacker:new(width, height, margin)
  local obj = {
    width = width,
    height = height,
    margin = margin or 0,
    atlas = Image(width, height, ColorMode.RGB),
    freeRects = { { x = 0, y = 0, width = width, height = height } },
    rects = {},
  }
  setmetatable(obj, self)
  return obj
end

function MaxRectsPacker:findPosition(w, h)
  local bestNode = nil
  local bestShort = math.huge
  local bestLong = math.huge

  for _, r in ipairs(self.freeRects) do
    if r.width >= w and r.height >= h then
      local leftoverH = r.height - h
      local leftoverW = r.width - w
      local shortSide = math.min(leftoverH, leftoverW)
      local longSide = math.max(leftoverH, leftoverW)
      if shortSide < bestShort or (shortSide == bestShort and longSide < bestLong) then
        bestNode = { x = r.x, y = r.y }
        bestShort = shortSide
        bestLong = longSide
      end
    end
  end

  return bestNode
end

function MaxRectsPacker:addCel(cel)
	local img = cel.image
	local w = img.width + self.margin * 2
	local h = img.height + self.margin * 2
  
	local pos = self:findPosition(w, h)
	if not pos then
	  error("Image doesn't fit in atlas. (Consider increasing atlas size.)")
	end
  
	self.atlas:drawImage(img, pos.x + self.margin, pos.y + self.margin)
  
	local layerName = cel.layer.name
	local x, z = splitXY(layerName)
	local groupName = findGroupName(cel.layer)
  
	local rect = {
	  x = pos.x + self.margin,
	  y = pos.y + self.margin,
	  width = img.width,
	  height = img.height,
	  celX = cel.position.x,
	  celY = cel.position.y,
	  layer = layerName,
	  group = groupName,
	  frame = cel.frameNumber,
	  xCoord = x,
	  zCoord = z,
	  cel = cel,
	}
	table.insert(self.rects, rect)
  
	self:splitFreeRects(pos.x, pos.y, w, h)
	self:pruneFreeRects()
  
	return rect
end
  
function MaxRectsPacker:addCels(cels)
  table.sort(cels, function(a, b)
    return (a.image.width * a.image.height) > (b.image.width * b.image.height)
  end)

  for _, cel in ipairs(cels) do
    self:addCel(cel)
  end
end

function MaxRectsPacker:splitFreeRects(x, y, w, h)
  local newRects = {}
  for _, r in ipairs(self.freeRects) do
    if not (x >= r.x + r.width or x + w <= r.x or y >= r.y + r.height or y + h <= r.y) then
      if x > r.x then
        table.insert(newRects, { x = r.x, y = r.y, width = x - r.x, height = r.height })
      end
      if x + w < r.x + r.width then
        table.insert(newRects, { x = x + w, y = r.y, width = (r.x + r.width) - (x + w), height = r.height })
      end
      if y > r.y then
        table.insert(newRects, { x = r.x, y = r.y, width = r.width, height = y - r.y })
      end
      if y + h < r.y + r.height then
        table.insert(newRects, { x = r.x, y = y + h, width = r.width, height = (r.y + r.height) - (y + h) })
      end
    else
      table.insert(newRects, r)
    end
  end
  self.freeRects = newRects
end

function MaxRectsPacker:pruneFreeRects()
  local pruned = {}
  for i, a in ipairs(self.freeRects) do
    local contained = false
    for j, b in ipairs(self.freeRects) do
      if i ~= j and a.x >= b.x and a.y >= b.y and
         a.x + a.width <= b.x + b.width and
         a.y + a.height <= b.y + b.height then
        contained = true
        break
      end
    end
    if not contained then
      table.insert(pruned, a)
    end
  end
  self.freeRects = pruned
end

function MaxRectsPacker:finalizeToPOT()
  local maxX, maxY = 0, 0
  for _, r in ipairs(self.rects) do
    local x = r.x + r.width + self.margin
    local y = r.y + r.height + self.margin
    if x > maxX then maxX = x end
    if y > maxY then maxY = y end
  end

  local newW = nextPowerOfTwo(maxX)
  local newH = nextPowerOfTwo(maxY)

  if newW ~= self.width or newH ~= self.height then
    local resized = Image(newW, newH, ColorMode.RGB)
    resized:drawImage(self.atlas, 0, 0)
    self.atlas = resized
    self.width = newW
    self.height = newH
  end
end

function MaxRectsPacker:getRects()
  return self.rects
end

function MaxRectsPacker:getAtlasImage()
  return self.atlas
end

function MaxRectsPacker:showAtlas()
  local spr = Sprite(self.width, self.height, ColorMode.RGB)
  spr.cels[1].image:drawImage(self.atlas)
  return spr
end

-- ==========================================================================================================

cels_for_packing = {}

-- ==========================================================================================================

local function save_json(filename, data)
	local jsonStr = json.encode(data)
	local file = io.open(filename, "w")
	file:write(jsonStr)
	file:close()
end

-- ==========================================================================================================

local function hideAllLayers(layers)
	for _, layer in ipairs(layers) do
		if layer.isGroup then
			hideAllLayers(layer.layers)
		else
			layer.isVisible = false
		end
	end
end

-- ==========================================================================================================

local function showAllLayers(layers)
	for _, layer in ipairs(layers) do
		layer.isVisible = true
		if layer.isGroup then
			showAllLayers(layer.layers)
		end
	end
end

-- ==========================================================================================================

local function export_layer(filePath, layer)

	local sprite = app.activeSprite

	hideAllLayers(sprite.layers)

	layer.isVisible = true

	app.command.ExportSpriteSheet {
		ui = false,
		askOverwrite=false,
		type = SpriteSheetType.HORIZONTAL,
		textureFilename = filePath,
		filenameFormat="{title}-{layer}.{extension}",
		trim = true,
		trimByGrid = false
	}

	showAllLayers(sprite.layers)

end

-- ==========================================================================================================

function splitXY(name)
	local x, z = name:match("([^,]+),([^,]+)")
	return tonumber(x), tonumber(z)
end

function findGroupName(layer)
	local parent = layer.parent
	if parent and parent.isGroup then
	  return parent.name
	end
	return nil
end
  
  
function split(str, delimiter)
	local result = {}
	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
	  table.insert(result, match)
	end
	return result
  end

-- ==========================================================================================================

local function process_layer(name, layer)

	local sprite = app.activeSprite
	local frame = app.activeFrame
	local cel = layer:cel(frame.frameNumber)

	if cel then
		table.insert(cels_for_packing, cel)
	end

end	

-- ==========================================================================================================

local function process_group(group)

    local sprite = app.activeSprite

	local spritePath = sprite.filename
	if spritePath == "" then
		print("Sprite must be saved first.")
		return
	end

	local spriteDir = app.fs.filePath(spritePath)

	app.transaction(function ()
		for i, layer in ipairs(group.layers) do
			process_layer(group.name, layer)
		end
	end)

end

-- ==========================================================================================================

local function process_groups(settings)

    local sprite = app.activeSprite

	local spritePath = sprite.filename
	if spritePath == "" then
			print("Sprite must be saved first.")
			return
	end

	local sprite = app.activeSprite
	local spritePath = app.fs.filePath(sprite.filename)
	local spriteName = app.fs.fileTitle(sprite.filename)
	
	local json_filename = spritePath .. "/" .. spriteName .. ".json"
	local atlas_filename = spritePath .. "/" .. spriteName .. "." .. settings.format

	app.transaction(function ()
		for i, layer in ipairs(sprite.layers) do
			if layer.isGroup then
				process_group(layer)
			end				
		end
	end)

	local packer = MaxRectsPacker:new(settings.width, settings.height, settings.margin)
	packer:addCels(cels_for_packing)
	packer:finalizeToPOT()
	
	local sprite = app.activeSprite
	local spritePath = app.fs.filePath(sprite.filename)
	local spriteName = app.fs.fileTitle(sprite.filename)
	
	local atlasData = {
	  layers = {},
	  settings = {}
	}
	
	for _, rect in ipairs(packer:getRects()) do
	  local group = rect.group or "ungrouped"
	
	  if not atlasData.layers[group] then
		atlasData.layers[group] = { tiles = {} }
	  end
	
	  table.insert(atlasData.layers[group].tiles, {
		atlas_coords = {
		  x = rect.x,
		  y = rect.y,
		  w = rect.width,
		  h = rect.height
		},
		screen_coords = {
		  x = rect.celX,
		  y = rect.celY,
		  w = rect.width,
		  h = rect.height
		},
		x = rect.xCoord,
		z = rect.zCoord
	  })
	end

	local atlasSprite = Sprite(packer.width, packer.height, ColorMode.RGB)
	atlasSprite.cels[1].image:drawImage(packer:getAtlasImage())
	
	local prevSprite = app.activeSprite
	app.activeSprite = atlasSprite

	if settings.indexed then
		app.command.ColorQuantization {
			ui = false,
			withAlpha = true,
			maxColors = 256,
			useRange = false,
			algorithm = 0
		}
		
		app.command.ChangePixelFormat{
		format="indexed",
		dithering="none"
		}
	end

	if settings.save then
		save_json(json_filename, atlasData)
		atlasSprite:saveAs(atlas_filename)
	end
	
	if not settings.show then
		atlasSprite:close()

		if prevSprite then
			app.activeSprite = prevSprite
		end
	end

end

-- ==========================================================================================================

local function mainWindow()

	local dlg = Dialog { title = "AtlasMaker 0.2" }

	local settings = {
	  width = 512,
	  height = 512,
	  margin = 0,
	  show = false,
	  indexed = true,
	  format = "png",
	  save = true,
	}

	dlg:label{
		label = "This tool packs visible layers into a texture atlas."
	  }
	  dlg:label{
		label = "Specify atlas size, margin, and options below."
	  }
	  
	  dlg:label{ text = "" }
		
	dlg:separator{
		id="separator_1",
		text=""
	}

	dlg:number {
	  id = "width",
	  label = "Atlas Width",
	  text = tostring(settings.width),
	  focus = true
	}
	
	dlg:number {
	  id = "height",
	  label = "Atlas Height",
	  text = tostring(settings.height)
	}
	
	dlg:number {
	  id = "margin",
	  label = "Margin",
	  text = tostring(settings.margin)
	}
	
	dlg:combobox{
		id = "format",
		label = "Save Format",
		options = { "png", "bmp" },
		option = settings.format
	}

	dlg:check {
	  id = "show",
	  label = "Show Atlas when done.",
	  selected = settings.show
	}
	
	dlg:check {
	  id = "save",
	  label = "Save Atlas + JSON",
	  selected = settings.save
	}
	
	dlg:button {
	  id = "ok",
	  text = "Run",
	  focus = true,
	  onclick = function()
		local data = dlg.data
		settings.width = tonumber(data.width)
		settings.height = tonumber(data.height)
		settings.margin = tonumber(data.margin)
		settings.show = data.show
		settings.format = data.format
		settings.save = data.save
		dlg:close()
		process_groups(settings)
	  end
	}
	
	dlg:button {
	  text = "Cancel",
	  onclick = function() dlg:close() end
	}
	
	return dlg

end

mainWindow():show{ wait=true }
