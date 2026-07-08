-- StarterPlayerScripts/GameClient/Controllers/CheckpointController.lua
-- Small auto-dismissing toast for checkpoint saves, forced returns (trust collapse /
-- time up), hint unlocks, and generic "locked interactable" notices. Never blocks input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local CheckpointController = {}
local player = Players.LocalPlayer

local RETURN_REASON_TEXT = {
	trust_collapsed = "Warga sudah tidak mempercayaimu -- kamu dikembalikan ke checkpoint terakhir.",
	time_up = "Waktu ronda habis -- kamu dikembalikan ke checkpoint terakhir.",
	unknown = "Kamu dikembalikan ke checkpoint terakhir.",
}

function CheckpointController.Start()
	local gui = UIKit.NewScreenGui("CheckpointGui")
	gui.Parent = player:WaitForChild("PlayerGui")

	local toast = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.92),
		Size = UDim2.fromScale(0.32, 0.06),
		Visible = false,
	})

	local label = UIKit.NewLabel({
		Name = "Label",
		Parent = toast,
		Text = "Progres disimpan",
	})

	local function showToast(text, duration)
		label.Text = text
		toast.BackgroundTransparency = 1
		UIKit.FadeIn(toast, 0.15, 0.25)
		task.delay(duration or 2.2, function()
			UIKit.FadeOutAndHide(toast, 0.3)
		end)
	end

	RemoteRegistry.Get("Checkpoint/Saved").OnClientEvent:Connect(function()
		showToast("Progres disimpan")
		UIKit.PlaySound(GameConfig.Audio.Kentongan, 0.5)
	end)

	RemoteRegistry.Get("Checkpoint/Returned").OnClientEvent:Connect(function(data)
		showToast(RETURN_REASON_TEXT[data.reason] or RETURN_REASON_TEXT.unknown, 3.5)
		UIKit.PlaySound(GameConfig.Audio.Kentongan, 0.6)
	end)

	RemoteRegistry.Get("Checkpoint/HintUnlocked").OnClientEvent:Connect(function()
		showToast("Petunjuk baru tersedia di jurnal")
	end)

	RemoteRegistry.Get("Interaction/Locked").OnClientEvent:Connect(function()
		showToast("Terkunci -- ada yang perlu ditemukan dulu.", 1.8)
	end)

	RemoteRegistry.Get("Night/TimeUp").OnClientEvent:Connect(function(data)
		if data.questCompleted then
			showToast("Tugas ronda malam ini selesai!", 2.5)
		end
		-- The "not completed" case is already covered by the Checkpoint/Returned toast
		-- that fires right after this (see NightTimerService).
	end)
end

return CheckpointController
