
local Class = require(".Class")

--[[
	heap data structure
]]
---Availability: Client and Server
---@class objects.Heap: objects.Class
---@field package compare fun(a:any,b:any):boolean
local Heap = Class("objects:Heap")



local floor = math.floor

local function defaultCompare(a, b)
	return a > b
end

---@param heap objects.Heap
local function siftUp(heap, index)
	local parentIndex
	if index ~= 1 then
		parentIndex = floor(index/2)
		if heap.compare(heap[parentIndex], heap[index]) then
			heap[parentIndex], heap[index] = heap[index], heap[parentIndex]
			siftUp(heap, parentIndex)
		end
	end
end

---@param heap objects.Heap
local function siftDown(heap, index)
	local leftChildIndex, rightChildIndex, minIndex
	leftChildIndex = index * 2
	rightChildIndex = index * 2 + 1
	if rightChildIndex > #heap then
		if leftChildIndex > #heap then
			return
		else
			minIndex = leftChildIndex
		end
	else
		if not heap.compare(heap[leftChildIndex], heap[rightChildIndex]) then
			minIndex = leftChildIndex
		else
			minIndex = rightChildIndex
		end
	end

	if heap.compare(heap[index], heap[minIndex]) then
		heap[minIndex], heap[index] = heap[index], heap[minIndex]
		siftDown(heap, minIndex)
	end
end

function Heap:init(comparator)
	self.compare = comparator or defaultCompare
end

if false then
    ---Create a new heap.
    ---
    ---Availability: Client and Server
	---@param comparator? fun(a:any,b:any):boolean
	---@return objects.Heap
	function Heap(comparator) end ---@diagnostic disable-line: cast-local-type, missing-return
end

---@param newValue any
function Heap:insert(newValue)
	table.insert(self, newValue)

	if #self > 1 then
		siftUp(self, #self)
	end
end

---@return any?
function Heap:pop()
	if #self > 0 then
		local toReturn = self[1]
		self[1] = self[#self]
		table.remove(self, #self)
		if #self > 0 then
			siftDown(self, 1)
		end
		return toReturn
	else
		return nil
	end
end

---@return any?
function Heap:peek()
	if #self > 0 then
		return self[1]
	else
		return nil
	end
end

---@return any[]
function Heap:toTable()
	local newTable = { }
	for i = 1, #self do
		table.insert(newTable, self[i])
	end
	return newTable
end

function Heap:clear()
	for k in ipairs(self) do
		self[k] = nil
	end
end

---@return integer
function Heap:size()
	return #self
end

---@return objects.Heap
function Heap:clone()
	local newHeap = Heap(self.compare)
	for i = 1, #self do
		table.insert(newHeap, self[i])
	end
	return newHeap
end

---@param oldTable any[]
---@param comparator? fun(a:any,b:any):boolean
---@return objects.Heap
function Heap.heapify(oldTable, comparator)
	local newHeap = Heap(comparator)
	for i = #oldTable, 1, -1 do
		newHeap:insert(oldTable[i])
		table.remove(oldTable, i)
	end
	return newHeap
end

return Heap
