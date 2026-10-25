--!nonstrict
-- SAE DIAGNOSTICO v0.3 | BUILD 2026-10-25-A
-- Sustituye el contenido de SAE_DataDiagnostic_v01.lua en GitHub con este archivo.
-- Ventana naranja, paginacion, errores visibles y lectura por entrada.
-- Solo lectura local: sin remotos, require, red ni envio de datos.

local visibleOutput, visibleStatus
local function reportFailure(reason)
    local message = "SAE v0.3: " .. tostring(reason)
    warn(message)
    local shown = pcall(function()
        if not visibleOutput or not visibleOutput.Parent then error("Sin ventana") end
        visibleOutput.Text = message
        if visibleStatus then visibleStatus.Text = "ERROR: comparte el mensaje de abajo." end
    end)
    if not shown then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "SAE v0.3: error al iniciar",
                Text = message:sub(1, 240), Duration = 30
            })
        end)
    end
end

local function start()
    print("[SAE v0.3 BUILD 2026-10-25-A] Iniciando...")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
    error("No hay LocalPlayer. Ejecuta el archivo con el juego abierto.")
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    error("No se encontro PlayerGui tras esperar 10 segundos.")
end

local ROOT_NAMES = { "AreaEggSlotsClient", "AreaEggSlots" }
local MAX_ENTRIES = 80
local MAX_PER_ENTRY = 320
local MAX_QUEUE_PER_ENTRY = 640
local MAX_ATTRIBUTE_LINES = 16
local MAX_TEXT_LINES = 8
local MAX_VALUE_LINES = 8
local MAX_CHILDREN_PER_NODE = 160

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

for _, oldName in ipairs({"SAE_DataDiagnostic_v01", "SAE_DataDiagnostic_v02", "SAE_DataDiagnostic_v03"}) do
    local old = playerGui:FindFirstChild(oldName)
    if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SAE_DataDiagnostic_v03"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Enabled = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(0.92, 0.78)
frame.BackgroundColor3 = Color3.fromRGB(32, 26, 21)
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
title.Text = "SAE v0.3 | NUEVA VERSION"
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
scanButton.BackgroundColor3 = Color3.fromRGB(222, 119, 28)
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
status.Text = "v0.3 iniciada. Preparando lectura..."
visibleStatus = status
status.TextWrapped = true
status.TextColor3 = Color3.fromRGB(186, 192, 208)
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(16, 96)
scroll.Size = UDim2.new(1, -32, 1, -152)
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
output.Text = "SAE v0.3 se inicio correctamente. Esperando escaneo..."
visibleOutput = output
output.Parent = scroll

local pages, pageIndex = { "Esperando informe..." }, 1
local previous = Instance.new("TextButton")
previous.Position = UDim2.new(0, 16, 1, -44)
previous.Size = UDim2.fromOffset(110, 30)
previous.Text = "< Anterior"
previous.TextSize = 14
previous.BackgroundColor3 = Color3.fromRGB(222, 119, 28)
previous.TextColor3 = Color3.new(1, 1, 1)
previous.Parent = frame
local nextPage = Instance.new("TextButton")
nextPage.Position = UDim2.new(1, -126, 1, -44)
nextPage.Size = UDim2.fromOffset(110, 30)
nextPage.Text = "Siguiente >"
nextPage.TextSize = 14
nextPage.BackgroundColor3 = previous.BackgroundColor3
nextPage.TextColor3 = Color3.new(1, 1, 1)
nextPage.Parent = frame
local pageLabel = Instance.new("TextLabel")
pageLabel.Position = UDim2.new(0, 136, 1, -44)
pageLabel.Size = UDim2.new(1, -272, 0, 30)
pageLabel.BackgroundTransparency = 1
pageLabel.TextColor3 = Color3.new(1, 1, 1)
pageLabel.TextSize = 14
pageLabel.Text = "Pagina 1/1"
pageLabel.Parent = frame

local function renderPage()
    if not gui.Parent then return end
    output.Text = pages[pageIndex] or "Sin datos."
    pageLabel.Text = "Pagina " .. pageIndex .. "/" .. #pages
    scroll.CanvasPosition = Vector2.new(0, 0)
end
local function setReport(report)
    pages, pageIndex = {}, 1
    local buffer, size = {}, 0
    for line in (report .. "\n"):gmatch("(.-)\n") do
        if size + #line + 1 > 5500 and #buffer > 0 then
            table.insert(pages, table.concat(buffer, "\n"))
            buffer, size = {}, 0
        end
        table.insert(buffer, line)
        size = size + #line + 1
    end
    if #buffer > 0 then table.insert(pages, table.concat(buffer, "\n")) end
    if #pages == 0 then pages = { "Sin datos." } end
    renderPage()
