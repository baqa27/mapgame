-- SecurityScan.lua
-- Scan semua script di dalam model/building Workspace untuk deteksi malware
-- BACA SAJA — tidak ada yang diubah/dihapus

local results = {}
local SUSPICIOUS_PATTERNS = {
    "loadstring",
    "HttpService",
    "GetAsync",
    "PostAsync",
    "require%(%d",          -- require(12345) pakai asset id angka
    "getfenv",
    "setfenv",
    "syn%.request",
    "http%.request",
    "Instance%.new.*Script",
    "game:GetService.*DataStore",
    "PromptProductPurchase",
    "PromptPurchase",
}

-- Folder yang BUKAN bagian dari game scripts kita
-- (ServerScriptService, StarterPlayer = legitimate, skip)
local SKIP_SERVICES = {
    "ServerScriptService",
    "StarterPlayer",
    "StarterGui",
    "StarterPack",
    "ReplicatedStorage",
    "ServerStorage",
    "SoundService",
    "Lighting",
    "Teams",
}

local function isLegitLocation(instance)
    local current = instance
    while current and current ~= game do
        for _, svc in ipairs(SKIP_SERVICES) do
            if current.Name == svc then return true end
        end
        current = current.Parent
    end
    return false
end

local function getPath(instance)
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

local function scanScript(script)
    if isLegitLocation(script) then return end

    local path = getPath(script)
    local src = ""
    local ok, err = pcall(function()
        src = script.Source
    end)
    if not ok then
        table.insert(results, {
            path = path,
            kind = script.ClassName,
            verdict = "UNREADABLE",
            reason = "Cannot read source: " .. tostring(err),
            preview = ""
        })
        return
    end

    local flags = {}
    for _, pat in ipairs(SUSPICIOUS_PATTERNS) do
        if src:find(pat) then
            table.insert(flags, pat)
        end
    end

    -- Cek obfuscation: string panjang aneh (>200 char tanpa spasi)
    if src:find("[A-Za-z0-9+/=]{200,}") then
        table.insert(flags, "LONG_ENCODED_STRING (possible obfuscation)")
    end

    local verdict = #flags > 0 and "⚠️ SUSPICIOUS" or "✅ CLEAN"
    if src:find("loadstring") and src:find("HttpService") then
        verdict = "🚨 LIKELY MALWARE"
    end

    table.insert(results, {
        path = path,
        kind = script.ClassName,
        verdict = verdict,
        flags = flags,
        preview = src:sub(1, 300):gsub("\n", " | ")
    })
end

-- Scan seluruh Workspace (termasuk Map.Buildings, Map.Props, dll)
local function scanAll(parent)
    for _, child in ipairs(parent:GetDescendants()) do
        if child:IsA("BaseScript") or child:IsA("ModuleScript") then
            scanScript(child)
        end
    end
end

scanAll(workspace)

-- Tampilkan hasil
local totalScripts = #results
local suspicious = 0

print("=== SECURITY SCAN REPORT ===")
print("Scripts ditemukan di luar folder game: " .. totalScripts)
print("")

for _, r in ipairs(results) do
    if r.verdict ~= "✅ CLEAN" then
        suspicious = suspicious + 1
        warn("PATH: " .. r.path)
        warn("TYPE: " .. r.kind)
        warn("VERDICT: " .. r.verdict)
        if r.flags and #r.flags > 0 then
            warn("FLAGS: " .. table.concat(r.flags, ", "))
        end
        warn("PREVIEW: " .. r.preview)
        print("---")
    else
        print("✅ CLEAN | " .. r.kind .. " | " .. r.path)
    end
end

print("")
print("=== SUMMARY ===")
print("Total script di model/building: " .. totalScripts)
print("Suspicious/Malware: " .. suspicious)
print("Clean: " .. (totalScripts - suspicious))

if totalScripts == 0 then
    print("Tidak ada script tersembunyi di model/building. Workspace bersih dari sisi script.")
end
