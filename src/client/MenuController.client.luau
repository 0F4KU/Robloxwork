--!strict
-- Opens and closes the main menu panel on the client.
local ScreenGui = script.Parent :: ScreenGui
local panel = ScreenGui:WaitForChild("Panel") :: Frame
local menuButton = ScreenGui:WaitForChild("MenuButton") :: TextButton
local playButton = panel:WaitForChild("PlayButton") :: TextButton
local closeButton = panel:WaitForChild("CloseButton") :: TextButton

local function setMenuOpen(isOpen: boolean)
	panel.Visible = isOpen
	menuButton.Visible = not isOpen
end

playButton.Activated:Connect(function()
	setMenuOpen(false)
end)
closeButton.Activated:Connect(function()
	setMenuOpen(false)
end)
menuButton.Activated:Connect(function()
	setMenuOpen(true)
end)

setMenuOpen(true)
