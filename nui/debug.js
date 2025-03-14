window.addEventListener('DOMContentLoaded', function() {
    fetch("https://pickle_casinos/pageLoaded").then(function(response) {
        // PRODUCTION MODE
    }).catch(function(error) {
        // DEBUG MODE
    });
    // setTimeout(function() {
    //     // window.postMessage({
    //     //     type: "setConfig",
    //     //     config: {
    //     //         identifier: "char:1",
    //     //     }
    //     // }, '*');
    // }, 1000);
});