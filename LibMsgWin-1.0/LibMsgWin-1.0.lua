--- The major and minor version numbers of the library.
local MAJOR, MINOR = 'LibMsgWin-1.0', 11

if _G[MAJOR] ~= nil and (_G[MAJOR].version and _G[MAJOR].version >= MINOR) then
    return
end

local lib = {}
lib.name = MAJOR
lib.version = MINOR

-- Add global variable "LibMsgWin"
LibMsgWin = lib

--- Adjusts the slider based on the buffer state.
---@param self tlw The TLW (Top Level Window) object.
local function AdjustSlider(self)
    ---@type buffer
    local buffer = self:GetNamedChild('Buffer')
    ---@type slider
    local slider = self:GetNamedChild('Slider')
    local numHistoryLines = buffer:GetNumHistoryLines()
    local numVisHistoryLines = buffer:GetNumVisibleLines()
    local bufferScrollPos = buffer:GetScrollPosition()
    local sliderMin, sliderMax = slider:GetMinMax()
    local sliderValue = slider:GetValue()

    slider:SetMinMax(0, numHistoryLines)

    if sliderValue == sliderMax then
        slider:SetValue(numHistoryLines)
    elseif numHistoryLines == buffer:GetMaxHistoryLines() then
        slider:SetValue(sliderValue - 1)
    end

    slider:SetHidden(numHistoryLines <= numVisHistoryLines)
end

