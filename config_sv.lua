ConfigSV = {}
ConfigSV.Webhooks = {
    ["purchaseChips"] = { 
        url = "DISCORD_WEBHOOK_URL",
        title = "Casino Chips Purchased", 
        fields = {
            { name = "Casino ID", value = "casinoId", inline = false },
            { name = "Casino Label", value = "casinoLabel", inline = false },
            { name = "Player", value = "player", inline = false },
            { name = "Currency", value = "currency", inline = false },
            { name = "Price", value = "price", inline = false },
            { name = "Chips Given", value = "chips", inline = false },
        } 
    },
    ["sellChips"] = { 
        url = "DISCORD_WEBHOOK_URL",
        title = "Casino Chips Sold",
        fields = {
            { name = "Casino ID", value = "casinoId", inline = false },
            { name = "Casino Label", value = "casinoLabel", inline = false },
            { name = "Player", value = "player", inline = false },
            { name = "Chips Given", value = "price", inline = false },
            { name = "Money", value = "chips", inline = false },
        }
    },
}

ConfigSV.WebhookHandler = function(webhookId, fields)
    local webhook = ConfigSV.Webhooks[webhookId]
    if webhook then
        if webhook.url == "DISCORD_WEBHOOK_URL" then return end
        local embed = {
            {
                ["title"] = webhook.title,
                ["color"] = 16711680,
                ["fields"] = {},
                ["footer"] = {
                    ["text"] = "Pickle's Casinos - " .. os.date("%c"),
                },
            }
        }
        for i=1, #webhook.fields do
            local field = webhook.fields[i]
            table.insert(embed[1].fields, {
                ["name"] = field.name,
                ["value"] = fields[field.value],
                ["inline"] = field.inline or false
            })
        end
        PerformHttpRequest(webhook.url, function(err, text, headers) end, "POST", json.encode({embeds = embed}), {["Content-Type"] = "application/json"})
    end
end