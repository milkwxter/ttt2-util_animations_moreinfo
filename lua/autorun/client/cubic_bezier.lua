--[[
 * https:--github.com/gre/bezier-easing
 * BezierEasing - use bezier curve for transition easing function
 * by Gaëtan Renaudeau 2014 - 2015 – MIT License
 *
 * modified to work in Lua by Alf21
]]--

-- These values are established by empiricism with tests (tradeoff: performance VS precision)
local NEWTON_ITERATIONS = 4
local NEWTON_MIN_SLOPE = 0.001
local SUBDIVISION_PRECISION = 0.0000001
local SUBDIVISION_MAX_ITERATIONS = 10

local kSplineTableSize = 11
local kSampleStepSize = 1.0 / (kSplineTableSize - 1.0)

local function A(aA1, aA2)
	return 1.0 - 3.0 * aA2 + 3.0 * aA1
end

local function B(aA1, aA2)
	return 3.0 * aA2 - 6.0 * aA1
end

local function C(aA1)
	return 3.0 * aA1
end

-- Returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
local function calcBezier(aT, aA1, aA2)
	return ((A(aA1, aA2) * aT + B(aA1, aA2)) * aT + C(aA1)) * aT
end

-- Returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
local function getSlope(aT, aA1, aA2)
	return 3.0 * A(aA1, aA2) * aT * aT + 2.0 * B(aA1, aA2) * aT + C(aA1)
end

local function binarySubdivide(aX, aA, aB, mX1, mX2)
	local currentX, currentT, i = 0, 0, 0

	currentT = aA + (aB - aA) * 0.5
	currentX = calcBezier(currentT, mX1, mX2) - aX

	if currentX > 0.0 then
		aB = currentT
	else
		aA = currentT
	end

	while math.abs(currentX) > SUBDIVISION_PRECISION and (i + 1) < SUBDIVISION_MAX_ITERATIONS do
		i = i + 1

		currentT = aA + (aB - aA) * 0.5
		currentX = calcBezier(currentT, mX1, mX2) - aX

		if currentX > 0.0 then
			aB = currentT
		else
			aA = currentT
		end
	end

	return currentT
end

local function newtonRaphsonIterate(aX, aGuessT, mX1, mX2)
	for i = 1, NEWTON_ITERATIONS do
		local currentSlope = getSlope(aGuessT, mX1, mX2)

		if currentSlope == 0.0 then
			return aGuessT
		end

		local currentX = calcBezier(aGuessT, mX1, mX2) - aX

		aGuessT = aGuessT - currentX / currentSlope
	end

	return aGuessT
end

local function getTForX(aX)
	local intervalStart = 0.0
	local currentSample = 1
	local lastSample = kSplineTableSize - 1

	while currentSample ~= lastSample and sampleValues[currentSample] <= aX do
		currentSample = currentSample + 1
		intervalStart = intervalStart + kSampleStepSize
	end
	--currentSample

	-- Interpolate to provide an initial guess for t
	local dist = (aX - sampleValues[currentSample]) / (sampleValues[currentSample + 1] - sampleValues[currentSample])
	local guessForT = intervalStart + dist * kSampleStepSize
	local initialSlope = getSlope(guessForT, mX1, mX2)

	if initialSlope >= NEWTON_MIN_SLOPE then
		return newtonRaphsonIterate(aX, guessForT, mX1, mX2)
	elseif initialSlope == 0.0 then
		return guessForT
	else
		return binarySubdivide(aX, intervalStart, intervalStart + kSampleStepSize, mX1, mX2)
	end
end

function CubicBezier(x1, y1, x2, y2, t)
	mX1 = x1
	mY1 = y1
	mX2 = x2
	mY2 = y2

	if not (0 <= mX1 and mX1 <= 1 and 0 <= mX2 and mX2 <= 1) then
		print("bezier x values must be in [0, 1] range")
	end

	-- Precompute samples table
	sampleValues = {}

	if mX1 ~= mY1 or mX2 ~= mY2 then
		for i = 1, kSplineTableSize do
			sampleValues[i] = calcBezier(i * kSampleStepSize, mX1, mX2)
		end
	end

	if mX1 == mY1 and mX2 == mY2 then
		return t -- linear
	end

	-- Because JavaScript number are imprecise, we should guarantee the extremes are right.
	if t == 0 then
		return 0
	end

	if t == 1 then
		return 1
	end

	return calcBezier(getTForX(t), mY1, mY2)
end
