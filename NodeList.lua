local class = require "com.class"

---@class NodeList
---@overload fun(nodeOrNodes):NodeList
local NodeList = class:derive("NodeList")

-- Place your imports here

---Constructs a new Node List.
---Node Lists represent zero, one or more Nodes and group them together so that they can be all edited at once.
---With bulk getters and setters, they also provide a standardized way of storing states of multiple Nodes at once for use with Commands.
---@param nodeOrNodes table|Node? A Node or a list of Nodes with which the Node List will be constructed.
function NodeList:new(nodeOrNodes)
    ---@type [Node]
    self.nodes = {}
    if nodeOrNodes then
        if #nodeOrNodes == 0 then
            -- A single node.
            self.nodes = {nodeOrNodes}
        else
            -- A list of nodes.
            self.nodes = _Utils.copyTable(nodeOrNodes)
        end
    end
end

---Returns a copy of this Node List.
---@return NodeList
function NodeList:copy()
    if #self.nodes == 0 then
        return NodeList()
    end
    return NodeList(self.nodes)
end

--############################################################################--
---------------- D I R E C T   L I S T   M A N I P U L A T I O N ---------------
--############################################################################--

---Adds a Node to the Node List. If that Node is already on the list, it will not be added the second time.
---@param node Node The node to be added.
function NodeList:addNode(node)
    if not _Utils.isValueInTable(self.nodes, node) then
        table.insert(self.nodes, node)
    end
end

---Removes a Node from the Node List, if it is in there.
---@param node Node The node to be removed.
function NodeList:removeNode(node)
    _Utils.removeValueFromTable(self.nodes, node)
end

---Removes these nodes from the Node List, for which the provided function `fn(node)` returns `true`.
---@param fn function The function.
function NodeList:removeNodesFunction(fn)
    for i = #self.nodes, 1, -1 do
        if fn(self.nodes[i]) then
            table.remove(self.nodes, i)
        end
    end
end

---Adds a Node to the Node List, if it is not in there, and removes it if it is there.
---@param node Node The node to be added or removed.
function NodeList:toggleNode(node)
    if _Utils.isValueInTable(self.nodes, node) then
        self:removeNode(node)
    else
        self:addNode(node)
    end
end

---Removes all nodes from the Node List.
function NodeList:clear()
    self.nodes = {}
end

---Returns whether the given Node is in this Node List.
---@param node Node The node to be checked.
function NodeList:hasNode(node)
    return _Utils.isValueInTable(self.nodes, node)
end

---Returns the n-th Node from this Node List, starting from 1.
---@param n integer The index of the node to be returned.
---@return Node?
function NodeList:getNode(n)
    return self.nodes[n]
end

---Returns the list of nodes which exist in this Node List.
---You should do this only when you want to iterate over the Node List's elements.
---@return [Node]
function NodeList:getNodes()
    return self.nodes
end

---Returns the current size of this Node List.
---@return integer
function NodeList:getSize()
    return #self.nodes
end

---Sorts the contained nodes by the order they appear in the UI tree.
function NodeList:sortByTreeOrder()
    local result = {}
    -- TODO: At some point, sort this independently of the UI tree module.
    local info = _EDITOR.uiTree:getUITreeInfo(_PROJECT:getCurrentLayout(), nil, nil, true)
    for i, entry in ipairs(info) do
        if _Utils.isValueInTable(self.nodes, entry.node) then
            table.insert(result, entry.node)
        end
    end
    self.nodes = result
end

--############################################################################--
---------------- N O D E / W I D G E T   M A N I P U L A T I O N ---------------
--############################################################################--

---Returns a list of property values for each contained node, for the given property key.
---@param key string The property key.
---@return [any?]
function NodeList:bulkGetPropBase(key)
    local result = {}
    for i, node in ipairs(self.nodes) do
        table.insert(result, node:getPropBase(key))
    end
    return result
end

---Sets each contained node's value for the given property key, in the order of the indices.
---Returns `true` if *at least one* Node's property has been actually changed.
---@param key string The property key.
---@param values [any?] A list of values. N-th node in this list will get the n-th value. Empty values will be substituted with `nil`.
---@return boolean
function NodeList:bulkSetPropBase(key, values)
    local success = false
    for i, node in ipairs(self.nodes) do
        local oldValue = node:getPropBase(key)
        node:setPropBase(key, values[i])
        if oldValue ~= values[i] then
            success = true
        end
    end
    return success
end

---Sets each contained node's value for the given property key.
---Returns `true` if *at least one* Node's property has been actually changed.
---@param key string The property key.
---@param value any? The value. All nodes will have this value assigned.
---@return boolean
function NodeList:bulkSetPropBaseSingle(key, value)
    local success = false
    for i, node in ipairs(self.nodes) do
        local oldValue = node:getPropBase(key)
        node:setPropBase(key, value)
        if oldValue ~= value then
            success = true
        end
    end
    return success
