
# run_scan.ps1 — Kirim execute_script ke Roblox Studio MCP via stdio
$scanLua = @'
local SP={"loadstring","HttpService","GetAsync","PostAsync","require%(%d","getfenv","setfenv","syn%.request","http%.request","Instance%.new.*Script","PromptProductPurchase","PromptPurchase","backdoor"}
local SKIP={"ServerScriptService","StarterPlayer","StarterGui","StarterPack","ReplicatedStorage","ServerStorage","SoundService","Lighting","Teams","Chat"}
local function isL(i) local c=i while c and c~=game do for _,s in ipairs(SKIP) do if c.Name==s then return true end end c=c.Parent end return false end
local function gP(i) local p={} local c=i while c and c~=game do table.insert(p,1,c.Name) c=c.Parent end return table.concat(p,".") end
local sus,tot=0,0
for _,s in ipairs(workspace:GetDescendants()) do
  if(s:IsA("BaseScript")or s:IsA("ModuleScript"))and not isL(s) then
    tot=tot+1
    local src="" pcall(function()src=s.Source end)
    local f={} for _,pat in ipairs(SP) do if src:find(pat) then table.insert(f,pat) end end
    if #f>0 then sus=sus+1 warn("SUSPICIOUS|"..gP(s).."|"..s.ClassName.."|"..table.concat(f,",").."|"..src:sub(1,300))
    else print("CLEAN|"..s.ClassName.."|"..gP(s)) end
  end
end
print("SCAN_DONE|total="..tot.."|suspicious="..sus)
'@

# Escape untuk JSON
$escaped = $scanLua -replace '\\', '\\\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`t", '\t'

$jsonReq = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"execute_script","arguments":{"script":"' + $escaped + '"}}}'

Write-Host "Sending to Roblox Studio MCP..."
Write-Host "Request length: $($jsonReq.Length) chars"

# Kirim via mcp.bat stdin/stdout
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c `"%LOCALAPPDATA%\Roblox\mcp.bat`""
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$proc.Start() | Out-Null

# Kirim JSON-RPC request
$proc.StandardInput.WriteLine($jsonReq)
$proc.StandardInput.Flush()
Start-Sleep -Milliseconds 500

# Baca response (timeout 15 detik)
$output = ""
$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline) {
    if ($proc.StandardOutput.Peek() -ge 0) {
        $line = $proc.StandardOutput.ReadLine()
        if ($line) {
            $output += $line + "`n"
            Write-Host "RAW: $line"
            # Kalau dapat response JSON, selesai
            if ($line -match '"result"' -or $line -match '"error"') { break }
        }
    }
    Start-Sleep -Milliseconds 100
}

$proc.Kill() 2>$null

Write-Host ""
Write-Host "=== RESPONSE ==="
Write-Host $output

# Parse dan tampilkan hasil bersih
if ($output -match '"content"') {
    $json = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($json.result.content) {
        Write-Host "=== SCAN RESULTS ==="
        $json.result.content | ForEach-Object { Write-Host $_.text }
    }
}
