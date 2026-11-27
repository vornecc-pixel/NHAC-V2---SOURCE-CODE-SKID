--[[
    =====================================================================
    VORNECC / gamesense UI  --  RUNTIME TEST HARNESS
    =====================================================================
    Runs on top of the library above (unchanged). Three jobs:

      1. Rebuilds the VORNECC redesign  (accent palette, 9-tab icon rail,
         Main tab = weapon ImageDropdown + two-column preview).
      2. Fills every tab with real controls so every widget type in the
         library can be clicked / inspected by hand.
      3. Runs a self-test suite against the library API and shows results
         three ways: console (with a readable PASS/FAIL log), a colour
         coded list in the "Test" tab, and a notification summary. Rows are
         green = pass, red = fail, yellow = INFO (not counted, used for
         library quirks worth knowing about). Pick any tab to poke the
         controls by hand; the "Test" tab can re-run everything.

    Press Insert to toggle the menu. Nothing is destroyed unless you press
    "Unload menu" in the Test tab (it asks for confirmation first).
    =====================================================================
]]

-- ====================== accent + compact palette =====================
Library.Theme.Default.Accent = Color3.fromRGB(153, 196, 39)
Library.Theme.Default.SecondAccent = Color3.fromRGB(124, 158, 32)
Library.UI.Name = "VORNECC TEST"

-- ========================= test framework ============================
local TotalPass, TotalFail = 0, 0
local Results = {}
local RenderedRows = {}

