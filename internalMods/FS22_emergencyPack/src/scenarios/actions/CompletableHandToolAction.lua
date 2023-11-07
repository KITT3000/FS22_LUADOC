CompletableHandToolAction = {}
local CompletableHandToolAction_mt = Class(CompletableHandToolAction, ScenarioHandToolAction)

function CompletableHandToolAction.new(checkpoint, custom_mt)
	local self = CompletableHandToolAction:superClass().new(checkpoint, custom_mt or CompletableHandToolAction_mt)

	return self
end

function CompletableHandToolAction:canBeCompleted()
	return self.checkpoint.isActive
end
