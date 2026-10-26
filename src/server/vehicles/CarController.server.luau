local RunService = game:GetService("RunService")

local car = script.Parent
local chassis = car.Chassis
local seat = car.DriverSeat

local MAX_SPEED = 60
local TURN_RATE = 2.2
local ACCEL_LERP = 0.15

RunService.Heartbeat:Connect(function()
	local velocity = chassis.AssemblyLinearVelocity
	local forward = chassis.CFrame.LookVector
	forward = Vector3.new(forward.X, 0, forward.Z).Unit

	local throttle = seat.Throttle
	local steer = seat.Steer

	local targetSpeed = throttle * MAX_SPEED
	local currentForward = Vector3.new(velocity.X, 0, velocity.Z):Dot(forward)
	local newForward = currentForward + (targetSpeed - currentForward) * ACCEL_LERP
	local lateral = Vector3.new(velocity.X, 0, velocity.Z) - forward * currentForward

	local horizontal = forward * newForward + lateral * (1 - ACCEL_LERP)
	chassis.AssemblyLinearVelocity = Vector3.new(horizontal.X, velocity.Y, horizontal.Z)

	local movingFactor = math.clamp(math.abs(newForward) / MAX_SPEED, 0, 1)
	local yaw = -steer * TURN_RATE * movingFactor * math.sign(newForward)
	chassis.AssemblyAngularVelocity = Vector3.new(0, yaw, 0)
end)