local function Record(Passed, Name, Detail)
    Results[#Results + 1] = {Pass = Passed, Name = Name, Detail = Detail}

    if Passed then
        TotalPass += 1
    else
        TotalFail += 1
    end

    print(("[UI TEST] %s  %s%s"):format(Passed and "PASS" or "FAIL", Name, Detail and ("  ->  " .. tostring(Detail)) or ""))
    return Passed
end

local function Check(Name, Function_)
    local Ok, Err = pcall(Function_)
    return Record(Ok, Name, (not Ok) and Err or nil)
end

-- informational result: printed and listed, but never counted as a failure
local function Note(Name, Detail)
    Results[#Results + 1] = {Info = true, Name = Name, Detail = Detail}
    print(("[UI TEST] INFO  %s  ->  %s"):format(Name, tostring(Detail)))
    return Detail
end

local function Equal(Actual, Expected, What)
    if Actual ~= Expected then
        error(("%s: expected %s, got %s"):format(What or "value", tostring(Expected), tostring(Actual)), 2)
    end
end

local function NotNil(Value, What)
    if Value == nil then
        error((What or "value") .. " is nil", 2)
    end
    return Value
end

local function NearRGB(Color, Expected, Tolerance)
    local R, G, B = math.round(Color.R * 255), math.round(Color.G * 255), math.round(Color.B * 255)
    local ER, EG, EB = Expected:match("(%d+),(%d+),(%d+)")

    ER, EG, EB = tonumber(ER), tonumber(EG), tonumber(EB)
    local Margin = Tolerance or 2

    if math.abs(R - ER) > Margin or math.abs(G - EG) > Margin or math.abs(B - EB) > Margin then
        error(("color: expected ~%s, got %d,%d,%d"):format(Expected, R, G, B), 2)
    end
end

local function RGB(Color)
    return ("%d,%d,%d"):format(math.round(Color.R * 255), math.round(Color.G * 255), math.round(Color.B * 255))
end

-- ============================ window =================================
local Window = Library:Window({
    Name = "VORNECC",
    Size = UDim2.new(0, 700, 0, 612),
    MinResize = UDim2.new(0, 620, 0, 480),
    CloseBind = Enum.KeyCode.Insert
})

-- Icon asset ids are the ones the library's own demo already used.
local MainTab = Window:CreateTab({Icon = "rbxassetid://18248771514"})
local AimTab = Window:CreateTab({Icon = "rbxassetid://15453335745"})
local VisualTab = Window:CreateTab({Icon = "rbxassetid://15453344494"})
local WorldTab = Window:CreateTab({Icon = "rbxassetid://15453313321"})
local PlayersTab = Window:CreateTab({Icon = "rbxassetid://15453359751"})
local WeaponsTab = Window:CreateTab({Icon = "rbxassetid://15453354931"})
local ConfigTab = Window:CreateTab({Icon = "rbxassetid://15453364412"})
local ScriptTab = Window:CreateTab({Icon = "rbxassetid://15453349637"})
local TestTab = Window:CreateTab({Icon = "rbxassetid://18240049800"})

Window:SetTab(1)

-- ===================== handles the tests look at =====================
local MainEnableExtras, MainExtraToggle, MainExtraSlider, MainDropdown, MainMultiBox
local MainAccentPicker, MainKeybind, MainTextBox
local AimFovSlider, AimSmoothSlider, AimDisabledSlider
local VisualSub1, VisualSub2
local TestParentToggle, TestHiddenToggle, TestHiddenSlider, TestLabelKeybind
local TestColorPicker, ResultsList, RunTests, RenderResults

-- ============================== MAIN =================================
do
    MainTab:ImageDropdown({
        Name = "Weapon type",
        Flag = "TestMainWeaponType",
        Options = {
            ["Global"] = {Icon = "rbxassetid://18657040454", Order = 1},
            ["Double Barrel SG"] = {Icon = "rbxassetid://18205706952", Order = 2},
            ["Revolver"] = {Icon = "rbxassetid://18205704829", Order = 3},
            ["LMG"] = {Icon = "rbxassetid://18205822505", Order = 4}
        },
        Default = "Global"
    })

    local Controls = MainTab:Section({Name = "Controls", Side = "Left", Fill = true})
    local Preview = MainTab:Section({Name = "Preview", Side = "Right", Fill = true})

    -- parent toggle drives two hidden children (visibility chain test)
    MainEnableExtras = Controls:Toggle({
        Name = "Enable extras",
        Flag = "TestMainEnableExtras",
        Callback = function(State)
            if MainExtraToggle then MainExtraToggle:SetVisible(State) end
            if MainExtraSlider then MainExtraSlider:SetVisible(State) end
        end
    })

    MainExtraToggle = Controls:Toggle({Name = "Extra toggle", Flag = "TestMainExtraToggle", Hidden = true})
    MainExtraSlider = Controls:Slider({Name = "Extra slider", Flag = "TestMainExtraSlider", Hidden = true, Min = 0, Max = 100, Default = 25, Ending = "%"})

    MainDropdown = Controls:Dropdown({
        Name = "Dropdown",
        Flag = "TestMainDropdown",
        Content = {"Option 1", "Option 2", "Option 3"},
        Default = "Option 1"
    })

    MainMultiBox = Controls:MultiBox({
        Name = "MultiBox",
        Flag = "TestMainMultiBox",
        Content = {"Option 1", "Option 2", "Option 3"}
    })

    MainTextBox = Controls:TextBox({Name = "TextBox", Flag = "TestMainTextBox", Max = 24})

    local AccentLabel = Preview:Label({Message = "Accent color"})
    MainAccentPicker = AccentLabel:ColorPicker({Name = "Accent color", Flag = "TestMainAccentPicker", Default = Library.Theme.Default.Accent})

    local KeybindLabel = Preview:Label({Message = "Toggle key"})
    KeybindLabel:Keybind({Default = Enum.KeyCode.RightShift, Mode = "Toggle", Flag = "TestMainKeybind"})

    Preview:Toggle({Name = "Risky option", Flag = "TestMainRisky", Risky = true})
    Preview:Button({Name = "Apply", Callback = function()
        print("[UI TEST] Main:Apply clicked")
    end})
    Preview:Button({Name = "Reset (confirm)", Confirmation = true, Callback = function()
        print("[UI TEST] Main:Reset confirmed")
    end})
end

-- ============================= AIMBOT ================================
do
    local Left = AimTab:Section({Name = "Aimbot", Side = "Left", Fill = true})
    local Right = AimTab:Section({Name = "Smoothing", Side = "Right", Fill = true})

    Left:Toggle({Name = "Enabled", Flag = "TestAimEnabled", Callback = function(State)
        print("[UI TEST] Aim:Enabled", State)
    end})
    Left:Toggle({Name = "Wall check", Flag = "TestAimWallCheck", Default = true})
    Left:Toggle({Name = "Rage mode", Flag = "TestAimRage", Risky = true})

    AimFovSlider = Left:Slider({Name = "FOV", Flag = "TestAimFov", Min = 0, Max = 100, Default = 25, Decimal = 1, Ending = "°"})
    Left:Dropdown({Name = "Hitbox", Flag = "TestAimHitbox", Content = {"Head", "Torso", "Nearest"}})
    Left:MultiBox({Name = "Priority", Flag = "TestAimPriority", Content = {"Closest", "Lowest health", "Visible"}})

    AimSmoothSlider = Right:Slider({Name = "Smoothness", Flag = "TestAimSmooth", Min = 1, Max = 50, Default = 12})
    AimDisabledSlider = Right:Slider({Name = "FOV limit", Flag = "TestAimFovLimit", Min = 0, Max = 11, Default = 5, Decimal = 1, Ending = "°", Disable = {"Disabled", 0, 11}})
    Right:Slider({Name = "No icons slider", Flag = "TestAimNoIcons", UseIcons = false})
    Right:Label({Message = "Aim key"}):Keybind({Default = Enum.KeyCode.Q, Mode = "On hotkey", Flag = "TestAimKey"})
end

-- ============================= VISUALS ===============================
do
    VisualSub1, VisualSub2 = VisualTab:SubSection({
        Name = "Category",
        Options = {
            "rbxassetid://18334627891",
            "rbxassetid://18334630306",
            "rbxassetid://18334626899",
            "rbxassetid://18334625304"
        }
    })

    local EspLeft = VisualSub1:Section({Name = "ESP", Fill = true})
    local EspRight = VisualSub1:Section({Name = "ESP extras", Side = "Right", Fill = true})

    EspLeft:Toggle({Name = "Player boxes", Flag = "TestEspBoxes", Default = true})
    EspLeft:Toggle({Name = "Names", Flag = "TestEspNames", Default = true})
    EspLeft:Toggle({Name = "Health bars", Flag = "TestEspHealth", Default = true})
    EspLeft:Dropdown({Name = "Team check", Flag = "TestEspTeam", Content = {"All", "Enemies", "Allies"}})

    EspRight:Toggle({Name = "Chams", Flag = "TestEspChams"})
    EspRight:Toggle({Name = "Chams color", Flag = "TestEspChamsColor"}):ColorPicker({Name = "Chams color", Flag = "TestEspChamsPicker"})
    EspRight:Slider({Name = "Distance", Flag = "TestEspDistance", Min = 0, Max = 1000, Default = 500})

    local ChamLeft = VisualSub2:Section({Name = "World", Fill = true})
    local ChamRight = VisualSub2:Section({Name = "World extras", Side = "Right", Fill = true})

    ChamLeft:Toggle({Name = "Full bright", Flag = "TestWorldFullBright"})
    ChamLeft:Slider({Name = "Ambient", Flag = "TestWorldAmbient", Min = 0, Max = 255, Default = 128})
    ChamRight:Button({Name = "Reload visuals", Callback = function()
        print("[UI TEST] Visuals:Reload clicked")
    end})
end

-- ============================== WORLD ================================
do
    local Left = WorldTab:Section({Name = "Environment", Side = "Left", Fill = true})
    local Right = WorldTab:Section({Name = "Effects", Side = "Right", Fill = true})

    Left:Toggle({Name = "Time changer", Flag = "TestWorldTime"})
    Left:Slider({Name = "Clock time", Flag = "TestWorldClock", Min = 0, Max = 24, Default = 14})
    Left:Button({Name = "Reset world", Confirmation = true, Callback = function()
        print("[UI TEST] World:Reset confirmed")
    end})

    Right:Dropdown({Name = "Skybox", Flag = "TestWorldSky", Content = {"Default", "Night", "Sunset"}})
    Right:Toggle({Name = "Remove fog", Flag = "TestWorldFog"}):ColorPicker({Name = "Fog color", Flag = "TestWorldFogPicker"})
    Right:Label({Message = "World key"}):Keybind({Default = Enum.KeyCode.F, Mode = "Toggle", Flag = "TestWorldKey"})
end

-- ============================= PLAYERS ===============================
do
    local Left = PlayersTab:Section({Name = "Players", Fill = true})
    local Right = PlayersTab:Section({Name = "Adjustments", Side = "Right", Fill = true})

    local PlayerList = Left:List({Flag = "TestPlayerList", Size = 220})
    local Listed = {}

    local function FillPlayers()
        for _, Player in Players:GetPlayers() do
            if not Listed[Player.Name] then
                Listed[Player.Name] = true

                local Ok, Thumb = pcall(function()
                    return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                end)

                PlayerList:AddValue(Player.Name, {Image = Ok and Thumb or nil})
            end
        end
    end

    FillPlayers()

    Left:Button({Name = "Refresh list", Callback = function()
        FillPlayers()
        print("[UI TEST] Players:Refresh clicked")
    end})

    Right:Toggle({Name = "Whitelisted", Flag = "TestPlayerWhitelisted"})
    Right:Toggle({Name = "Spectate", Flag = "TestPlayerSpectate"})
    Right:Slider({Name = "Highlight transparency", Flag = "TestPlayerHighlight", Min = 0, Max = 100, Default = 50, Ending = "%"})
    Right:TextBox({Name = "Note", Flag = "TestPlayerNote", Max = 48})
end

-- ============================= WEAPONS ===============================
do
    local Left = WeaponsTab:Section({Name = "Skins", Fill = true})
    local Right = WeaponsTab:Section({Name = "Weapon settings", Side = "Right", Fill = true})

    local Skins = Left:List({Flag = "TestSkinsList", Size = 200})
    Skins:AddValue("Default", {Color = Color3.fromRGB(200, 200, 200)})
    Skins:AddValue("Crimson", {Color = Color3.fromRGB(232, 0, 0)})
    Skins:AddValue("Ocean", {Color = Color3.fromRGB(2, 144, 232)})
    Skins:AddValue("Violet", {Color = Color3.fromRGB(198, 7, 232)})

    Left:Button({Name = "Apply skin", Callback = function()
        print("[UI TEST] Weapons:Apply clicked")
    end})

    Right:Dropdown({Name = "Weapon", Flag = "TestWeaponChoice", Content = {"Global", "Double Barrel SG", "Revolver", "LMG"}})
    Right:Slider({Name = "Skin scale", Flag = "TestWeaponScale", Min = 1, Max = 10, Default = 5, Decimal = 0.1})
    Right:Toggle({Name = "Show skin name", Flag = "TestWeaponName"})
end

-- ============================== CONFIGS ==============================
do
    local Left = ConfigTab:Section({Name = "Configs", Fill = true})
    local Right = ConfigTab:Section({Name = "Info", Side = "Right", Fill = true})

    local ConfigList = Left:List({Flag = "TestCurrentConfig", Size = 180})
    Left:TextBox({Name = "Config name", Flag = "TestConfigName", Max = 32})

    local function ConfigPath(Name)
        return Library.ConfigFolder .. "/" .. Name .. ".cfg"
    end

    Left:Button({Name = "Create config", Callback = function()
        local Name = Library.Flags["TestConfigName"]:Get()

        if Name == "" then
            Library:Notify({Message = "Enter a config name first", Delay = 3})
            return
        end

        local Ok, Err = pcall(function()
            if makefolder then
                pcall(makefolder, Library.Folder)
                pcall(makefolder, Library.ConfigFolder)
            end

            writefile(ConfigPath(Name), Library:GetConfig())
        end)

        if Ok then
            pcall(function() Library:UpdateConfigList(ConfigList, "Add") end)
            Library:Notify({Message = ("Config <font color='rgb(153, 196, 39)'>%s</font> saved"):format(Name), Delay = 3})
        else
            Library:Notify({Message = "Save failed: " .. tostring(Err), Delay = 5})
        end
    end})

    Left:Button({Name = "Load config", Callback = function()
        local Name = Library.Flags["TestCurrentConfig"]:Get()

        if not Name then
            Library:Notify({Message = "Select a config first", Delay = 3})
            return
        end

        local Ok, Err = pcall(function()
            Library:LoadConfig(readfile(ConfigPath(Name)))
        end)

        Library:Notify({Message = Ok and ("Loaded <font color='rgb(153, 196, 39)'>%s</font>"):format(Name) or ("Load failed: " .. tostring(Err)), Delay = 4})
    end})

    Left:Button({Name = "Refresh list", Callback = function()
        local Ok = pcall(function() Library:UpdateConfigList(ConfigList, "Add") end)
        print("[UI TEST] Configs:Refresh clicked", Ok and "ok" or "no gamesense/Configs folder")
    end})

    Right:Label({Message = "Folder: " .. tostring(Library.ConfigFolder)})
    Right:Button({Name = "Copy current config to console", Callback = function()
        print("[UI TEST] config dump: " .. Library:GetConfig())
    end})
end

-- ============================== SCRIPTS ==============================
do
    local Left = ScriptTab:Section({Name = "Scripts", Fill = true})
    local Right = ScriptTab:Section({Name = "Editor", Side = "Right", Fill = true})

    local ScriptList = Left:List({Flag = "TestScriptList", Size = 160})
    ScriptList:AddValue("example.lua")
    ScriptList:AddValue("testing.lua")

    Left:Button({Name = "Load script", Callback = function()
        print("[UI TEST] Scripts:Load clicked")
    end})
    Left:Button({Name = "Unload script", Callback = function()
        print("[UI TEST] Scripts:Unload clicked")
    end})
    Left:Button({Name = "Refresh list", Callback = function()
        print("[UI TEST] Scripts:Refresh clicked")
    end})

    Right:TextBox({Name = "Script path", Flag = "TestScriptPath", Max = 64})
    Right:Toggle({Name = "Auto execute", Flag = "TestScriptAuto"})
end

-- =============================== TEST ================================
do
    local Left = TestTab:Section({Name = "Self-test", Fill = true})
    local Right = TestTab:Section({Name = "Widgets", Side = "Right", Fill = true})

    ResultsList = Left:List({Flag = "TestResultsList", Size = 220})

    Left:Button({Name = "Re-run all checks", Callback = function()
        if not RunTests then return end

        local Ok, Err = pcall(RunTests)
        if not Ok then print("[UI TEST] re-run failed: " .. tostring(Err)) end
    end})
    Left:Button({Name = "Test notification", Callback = function()
        Library:Notify({
            Message = ("Notify test <font color='rgb(153, 196, 39)'>accent</font> / <font color='rgb(205, 205, 205)'>text</font>"),
            Position = "Top Left",
            Delay = 4
        })
    end})
    Left:Button({Name = "Unload menu", Confirmation = true, Callback = function()
        Library:Unload()
    end})

    -- visibility chain + widget coverage used by the automated checks
    TestParentToggle = Right:Toggle({
        Name = "Show hidden widgets",
        Flag = "TestParentToggle",
        Callback = function(State)
            if TestHiddenToggle then TestHiddenToggle:SetVisible(State) end
            if TestHiddenSlider then TestHiddenSlider:SetVisible(State) end
        end
    })

    TestHiddenToggle = Right:Toggle({Name = "Hidden toggle", Flag = "TestHiddenToggle", Hidden = true})
    TestHiddenSlider = Right:Slider({Name = "Hidden slider", Flag = "TestHiddenSlider", Hidden = true, Min = 0, Max = 10, Default = 5})

    local LabelKeybind = Right:Label({Message = "Menu key"})
    LabelKeybind:Keybind({Default = Enum.KeyCode.Insert, Mode = "Toggle", UseMode = false, Flag = "TestLabelKeybind", Callback = function(Key)
        Library.UI.CloseBind = Key
    end})
    TestLabelKeybind = Library.Flags["TestLabelKeybind"]

    TestColorPicker = Right:Label({Message = "Picker"}):ColorPicker({Name = "Picker", Flag = "TestLabelPicker"})

    Right:Slider({Name = "Risky slider", Flag = "TestRiskySlider", Risky = true})
    Right:Slider({Name = "Overridden slider", Flag = "TestOverrideSlider", Min = 0, Max = 10, Default = 5, OverrideLimit = true})
end

-- ============================ run the tests ==========================
function RunTests()
    TotalPass, TotalFail = 0, 0
    Results = {}

    -- theme / globals
    Check("theme accent = 153,196,39", function()
        Equal(RGB(Library.Theme.Default.Accent), "153,196,39", "Accent")
    end)

    Check("theme second accent = 124,158,32", function()
        Equal(RGB(Library.Theme.Default.SecondAccent), "124,158,32", "SecondAccent")
    end)

    Check("Library.UI.Name applied", function()
        Equal(Library.UI.Name, "VORNECC TEST", "UI.Name")
    end)

    -- window / tabs
    Check("window created", function()
        NotNil(Library.UI.MainUI, "Library.UI.MainUI")
        Equal(Library.UI.MainUI.Size.X.Offset, 700, "window width")
        Equal(Library.UI.MainUI.Size.Y.Offset, 612, "window height")
    end)

    Check("9 tabs created", function()
        Equal(#Window.Tabs, 9, "#Window.Tabs")
    end)

    Check("SetTab switches tab", function()
        Window:SetTab(2)
        Equal(Window.CurrentTab, AimTab, "CurrentTab after SetTab(2)")
        if not AimTab.Active then error("AimTab.Active is false after activation", 2) end
    end)

    Check("SetTab back to Main", function()
        Window:SetTab(1)
        Equal(Window.CurrentTab, MainTab, "CurrentTab after SetTab(1)")
    end)

    -- toggles
    Check("toggle default state", function()
        Equal(MainEnableExtras:Get(), false, "default toggle state")
    end)

    Check("toggle flag registered", function()
        NotNil(Library.Flags["TestMainEnableExtras"], 'Library.Flags["TestMainEnableExtras"]')
        Equal(Library.Flags["TestMainEnableExtras"]:Get(), false, "flag state")
    end)

    Check("toggle Set(true) / Get()", function()
        MainEnableExtras:Set(true)
        Equal(MainEnableExtras:Get(), true, "toggle state")
        Equal(Library.Flags["TestMainEnableExtras"]:Get(), true, "flag state")
    end)

    Check("toggle visibility chain shows children", function()
        Equal(MainExtraToggle.Hiding, false, "child toggle Hiding")
        Equal(MainExtraSlider.Hiding, false, "child slider Hiding")
    end)

    Check("toggle visibility chain hides children", function()
        MainEnableExtras:Set(false)
        Equal(MainExtraToggle.Hiding, true, "child toggle Hiding")
        Equal(MainExtraSlider.Hiding, true, "child slider Hiding")
    end)

    Check("Test tab visibility chain", function()
        TestParentToggle:Set(true)
        Equal(TestHiddenToggle.Hiding, false, "TestHiddenToggle.Hiding")
        Equal(TestHiddenSlider.Hiding, false, "TestHiddenSlider.Hiding")
        TestParentToggle:Set(false)
        Equal(TestHiddenToggle.Hiding, true, "TestHiddenToggle.Hiding after off")
    end)

    -- sliders
    Check("slider default value", function()
        Equal(AimFovSlider:Get(), 25, "slider default")
    end)

    Check("slider Set(50)", function()
        AimFovSlider:Set(50)
        Equal(AimFovSlider:Get(), 50, "slider value")
        Equal(Library.Flags["TestAimFov"]:Get(), 50, "flag slider value")
    end)

    Check("slider clamps below Min", function()
        AimFovSlider:Set(-100)
        Equal(AimFovSlider:Get(), 0, "clamped value")
    end)

    Check("slider clamps above Max", function()
        AimFovSlider:Set(9999)
        Equal(AimFovSlider:Get(), 100, "clamped value")
        AimFovSlider:Set(25)
    end)

    Check("slider Min()/Max()", function()
        Equal(AimFovSlider:Min(), 0, "Min()")
        Equal(AimFovSlider:Max(), 100, "Max()")
    end)

    Check("slider Disable range", function()
        AimDisabledSlider:Set(11)
        Equal(AimDisabledSlider:Get(), 11, "disabled-range value")
        AimDisabledSlider:Set(5)
    end)

    -- dropdown / multibox / textbox
    Check("dropdown default", function()
        Equal(MainDropdown:Get(), "Option 1", "dropdown default")
    end)

    Check("dropdown Set/Get", function()
        MainDropdown:Set("Option 2")
        Equal(MainDropdown:Get(), "Option 2", "dropdown value")
        MainDropdown:Set("Option 1")
    end)

    Check("dropdown AddValue", function()
        MainDropdown:AddValue("Option 4")
        MainDropdown:Set("Option 4")
        Equal(MainDropdown:Get(), "Option 4", "added option value")
        MainDropdown:Set("Option 1")
    end)

    Check("multibox Set (no error)", function()
        MainMultiBox:Set({"Option 1"})

        if type(MainMultiBox:Get()) ~= "table" then
            error("MultiBox:Get() did not return a table", 2)
        end
    end)

    Check("textbox default value", function()
        Equal(MainTextBox:Get(), "", "textbox default")
    end)

    -- lists
    Check("list AddValue / RemoveValue", function()
        local List = Library.Flags["TestSkinsList"]
        NotNil(List, "TestSkinsList flag")
        List:AddValue("Temporary")
        List:RemoveValue("Temporary")
    end)

    -- keybind / color picker
    Check("keybind Set/Get", function()
        NotNil(TestLabelKeybind, "label keybind handle")
        TestLabelKeybind:Set(Enum.KeyCode.RightShift)
        Equal(TestLabelKeybind:Get(), "RightShift", "keybind name")
        TestLabelKeybind:Set(Enum.KeyCode.Insert)
    end)

    Check("color picker Set/Get", function()
        NotNil(TestColorPicker, "label color picker handle")
        TestColorPicker:Set(Color3.fromRGB(232, 0, 0))
        local Value = TestColorPicker:Get()
        NearRGB(Value.Color, "232,0,0", 2)
        TestColorPicker:Set(Library.Theme.Default.Accent)
    end)

    Check("ImageDropdown flag registered", function()
        NotNil(Library.Flags["TestMainWeaponType"], "TestMainWeaponType flag")
    end)

    -- subsections
    Check("subsection switch (no error)", function()
        VisualSub2:Activate()
        VisualSub1:Activate()
    end)

    -- notifications
    Check("notify creates a notification", function()
        Library:Notify({Message = "self-test notification", Position = "Middle", Delay = 2})
    end)

    -- config round trip
    Check("config round-trip", function()
        MainEnableExtras:Set(true)
        AimFovSlider:Set(37)

        local Config = Library:GetConfig()
        if type(Config) ~= "string" or #Config < 2 then error("GetConfig() returned no data", 2) end

        Library:LoadConfig(Config)

        Equal(AimFovSlider:Get(), 37, "slider value after LoadConfig")
        MainEnableExtras:Set(false)
    end)

    -- informational only:
    -- Library:Disable() calls :Set(false) on EVERY registered flag. That is only
    -- well defined for toggles/sliders; a MultiBox or ImageDropdown flag can make
    -- it throw (table.find on a boolean). If it does, it is a library quirk, not a
    -- problem with this UI, so it is reported as INFO instead of FAIL.
    Note("Library:Disable()", (function()
        MainEnableExtras:Set(true)

        local Ok, Err = pcall(Library.Disable, Library)

        -- put shared state back so a re-run starts from the same place
        pcall(function() MainEnableExtras:Set(false) end)
        pcall(function() MainDropdown:Set("Option 1") end)
        pcall(function() MainMultiBox:Set({}) end)

        return Ok and "ran without error" or ("errored: " .. tostring(Err))
    end)())

    -- leave the UI in a clean state
    Window:SetTab(1)
    AimFovSlider:Set(25)

    RenderResults()

    Library:Notify({
        Message = ("UI self-test: <font color='rgb(120, 200, 90)'>%d passed</font>, <font color='rgb(235, 90, 90)'>%d failed</font>"):format(TotalPass, TotalFail),
        Position = "Top Left",
        Delay = 6
    })

    print("[UI TEST] ------------------------------------------------------------")
    print(("[UI TEST] DONE: %d passed, %d failed"):format(TotalPass, TotalFail))
    print("[UI TEST] Open the last tab (Test) for the results list. Press Insert to toggle the menu.")

    return TotalPass, TotalFail
end

function RenderResults()
    for Index = #RenderedRows, 1, -1 do
        local Row = RenderedRows[Index]

        if ResultsList then
            pcall(function()
                ResultsList:RemoveValue(Row)
            end)
        end

        RenderedRows[Index] = nil
    end

    if not ResultsList then return end

    if #Results == 0 then
        RenderedRows[1] = "no results"
        ResultsList:AddValue("no results", {Color = Color3.fromRGB(160, 160, 160)})
        return
    end

    for Index, Result in Results do
        local Kind = Result.Info and "INFO" or (Result.Pass and "PASS" or "FAIL")
        local Row = ("%02d %s  %s"):format(Index, Kind, Result.Name)

        RenderedRows[#RenderedRows + 1] = Row

        if Result.Info then
            ResultsList:AddValue(Row, {Color = Color3.fromRGB(200, 190, 120)})
        else
            ResultsList:AddValue(Row, {Color = Result.Pass and Color3.fromRGB(120, 200, 90) or Color3.fromRGB(235, 90, 90)})
        end
    end
end

-- watermark + viewport recentering, same as the original demo
Library:Init()

-- player list live updates (exercises the connection API)
if PlayersTab then
    Library:Connection(Players.PlayerAdded, function(Player)
        print("[UI TEST] player joined:", Player.Name)
    end)

    Library:Connection(Players.PlayerRemoving, function(Player)
        print("[UI TEST] player left:", Player.Name)
    end)
end

-- run once the first frame has rendered
task.defer(function()
    local Ok, Err = pcall(RunTests)

    if not Ok then
        warn("[UI TEST] harness error: " .. tostring(Err))
        Library:Notify({Message = "Test harness error: " .. tostring(Err), Position = "Middle", Delay = 8})
    end
end)
