--!nonstrict
-- SAE: diagnóstico de datos del cliente.
-- Todavía no es el radar ni el panel multicuenta.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
    warn("[SAE] Se necesita un contexto cliente con LocalPlayer.")
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[SAE] No se encontró PlayerGui.")
    return
end

local ROOT_NAMES = { "AreaEggSlotsClient", "AreaEggSlots" }
local MAX_VISITED = 450
local MAX_QUEUED = 800
local MAX_ATTRIBUTES = 12
local MAX_ATTRIBUTE_OBJECTS = 12
local MAX_TEXT_OBJECTS = 12
local MAX_STRUCTURE_OBJECTS = 12
local MAX_CHILDREN_PER_NODE = 100

local function clean(value, limit)
    local ok, result = pcall(tostring, value)
    if not ok then
        return "[no convertible a texto]"
    end

    result = result:gsub("[%c]", " ")
    limit = limit or 150

    local validUtf8, characterCount = pcall(utf8.len, result)
    if not validUtf8 or characterCount == nil then
        result = result:gsub("[^\32-\126]", "?")
        characterCount = #result
    end

    if characterCount > limit then
        local stop = utf8.offset(result, limit + 1)
        result = result:sub(1, stop - 1) .. "..."
    end

    return result
end

local function fullName(object)
    local ok, result = pcall(function()
        return object:GetFullName()
    end)
    return ok and clean(result, 220) or "[objeto no disponible]"
end

local function readAttributes(object)
    local ok, result = pcall(function()
        return object:GetAttributes()
    end)
    return ok and result or {}
end

local function childrenOf(object)
    local ok, result = pcall(function()
        return object:GetChildren()
    end)
    return ok and result or {}
end

local function protectedKey(key)
    local name = tostring(key):lower()
    return name:find("token", 1, true)
        or name:find("password", 1, true)
        or name:find("cookie", 1, true)
        or name:find("webhook", 1, true)
end

local function safeValue(value)
    if type(value) == "string" then
        local lower = value:lower()
        if lower:find("https://", 1, true)
            or lower:find("http://", 1, true) then
            return "[URL omitida]"
        end
    end
    return clean(value, 110)
end

local function readGameProperty(name)
    local ok, result = pcall(function()
        return game[name]
    end)
    if not ok or result == nil or result == "" then
        return "[no disponible]"
    end
    return clean(result, 100)
end

local oldGui = playerGui:FindFirstChild("SAE_DataDiagnostic_v01")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SAE_DataDiagnostic_v01"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(0.92, 0.78)
frame.BackgroundColor3 = Color3.fromRGB(22, 23, 33)
frame.BorderSizePixel = 0
frame.Parent = gui

local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(760, 640)
constraint.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -72, 0, 32)
title.BackgroundTransparency = 1
title.Text = "SAE | Diagnóstico de datos"
title.TextColor3 = Color3.fromRGB(241, 242, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -44, 0, 10)
close.Size = UDim2.fromOffset(30, 28)
close.BackgroundColor3 = Color3.fromRGB(63, 43, 57)
close.BorderSizePixel = 0
close.Text = "X"
close.TextSize = 16
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = frame

close.Activated:Connect(function()
    gui:Destroy()
end)

local scanButton = Instance.new("TextButton")
scanButton.Position = UDim2.fromOffset(16, 49)
scanButton.Size = UDim2.fromOffset(110, 34)
scanButton.BackgroundColor3 = Color3.fromRGB(121, 91, 220)
scanButton.BorderSizePixel = 0
scanButton.Text = "Escanear"
scanButton.TextColor3 = Color3.new(1, 1, 1)
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 14
scanButton.Parent = frame

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(136, 49)
status.Size = UDim2.new(1, -152, 0, 34)
status.BackgroundTransparency = 1
status.Text = "Preparando..."
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(186, 192, 208)
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(16, 96)
scroll.Size = UDim2.new(1, -32, 1, -112)
scroll.BackgroundColor3 = Color3.fromRGB(15, 17, 25)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.Parent = frame

local output = Instance.new("TextBox")
output.Position = UDim2.fromOffset(8, 8)
output.Size = UDim2.new(1, -22, 0, 32)
output.AutomaticSize = Enum.AutomaticSize.Y
output.BackgroundTransparency = 1
output.ClearTextOnFocus = false
output.MultiLine = true
output.TextEditable = false
output.RichText = false
output.TextWrapped = true
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 13
output.TextColor3 = Color3.fromRGB(213, 225, 231)
output.Text = "El informe aparecerá aquí."
output.Parent = scroll

