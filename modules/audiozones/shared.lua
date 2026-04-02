function GetAudioPresetOptions()
    local options = {}
    for k, v in pairs(Config.AmbientAudio) do
        table.insert(options, {label = v.label, value = k})
    end
    return options
end

function GetAudioPreset(presetId)
    return Config.AmbientAudio[presetId]
end
