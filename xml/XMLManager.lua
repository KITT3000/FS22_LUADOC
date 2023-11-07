XMLManager = {}
local XMLManager_mt = Class(XMLManager)

function XMLManager.new(customMt)
	local self = setmetatable({}, customMt or XMLManager_mt)
	self.schemas = {}
	self.files = {}
	self.createSchemaFunctions = {}
	self.initSchemaFunctions = {}

	return self
end

function XMLManager:unloadMapData()
	self.schemas = {}
end

function XMLManager:addSchema(schema)
	table.insert(self.schemas, schema)
end

function XMLManager:addFile(file)
	self.files[file.handle] = file
end

function XMLManager:removeFile(file)
	self.files[file.handle] = nil
end

function XMLManager:getFileByHandle(handle)
	return self.files[handle]
end

function XMLManager:addCreateSchemaFunction(func)
	table.insert(self.createSchemaFunctions, func)
end

function XMLManager:createSchemas()
	for _, func in ipairs(self.createSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function ()
			func()
		end)
	end
end

function XMLManager:addInitSchemaFunction(func)
	table.insert(self.initSchemaFunctions, func)
end

function XMLManager:initSchemas()
	for _, func in ipairs(self.initSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function ()
			func()
		end)
	end
end

function XMLManager.consoleCommandGenerateSchemas()
	if g_xmlManager ~= nil then
		local schemasSorted = {}

		for i = 1, #g_xmlManager.schemas do
			local schema = g_xmlManager.schemas[i]

			schema:generateSchema()
			schema:generateHTML()
			table.insert(schemasSorted, schema)
		end

		table.sort(schemasSorted, function (a, b)
			return a.name < b.name
		end)

		local htmlPath = string.format("shared/xml/documentation/overview.html")
		local file = io.open(htmlPath, "w")

		file:write("<!DOCTYPE html>\n")
		file:write("<html>\n")
		file:write("  <head>\n")
		file:write("    <title>XML Documentation (v" .. g_gameVersionDisplay .. ")</title>\n")
		file:write("  </head>\n")
		file:write("  <style>\n")
		file:write("    li {\n")
		file:write("      margin: 5px;\n")
		file:write("    }\n")
		file:write("    a {\n")
		file:write("      text-decoration:none;\n")
		file:write("      font-size: 15pt;\n")
		file:write("      color: #000000;\n")
		file:write("    }\n")
		file:write("  </style>\n")
		file:write("<body>\n")
		file:write("  <h1>Schema Overview</h1>\n")
		file:write("  <ul>\n")

		for _, schema in ipairs(schemasSorted) do
			file:write("   <li><a href=\"" .. schema.name .. ".html\">" .. schema.name .. "</a></li>\n")
		end

		file:write("  </ul>\n")
		file:write("</body>\n")
		file:write("</html>\n")
		file:close()
	end
end

addConsoleCommand("gsXMLGenerateSchemas", "Generates xml schemas", "XMLManager.consoleCommandGenerateSchemas", nil)

g_xmlManager = XMLManager.new()
