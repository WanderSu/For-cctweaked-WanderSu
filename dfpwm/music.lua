-- 本地 DFPWM 音乐播放函数  music file volume  .音量（0.0~3.0，默认1.0）
local file = arg[1]
local volume = tonumber(arg[2]) or 1.5
local decoder = require "cc.audio.dfpwm".make_decoder()
local speakers = { peripheral.find("speaker") }
if #speakers == 0 then
    error("No speakers attached.")
end

--- 播放本地 DFPWM 文件
-- @param path 文件路径
function PlayDFPWM(path, volume)
    volume = volume or 1.0
    local file = fs.open(path, "rb")
    if not file then
        error("无法打开文件: " .. path)
    end

    while true do
        local chunk = file.read(16 * 1024)
        if not chunk then break end
        local buffer = decoder(chunk)
        for _, speaker in ipairs(speakers) do
            while not speaker.playAudio(buffer, volume) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
    file.close()
end

PlayDFPWM(file, volume)
