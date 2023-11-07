ClassExtension = {
	getClassObject = function (className)
		local parts = string.split(className, ".")
		local numParts = table.getn(parts)
		local currentTable = _G[parts[1]]

		if type(currentTable) ~= "table" then
			return nil
		end

		for i = 2, numParts do
			currentTable = currentTable[parts[i]]

			if type(currentTable) ~= "table" then
				return nil
			end
		end

		return currentTable
	end
}
