-- This file is a prototype for the UI Script system, and as such is not a class!
-- Many paradigms seen here will carry over to the new scripting system!

local f = {}
local ui = _EDITOR.TEXT_INPUT_UI

function f.startEditing()
    local editedNode = assert(_EDITOR.selectedNodes:getNode(1))
    local text = editedNode:getText()
    local formatted = editedNode:getTextFormatted()
    ui:getChild("editText"):setText(text)
    ui:getChild("previewText"):setText(text)
    ui:getChild("previewText"):setTextFormatted(formatted)
    ui:setVisible(true)
end

function f.onTextChanged()
    local text = ui:getChild("editText"):getText()
    ui:getChild("previewText"):setText(text)
end

function f.onConfirmClicked()
    local editedNode = assert(_EDITOR.selectedNodes:getNode(1))
    local text = ui:getChild("editText"):getText()
    editedNode:setWidgetPropBase("text", text)
    ui:setVisible(false)
end

function f.onCancelClicked()
    ui:setVisible(false)
end

return f