--- Creates a message window with the given parameters.
---@param _UniqueName string The unique name for the message window.
---@param _LabelText string The label text for the message window.
---@param _FadeDelay number The delay before the fade animation starts.
---@param _FadeTime number The duration of the fade animation.
---@return tlw TopLevelWindow The created message window.
function lib:CreateMsgWindow(_UniqueName, _LabelText, _FadeDelay, _FadeTime)
    -- Dimension Constraits
    local minWidth = 200
    local minHeight = 150
    ---@class  tlw : TopLevelWindow
    local tlw = WINDOW_MANAGER:CreateTopLevelWindow(_UniqueName)
    tlw:SetMouseEnabled(true)
    tlw:SetMovable(true)
    tlw:SetHidden(false)
    tlw:SetClampedToScreen(true)
    tlw:SetDimensions(350, 400)
    tlw:SetClampedToScreenInsets(-24)
    tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 50, 50)
    tlw:SetDimensionConstraints(minWidth, minHeight)
    tlw:SetResizeHandleSize(16)

    -- Set Fade Delay/Times
    tlw.fadeDelayWindow = _FadeDelay or 0
    tlw.fadeTimeWindow = _FadeTime or 0
    tlw.fadeDelayTextLines = tlw.fadeDelayWindow / 1000
    tlw.fadeTimeTextLines = tlw.fadeTimeWindow / 1000

    -- Create window fade timeline/animation
    tlw.timeline = ANIMATION_MANAGER:CreateTimeline()
    tlw.animation = tlw.timeline:InsertAnimation(ANIMATION_ALPHA, tlw, tlw.fadeDelayWindow)
    tlw.animation:SetAlphaValues(1, 0)
    tlw.animation:SetDuration(tlw.fadeTimeWindow)
    tlw.timeline:PlayFromStart()

    --- Adds text to the TLW (Top Level Window).
    ---@param _Message string The message to add.
    ---@param _Red? number (optional) The red color value (0-1).
    ---@param _Green? number (optional) The green color value (0-1).
    ---@param _Blue? number (optional) The blue color value (0-1).
    function tlw:AddText(_Message, _Red, _Green, _Blue)
        local Red = _Red or 1
        local Green = _Green or 1
        local Blue = _Blue or 1

        if not _Message then
            return
        end

        --- Adds the message to the buffer.
        self:GetNamedChild('Buffer'):AddMessage(_Message, Red, Green, Blue)

        --- Adjusts the slider value and checks visibility.
        AdjustSlider(self)

        --- Resets the fade timers.
        tlw:SetAlpha(1)
        tlw.timeline:PlayFromStart()
    end

    --- Changes the fade settings for the window.
    ---@param _FadeDelayWF number The delay before the fade animation starts.
    ---@param _FadeTimeWF number The duration of the fade animation.
    function tlw:ChangeWinFade(_FadeDelayWF, _FadeTimeWF)
        if not (type(_FadeDelayWF) == 'number' and type(_FadeTimeWF) == 'number') then
            return
        end

        --- The delay before the fade animation starts.
        tlw.fadeDelayWindow = _FadeDelayWF

        --- The duration of the fade animation.
        tlw.fadeTimeWindow = _FadeTimeWF

        --- Sets the animation offset for the timeline.
        tlw.timeline:SetAnimationOffset(tlw.animation, _FadeDelayWF)

        --- Sets the duration of the animation.
        tlw.animation:SetDuration(_FadeTimeWF)
    end

    --- Changes the fade settings for the text lines.
    ---@param _FadeDelayTF number The delay before the fade animation starts, in milliseconds.
    ---@param _FadeTimeTF number The duration of the fade animation, in milliseconds.
    function tlw:ChangeTextFade(_FadeDelayTF, _FadeTimeTF)
        if not (type(_FadeDelayTF) == 'number' and type(_FadeTimeTF) == 'number') then
            return
        end

        --- The delay before the fade animation starts, in seconds.
        tlw.fadeDelayTextLines = _FadeDelayTF / 1000

        --- The duration of the fade animation, in seconds.
        tlw.fadeTimeTextLines = _FadeTimeTF / 1000

        --- Sets the line fade settings for the buffer.
        self:GetNamedChild('Buffer'):SetLineFade(_FadeDelayTF / 1000, _FadeTimeTF / 1000)
    end

    --- Clears the text in the TLW (Top Level Window) buffer.
    function tlw:ClearText()
        --- Clears the text in the buffer.
        self:GetNamedChild('Buffer'):Clear()
    end

    --- Creates a backdrop control for the TLW (Top Level Window).
    ---@class  bg : BackdropControl
    local bg = WINDOW_MANAGER:CreateControl(_UniqueName .. 'Bg', tlw, CT_BACKDROP)

    --- Sets the anchor points for the backdrop control.
    bg:SetAnchor(TOPLEFT, tlw, TOPLEFT, -8, -6, ANCHOR_CONSTRAINS_XY)
    bg:SetAnchor(BOTTOMRIGHT, tlw, BOTTOMRIGHT, 4, 4, ANCHOR_CONSTRAINS_XY)

    --- Sets the edge texture for the backdrop control.
    bg:SetEdgeTexture('EsoUI/Art/ChatWindow/chat_BG_edge.dds', 256, 256, 32, 0)

    --- Sets the center texture for the backdrop control.
    bg:SetCenterTexture('EsoUI/Art/ChatWindow/chat_BG_center.dds', 0)

    --- Sets the insets for the backdrop control.
    bg:SetInsets(32, 32, -32, -32)

    --- Sets the dimension constraints for the backdrop control.
    bg:SetDimensionConstraints(minWidth, minHeight)
    ---@class divider : TextureControl
    local divider = WINDOW_MANAGER:CreateControl(_UniqueName .. 'Divider', tlw, CT_TEXTURE)
    divider:SetDimensions(4, 8)
    divider:SetAnchor(TOPLEFT, tlw, TOPLEFT, 20, 40, ANCHOR_CONSTRAINS_XY)
    divider:SetAnchor(TOPRIGHT, tlw, TOPRIGHT, -20, 40, ANCHOR_CONSTRAINS_XY)
    divider:SetTexture('EsoUI/Art/Miscellaneous/horizontalDivider.dds')
    divider:SetTextureCoords(0.181640625, 0.818359375, 0, 1)
    ---@class buffer : TextBufferControl
    local buffer = WINDOW_MANAGER:CreateControl(_UniqueName .. 'Buffer', tlw, CT_TEXTBUFFER)
    buffer:SetFont('ZoFontChat')
    buffer:SetMaxHistoryLines(200)
    buffer:SetMouseEnabled(true)
    buffer:SetLinkEnabled(true)
    buffer:SetAnchor(TOPLEFT, tlw, TOPLEFT, 20, 42, ANCHOR_CONSTRAINS_XY)
    buffer:SetAnchor(BOTTOMRIGHT, tlw, BOTTOMRIGHT, -35, -20, ANCHOR_CONSTRAINS_XY)
    buffer:SetLineFade(tlw.fadeDelayTextLines, tlw.fadeTimeTextLines)
    buffer:SetHandler('OnLinkMouseUp', function(self, linkText, link, button)
        --  ZO_PopupTooltip_SetLink(link)
        ZO_LinkHandler_OnLinkMouseUp(link, button, self)
    end)
    buffer:SetDimensionConstraints(minWidth - 55, minHeight - 62)
    buffer:SetHandler('OnMouseWheel', function(self, delta, ctrl, alt, shift)
        local offset = delta
        local slider = buffer:GetParent():GetNamedChild('Slider')
        if shift then
            offset = offset * buffer:GetNumVisibleLines()
        elseif ctrl then
            offset = offset * buffer:GetNumHistoryLines()
        end
        buffer:SetScrollPosition(buffer:GetScrollPosition() + offset)
        slider:SetValue(slider:GetValue() - offset)
    end)
    buffer:SetHandler('OnMouseEnter', function(...)
        tlw.timeline:Stop()
        buffer:SetLineFade(0, 0)
        buffer:ShowFadedLines()
        tlw:SetAlpha(1)
    end)
    buffer:SetHandler('OnMouseExit', function(...)
        buffer:SetLineFade(tlw.fadeDelayTextLines, tlw.fadeTimeTextLines)
        tlw.timeline:PlayFromStart()
    end)
    ---@class slider : SliderControl
    local slider = WINDOW_MANAGER:CreateControl(_UniqueName .. 'Slider', tlw, CT_SLIDER)
    slider:SetDimensions(15, 32)
    slider:SetAnchor(TOPRIGHT, tlw, TOPRIGHT, -25, 60, ANCHOR_CONSTRAINS_XY)
    slider:SetAnchor(BOTTOMRIGHT, tlw, BOTTOMRIGHT, -15, -80, ANCHOR_CONSTRAINS_XY)
    slider:SetMinMax(1, 1)
    slider:SetMouseEnabled(true)
    slider:SetValueStep(1)
    slider:SetValue(1)
    slider:SetHidden(true)
    slider:SetThumbTexture('EsoUI/Art/ChatWindow/chat_thumb.dds', 'EsoUI/Art/ChatWindow/chat_thumb_disabled.dds', nil, 8,
        22, nil, nil, 0.6875, nil)
    slider:SetBackgroundMiddleTexture('EsoUI/Art/ChatWindow/chat_scrollbar_track.dds')
    slider:SetHandler('OnValueChanged', function(self, value, eventReason)
        local numHistoryLines = self:GetParent():GetNamedChild('Buffer'):GetNumHistoryLines()
        local sliderValue = slider:GetValue()
        if eventReason == EVENT_REASON_HARDWARE then
            buffer:SetScrollPosition(numHistoryLines - sliderValue)
        end
    end)
    ---@class scrollUp : ButtonControl
    local scrollUp = WINDOW_MANAGER:CreateControlFromVirtual(_UniqueName .. 'SliderScrollUp', slider, 'ZO_ScrollUpButton')
    scrollUp:SetAnchor(BOTTOM, slider, TOP, -1, 0, ANCHOR_CONSTRAINS_XY)
    scrollUp:SetNormalTexture('EsoUI/Art/ChatWindow/chat_scrollbar_upArrow_up.dds')
    scrollUp:SetPressedTexture('EsoUI/Art/ChatWindow/chat_scrollbar_upArrow_down.dds')
    scrollUp:SetMouseOverTexture('EsoUI/Art/ChatWindow/chat_scrollbar_upArrow_over.dds')
    scrollUp:SetDisabledTexture('EsoUI/Art/ChatWindow/chat_scrollbar_upArrow_disabled.dds')
    scrollUp:SetHandler('OnMouseDown', function(...)
        buffer:SetScrollPosition(buffer:GetScrollPosition() + 1)
        slider:SetValue(slider:GetValue() - 1)
    end)
    ---@class scrollDown : ButtonControl
    local scrollDown = WINDOW_MANAGER:CreateControlFromVirtual(_UniqueName .. 'SliderScrollDown', slider,
        'ZO_ScrollDownButton')
    scrollDown:SetAnchor(TOP, slider, BOTTOM, -1, 0, ANCHOR_CONSTRAINS_XY)
    scrollDown:SetNormalTexture('EsoUI/Art/ChatWindow/chat_scrollbar_downArrow_up.dds')
    scrollDown:SetPressedTexture('EsoUI/Art/ChatWindow/chat_scrollbar_downArrow_down.dds')
    scrollDown:SetMouseOverTexture('EsoUI/Art/ChatWindow/chat_scrollbar_downArrow_over.dds')
    scrollDown:SetDisabledTexture('EsoUI/Art/ChatWindow/chat_scrollbar_downArrow_disabled.dds')
    scrollDown:SetHandler('OnMouseDown', function(...)
        buffer:SetScrollPosition(buffer:GetScrollPosition() - 1)
        slider:SetValue(slider:GetValue() + 1)
    end)

    ---@class scrollEnd : ButtonControl
    local scrollEnd = WINDOW_MANAGER:CreateControlFromVirtual(_UniqueName .. 'SliderScrollEnd', slider,
        'ZO_ScrollEndButton')
    scrollEnd:SetDimensions(16, 16)
    scrollEnd:SetAnchor(TOP, scrollDown, BOTTOM, 0, 0, ANCHOR_CONSTRAINS_XY)
    scrollEnd:SetHandler('OnMouseDown', function(...)
        buffer:SetScrollPosition(0)
        slider:SetValue(buffer:GetNumHistoryLines())
    end)

    if _LabelText and _LabelText ~= '' then
        ---@class label : LabelControl
        local label = WINDOW_MANAGER:CreateControl(_UniqueName .. 'Label', tlw, CT_LABEL)
        label:SetText(_LabelText)
        label:SetFont('$(ANTIQUE_FONT)|24')
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)

        ---@class textHeight : LabelControl
        local textHeight = label:GetTextHeight()

        --- Sets the dimension constraints for the label control.
        label:SetDimensionConstraints(minWidth - 60, textHeight, nil, textHeight)

        --- Clears the anchors for the label control.
        label:ClearAnchors()

        --- Sets the anchors for the label control.
        label:SetAnchor(TOPLEFT, tlw, TOPLEFT, 30, (40 - textHeight) / 2 + 5, ANCHOR_CONSTRAINS_XY)
        label:SetAnchor(TOPRIGHT, tlw, TOPRIGHT, -30, (40 - textHeight) / 2 + 5, ANCHOR_CONSTRAINS_XY)
    end

    return tlw
end

return lib
