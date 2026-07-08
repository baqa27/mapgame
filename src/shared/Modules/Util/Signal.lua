-- ReplicatedStorage/Modules/Util/Signal.lua
-- Minimal pub-sub helper for internal Controller/Service state changes that don't need
-- to cross the client/server boundary (i.e. don't need a RemoteEvent). Not required by
-- the current Controllers, but available so future UI screens can drive state without
-- per-frame polling, per ROBLOX_UI_SKILL.md §5.

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	table.insert(handlers, fn)

	local connection = {}
	function connection.Disconnect()
		local index = table.find(handlers, fn)
		if index then
			table.remove(handlers, index)
		end
	end
	return connection
end

function Signal:Fire(...)
	for _, fn in ipairs(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