end

---Returns a list of property values for each contained node's widget, for the given property key.
---If any node does not have a widget, `nil` will be prepended instead.
---@param key string The property key.
---@return [any?]
function NodeList:bulkGetWidgetPropBase(key)
    local result = {}
    for i, node in ipairs(self.nodes) do
        table.insert(result, node.widget and node.widget:getPropBase(key) or nil)
    end
    return result
end

---Sets each contained node widget's value for the given property key, in the order of the indices.
---Returns `true` if *at least one* Widget's property has been actually changed.
---@param key string The property key.
---@param values [any?] A list of values. N-th node in this list will get the n-th value. Empty values will be substituted with `nil`.
---@return boolean
function NodeList:bulkSetWidgetPropBase(key, values)
    local success = false
    for i, node in ipairs(self.nodes) do
        if node.widget then
            local oldValue = node.widget:getPropBase(key)
            node.widget:setPropBase(key, values[i])
            if oldValue ~= values[i] then
                success = true
            end
        end
    end
    return success
end

---Sets each contained node widget's value for the given property key.
---Returns `true` if *at least one* Widget's property has been actually changed.
---@param key string The property key.
---@param value any? The value. All nodes will have this value assigned.
---@return boolean
function NodeList:bulkSetWidgetPropBaseSingle(key, value)
    local success = false
    for i, node in ipairs(self.nodes) do
        if node.widget then
            local oldValue = node.widget:getPropBase(key)
            node.widget:setPropBase(key, value)
            if oldValue ~= value then
                success = true
            end
        end
    end
    return success
end

---Sets a name for all contained Nodes.
---All of them get the exact same name. There is no duplicate resolution.
---Returns `true` if *at least one* Node's name has been changed.
---@param name string The name to be given to all contained Nodes.
function NodeList:bulkSetName(name)
    local success = false
    for i, node in ipairs(self.nodes) do
        local result = node:setName(name)
        success = success or result
    end
    return success
end

---Ensures a unique name for all contained Nodes.
function NodeList:bulkEnsureUniqueName()
    for i, node in ipairs(self.nodes) do
        node:ensureUniqueName()
    end
end

--##################################################################################--
---------------- N O D E   H I E R A R C H Y   M A N I P U L A T I O N ---------------
--##################################################################################--

