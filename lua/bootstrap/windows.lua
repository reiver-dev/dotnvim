local function find_exec(locations)
    for _, loc in ipairs(locations) do
        if vim.fn.executable(loc) == 1 then
            return loc
        end
    end
end

local vswhere_path

local function vswhere_exe()
    if not vswhere_path then
        vswhere_path = find_exec {
            "vswhere",
            vim.env["ProgramFiles(x86)"] .. "\\Microsoft Visual Studio\\Installer\\vswhere.exe"
        }
        if not vswhere_path then
            error("vswhere executable not found")
        end
    end
    return vswhere_path
end


local function vswhere()
    local cmd = {vswhere_exe(), "-format", "json", "-products", "*"}
    local data = vim.fn.system(cmd)
    return vim.json.decode(data)
end


local vsenv_script = [==[
$vswhere = ("vswhere", "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe") | 
           %{get-command -Name $_ -CommandType Application -ErrorAction Ignore} |
           ?{$_ -ne $null} |
           select-object -first 1
$vsroot = (& $vswhere -format json -products "*" | ConvertFrom-Json)[0].installationPath
$vscmd = "`"$vsroot\Common7\Tools\VsDevCmd.bat`" -arch=amd64 -host_arch=amd64 -no_logo > NUL & set"
$result = @{}
foreach ($line in (& cmd /D /C $vscmd)) {
    if ($line -match "^(\S*?)\s*=\s*(.*)$") {
        $result[$matches[1]] = $matches[2]
    }
}
echo ($result | ConvertTo-Json)
]==]

local function pscript(text)
    return vim.fn.system({
        "powershell", "-NoLogo", "-NoProfile",
        "-ExecutionPolicy", "RemoteSigned",
        "-Command",
        "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
        text,
    })
end

local function vsenv()
    local text = pscript(vsenv_script)
    return vim.json.decode(text)
end

return {
    vswhere = vswhere,
    pscript = pscript,
    vsenv = vsenv,
}