end
previous.Activated:Connect(function()
    pageIndex = math.max(1, pageIndex - 1)
    renderPage()
end)
nextPage.Activated:Connect(function()
    pageIndex = math.min(#pages, pageIndex + 1)
    renderPage()
end)

local function ignoredAttribute(key)
    return protectedKey(key)
        or key == "RBX_ReimportId"
        or key == "OldId"
        or key == "DontModify"
end

local function inspectRoot(root, lines)
    local entries = childrenOf(root)
    local count = math.min(#entries, MAX_ENTRIES)
    table.insert(lines, "")
    table.insert(lines, "RUTA: " .. fullName(root))
    table.insert(lines, "Hijos directos: " .. #entries)
    table.insert(lines, "Cada entrada tiene su propio limite de lectura.")
    local totalVisited, totalTexts, totalValues = 0, 0, 0

    for index = 1, count do
        if not gui.Parent then return end
        local egg = entries[index]
        status.Text = "Revisando entrada " .. index .. "/" .. count
        local queue, head, visited = { egg }, 1, 0
        local shownAttrs, shownTexts, shownValues = 0, 0, 0
        local details, summary = {}, {}
        local limited, outputLimited = false, false
        local textSeen = {}
        local firstChildren = childrenOf(egg)
        for i = 1, math.min(#firstChildren, 10) do
            table.insert(summary, clean(firstChildren[i].Name, 55)
                .. " [" .. firstChildren[i].ClassName .. "]")
        end
        table.insert(lines, "")
        table.insert(lines, "ENTRADA " .. index .. ": " .. clean(egg.Name, 100)
            .. " [" .. egg.ClassName .. "]")
        table.insert(lines, "  Hijos: " .. (#summary > 0
            and table.concat(summary, ", ") or "(ninguno)"))

        while head <= #queue and visited < MAX_PER_ENTRY do
            if not gui.Parent then return end
            local object = queue[head]
            head, visited = head + 1, visited + 1
            local attributes = readAttributes(object)
            local keys = {}
            for key in pairs(attributes) do
                if not ignoredAttribute(key) then table.insert(keys, key) end
            end
            table.sort(keys)
            for _, key in ipairs(keys) do
                if shownAttrs < MAX_ATTRIBUTE_LINES then
                    shownAttrs = shownAttrs + 1
                    table.insert(details, "  ATRIBUTO " .. fullName(object)
                        .. " | " .. clean(key, 70) .. " = " .. safeValue(attributes[key]))
                else
                    outputLimited = true
                end
            end

            if object:IsA("TextLabel") or object:IsA("TextButton")
                or object:IsA("TextBox") then
                local ok, value = pcall(function() return object.Text end)
                if ok and value ~= "" then
                    local text = safeValue(value)
                    if not textSeen[text] then
                        textSeen[text] = true
                        totalTexts = totalTexts + 1
                        if shownTexts < MAX_TEXT_LINES then
                            shownTexts = shownTexts + 1
                            table.insert(details, "  TEXTO " .. fullName(object)
                                .. " = " .. text)
                        else
                            outputLimited = true
                        end
                    end
                end
            end

            if object:IsA("NumberValue") or object:IsA("IntValue")
                or object:IsA("StringValue") or object:IsA("BoolValue") then
                if not protectedKey(object.Name) then
                    local ok, value = pcall(function() return object.Value end)
                    if ok then
                        totalValues = totalValues + 1
                        if shownValues < MAX_VALUE_LINES then
                            shownValues = shownValues + 1
                            table.insert(details, "  VALOR " .. fullName(object)
                                .. " [" .. object.ClassName .. "] = " .. safeValue(value))
                        else
                            outputLimited = true
                        end
                    end
                end
            end

            local children = childrenOf(object)
            local take = math.min(#children, MAX_CHILDREN_PER_NODE,
                math.max(0, MAX_QUEUE_PER_ENTRY - #queue))
            if take < #children then limited = true end
            for i = 1, take do table.insert(queue, children[i]) end
            if visited % 80 == 0 then task.wait() end
        end
        totalVisited = totalVisited + visited
        for _, line in ipairs(details) do table.insert(lines, line) end
        if #details == 0 then
            table.insert(lines, "  Sin atributos utiles, textos ni valores en esta muestra.")
        end
        table.insert(lines, "  Examinados: " .. visited)
        if head <= #queue or limited then
            table.insert(lines, "  Lectura parcial de esta entrada.")
        end
        if outputLimited then
            table.insert(lines, "  Hay mas datos de esta entrada que no se muestran.")
        end
        task.wait()
    end
    table.insert(lines, "")
    table.insert(lines, "RESUMEN: entradas " .. count .. "/" .. #entries
        .. ", objetos " .. totalVisited .. ", textos " .. totalTexts
        .. ", valores " .. totalValues)
    if count < #entries then
        table.insert(lines, "Hay entradas sin examinar por el limite de seguridad.")
    end
end

local function listChildren(label, parent, lines)
    table.insert(lines, "")
    table.insert(lines, label .. " (solo nombres y clases):")
    if not parent then
        table.insert(lines, "  NO ENCONTRADO")
        return
    end
    local children = childrenOf(parent)
    for i = 1, math.min(#children, 60) do
        local child = children[i]
        table.insert(lines, "  " .. clean(child.Name, 90)
            .. " [" .. child.ClassName .. "]")
    end
    if #children > 60 then table.insert(lines, "  [lista parcial]") end
end

local function collectReport()
    local lines = {
        "SAE v0.3 | NUEVA VERSION",
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

    listChildren("Workspace", Workspace, lines)
    listChildren("ReplicatedStorage", ReplicatedStorage, lines)
    listChildren("ReplicatedStorage.Library", library, lines)
    listChildren("ReplicatedStorage.Library.Client", client, lines)
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

    local ok, report = xpcall(collectReport, function(e) return tostring(e) end)

    if gui.Parent then
        if ok then
            setReport(report)
            status.Text = "Listo. Usa Anterior / Siguiente y comparte el informe."
        else
            setReport("[SAE v0.3] Fallo de lectura: " .. clean(report, 1500))
            warn("[SAE v0.3] " .. tostring(report))
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

task.defer(function()
    task.wait()
    local success, failure = pcall(runScan)
    if not success then reportFailure(failure) end
end)

end

local started, failure = xpcall(start, function(e) return tostring(e) end)
if not started then reportFailure(failure) end