---Adds all Nodes in this list to a given UI tree (as the given node's parent).
---Returns `true` if *at least one* Node has been successfully added.
---
---This function works **ONLY** if the node list has been sorted using `:sortByTreeOrder()`. And it still sometimes doesn't work. See the TODO in `:bulkMoveToIndex()`.
---@param parent Node The parent Node the nodes in this list will be added to.
---@param indexes [integer]? The indexes each of the Nodes will occupy. Note that the final result may differ as new nodes will shift the previous nodes' indexes.
---@return boolean
function NodeList:bulkAdd(parent, indexes)
    local success = false
    for i, node in ipairs(self.nodes) do
        local result = parent:addChild(node, indexes and indexes[i])
        success = success or result
    end
    return success
end

---Adds all Nodes in this list as the given UI nodes' children.
---Returns `true` if *at least one* Node has been successfully added.
---
---This function works **ONLY** if the node list has been sorted using `:sortByTreeOrder()`. And it still sometimes doesn't work. See the TODO in `:bulkMoveToIndex()`.
---@param parents [Node] The parent Nodes the nodes in this list will be added to.
---@param indexes [integer]? The indexes each of the Nodes will occupy. Note that the final result may differ as new nodes will shift the previous nodes' indexes.
function NodeList:bulkAddSpread(parents, indexes)
    local success = false
    for i, node in ipairs(self.nodes) do
        local result = parents[i]:addChild(node, indexes and indexes[i])
        success = success or result
    end
    return success
end

---Removes all Nodes in this list from their UI trees.
---Returns `true` if *at least one* Node has been successfully deleted.
---@return boolean
function NodeList:bulkRemove()
    local success = false
    for i, node in ipairs(self.nodes) do
        local result = node:removeSelf()
        success = success or result
    end
    return success
end

---Restores all Nodes in this list to their respective places they had prior to their deletion.
function NodeList:bulkRestore()
    ---The restore is done in reverse order.
    for i = #self.nodes, 1, -1 do
        self.nodes[i]:restoreSelf()
    end
end

---Returns a list of parents for each contained node.
---@return [Node]
function NodeList:bulkGetParents()
    local result = {}
    for i, node in ipairs(self.nodes) do
        table.insert(result, node.parent)
    end
    return result
end

---Sets each contained node's parent to the corresponding item from the provided list of parents.
---Make sure the length of this list is the same as the size of this list.
---@param parents [Node] The list of parents to be assigned to the contained nodes.
function NodeList:bulkSetParents(parents)
    for i, node in ipairs(self.nodes) do
        node.parent = parents[i]
    end
end

---Returns a list of indexes (n-th item in the node's parent) for each contained node.
---@return [integer]
function NodeList:bulkGetSelfIndexes()
    local result = {}
    for i, node in ipairs(self.nodes) do
        table.insert(result, node:getSelfIndex())
    end
    return result
end

---Moves all contained nodes to the specified index, with subsequent nodes in this list occupying the spaces directly below.
---Returns `true` if any of the nodes' positions has changed.
---
---This function works **ONLY** if the node list has been sorted using `:sortByTreeOrder()`. And it still sometimes doesn't work. See the TODO in this function.
---@return boolean
function NodeList:bulkMoveToIndex(index)
    -- TODO: (not applying only to this one):
    -- Detect when we've moved a Node that's *above*.
    -- In that case, all subsequent moves MUST be decremented.
    -- Zoinks: this list can have nodes from all around the tree, inside, outside, whatever! so this decrement needs to be stored per parent lol
    local result = false
    for i, node in ipairs(self.nodes) do
        local success = node:moveSelfToPosition(index + i - 1)
        result = result or success
    end
    return result
end

---Moves all contained nodes to the provided index, with each subsequent node below.
---Returns `true` if any of the nodes' positions has changed.
---
---This function works **ONLY** if the node list has been sorted using `:sortByTreeOrder()`. And it still sometimes doesn't work. See the TODO in `:bulkMoveToIndex()`.
---@return boolean
function NodeList:bulkMoveToIndexes(indexes)
    local result = false
    for i = #self.nodes, 1, -1 do
        local success = self.nodes[i]:moveSelfToPosition(indexes[i])
        result = result or success
    end
    return result
end

---Moves all contained nodes up by one position.
---Returns `true` if any of the nodes' positions has changed.
---@return boolean
function NodeList:bulkMoveUp()
    local result = false
    for i, node in ipairs(self.nodes) do
        local success = node:moveSelfUp()
        result = result or success
    end
    return result
end

---Moves all contained nodes down by one position.
---Returns `true` if any of the nodes' positions has changed.
---@return boolean
function NodeList:bulkMoveDown()
    local result = false
    for i = #self.nodes, 1, -1 do
        local success = self.nodes[i]:moveSelfDown()
        result = result or success
    end
    return result
end

---Moves all contained nodes to the top, in the order they are contained in this node list.
---Returns `true` if any of the nodes' positions has changed.
---@return boolean
function NodeList:bulkMoveToTop()
    local result = false
    for i = #self.nodes, 1, -1 do
        local success = self.nodes[i]:moveSelfToTop()
        result = result or success
    end
    return result
end

---Moves all contained nodes to the bottom, in the order they are contained in this node list.
---Returns `true` if any of the nodes' positions has changed.
---@return boolean
function NodeList:bulkMoveToBottom()
    local result = false
    for i, node in ipairs(self.nodes) do
        local success = node:moveSelfToBottom()
        result = result or success
    end
    return result
end

--##############################################################################--
---------------- O T H E R   B U L K   N O D E   F U N C T I O N S ---------------
--##############################################################################--

---Finishes the dragging process for all contained Nodes.
---Returns `true` if *at least one* Node has been actually dragged somewhere in result of the drag.
---@return boolean
function NodeList:bulkFinishDrag()
    local success = false
    for i, node in ipairs(self.nodes) do
        local startPos = node:getProp("pos")
        local finishPos = node:getPos()
        node:finishDrag()
        if startPos ~= finishPos then
            success = true
        end
    end
    return success
end

---Cancels the dragging process for all contained Nodes.
function NodeList:bulkCancelDrag()
    for i, node in ipairs(self.nodes) do
        node:cancelDrag()
    end
end

---Finishes the resize process for all contained Nodes.
---Returns `true` if *at least one* Node has been actually resized somewhere in result of the process.
---@return boolean
function NodeList:bulkFinishResize()
    local success = false
    for i, node in ipairs(self.nodes) do
        if node.widget and node:isResizable() then
            local startPos = node:getProp("pos")
            local startSize = node.widget:getProp("size")
            local finishPos = node:getPos()
            local finishSize = node:getSize()
            node:finishResize()
            if startPos ~= finishPos or startSize ~= finishSize then
                success = true
            end
        end
    end
    return success
end

---Cancels the resize process for all contained Nodes.
function NodeList:bulkCancelResize()
    for i, node in ipairs(self.nodes) do
        node:cancelResize()
    end
end

---Returns a list of serialized Nodes' data.
---@return [string]
function NodeList:bulkSerialize()
    local data = {}
    for i, node in ipairs(self.nodes) do
        table.insert(data, node:serialize())
    end
    return data
end

return NodeList