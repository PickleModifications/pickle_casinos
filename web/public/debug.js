window.addEventListener('DOMContentLoaded', function() {
    // fetch("https://pickle_casinos/pageLoaded").then(function(response) {
    //     // PRODUCTION MODE
    // }).catch(function(error) {
    //     // DEBUG MODE
    // });
    setTimeout(function() {
        window.postMessage({
            type: "setConfig",
            config: {
                identifier: "char:1",
            }
        }, '*');
    }, 1000);
});

function ExecuteDebugEvent(eventName, data) {
    switch (eventName) {
        case "sendChannelMessage":
            window.postMessage({
                type: "receiveChannelMessage",
                channel: data.channel,
                message: {
                    id: Math.floor(Math.random() * 1000000),
                    user: {
                        identifier: "char:1",
                        name: "Pickle Mods",
                        role: "role_1",
                        image: "https://picklemods.com/logo_1.png"
                    },
                    datetime: Date.now() / 1000,
                    message: data.message
                }
            }, '*');
            break;
        default: 
            console.log("Unknown event: " + eventName);
            break;
    }
}

window.addEventListener("message", function(event) {
    if (event.data.eventName) {
        ExecuteDebugEvent(event.data.eventName, event.data.data);
    }
});