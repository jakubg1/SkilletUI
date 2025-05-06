-- This file is a prototype for the UI Script system, and as such is not a class!
-- Many paradigms seen here will carry over to the new scripting system!

local f = {}
local ui = _EDITOR.TEXT_INPUT_UI

function f.startEditing()
    local editedNode = _EDITOR:getSingleSelectedNode()
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
    local editedNode = _EDITOR:getSingleSelectedNode()
    local text = ui:getChild("editText"):getText()
    _EDITOR:setNodeWidgetProperty(editedNode, "text", text)
    ui:setVisible(false)
end

function f.onCancelClicked()
    ui:setVisible(false)
end

return f