local function inspectRoot(root, lines)
    local queue = { root }
    local head = 1
    local visited = 0
    local attributeObjects = 0
    local textObjects = 0
    local structureObjects = 0
    local omittedChildren = false

    table.insert(lines, "")
    table.insert(lines, "RUTA: " .. fullName(root))
    table.insert(lines, "Hijos directos: " .. #childrenOf(root))
    table.insert(lines, "Muestras de estructura y valores:")

    while head <= #queue and visited < MAX_VISITED do
        if not gui.Parent then
            return
        end

        local object = queue[head]
        head = head + 1
        visited = visited + 1

        local attributes = readAttributes(object)
        local keys = {}

        for key in pairs(attributes) do
            if not protectedKey(key) then
                table.insert(keys, key)
            end
        end
        table.sort(keys)

        local showStructure = structureObjects < MAX_STRUCTURE_OBJECTS
        local showAttributes = #keys > 0
            and attributeObjects < MAX_ATTRIBUTE_OBJECTS

        if showStructure or showAttributes then
            table.insert(
                lines,
                "- " .. fullName(object) .. " [" .. object.ClassName .. "]"
            )

            if showStructure then
                structureObjects = structureObjects + 1
            end

            if showAttributes then
                attributeObjects = attributeObjects + 1

                for i = 1, math.min(#keys, MAX_ATTRIBUTES) do
                    local key = keys[i]
                    table.insert(
                        lines,
                        "    " .. clean(key, 80)
                            .. " = " .. safeValue(attributes[key])
                    )
                end

                if #keys > MAX_ATTRIBUTES then
                    table.insert(lines, "    [más atributos omitidos]")
                end
            end
        end

        if textObjects < MAX_TEXT_OBJECTS
            and (object:IsA("TextLabel")
                or object:IsA("TextButton")
                or object:IsA("TextBox")) then
            local text = object.Text

            if text and text ~= "" then
                textObjects = textObjects + 1
                table.insert(
                    lines,
                    "  TEXTO " .. fullName(object) .. " = " .. safeValue(text)
                )
            end
        end

        local children = childrenOf(object)
        local availableSlots = math.max(0, MAX_QUEUED - #queue)
        local take = math.min(
            #children,
            MAX_CHILDREN_PER_NODE,
            availableSlots
        )

        if take < #children then
            omittedChildren = true
        end

        for i = 1, take do
            table.insert(queue, children[i])
        end

        if visited % 50 == 0 then
            task.wait()
        end
    end

    table.insert(lines, "Objetos examinados: " .. visited)
    table.insert(lines, "Objetos mostrados con atributos: " .. attributeObjects)
    table.insert(lines, "Textos mostrados: " .. textObjects)

    if head <= #queue or omittedChildren then
        table.insert(lines, "MUESTRA LIMITADA: hay objetos no examinados.")
    end
end

local function collectReport()
    local lines = {
        "SAE | Diagnóstico v0.1",
        "PlaceId: " .. readGameProperty("PlaceId"),
        "Instancia: " .. readGameProperty("JobId"),
        "Fecha UTC: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
        "",
        "Producción: NO VERIFICADA.",
        "Este informe muestra nombres, atributos y textos.",
        "La cobertura del cliente puede ser parcial por streaming.",
        "",
        "CARPETAS CANDIDATAS",
    }

    local found = 0

    for _, name in ipairs(ROOT_NAMES) do
        local root = Workspace:FindFirstChild(name)

        if root then
            found = found + 1
            inspectRoot(root, lines)
        else
            table.insert(lines, "- Workspace." .. name .. ": NO ENCONTRADA")
        end
    end

    table.insert(lines, "")
    table.insert(lines, "MÓDULOS CANDIDATOS (solo existencia; no se ejecutan)")

    local library = ReplicatedStorage:FindFirstChild("Library")
    local client = library and library:FindFirstChild("Client")

    for _, name in ipairs({ "EggCmds", "Network" }) do
        local object = client and client:FindFirstChild(name)

        table.insert(
            lines,
            "- Library.Client." .. name .. ": "
                .. (object and (object.ClassName .. " presente")
                    or "NO ENCONTRADO")
        )
    end

    table.insert(lines, "")

    if found == 0 then
        table.insert(lines, "No se localizaron las rutas candidatas.")
        table.insert(lines, "Las rutas pueden haber cambiado.")
    else
        table.insert(lines, "Comparte los nombres y valores observados.")
        table.insert(lines, "Price no equivale necesariamente a producción/s.")
    end

    table.insert(lines, "Todavía no hay filtro 1 B/s ni envío al panel.")

    return table.concat(lines, "\n")
end

local busy = false
local lastScan = -math.huge

local function runScan()
    if busy or not gui.Parent or os.clock() - lastScan < 1 then
        return
    end

    busy = true
    lastScan = os.clock()
    scanButton.Text = "Leyendo..."
    status.Text = "Consultando las rutas candidatas."

    local ok, report = pcall(collectReport)

    if gui.Parent then
        if ok then
            output.Text = report
            status.Text = "Listo. Selecciona el texto o envía capturas."
        else
            output.Text = "[SAE] Fallo de lectura: " .. clean(report, 500)
            status.Text = "Conserva el mensaje mostrado."
        end

        scroll.CanvasPosition = Vector2.new(0, 0)
        scanButton.Text = "Escanear"
    end

    busy = false
end

scanButton.Activated:Connect(function()
    task.spawn(runScan)
end)

task.defer(runScan)
