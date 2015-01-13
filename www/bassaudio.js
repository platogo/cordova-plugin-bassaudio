module.exports = {
    play: function(fileName, opts, successCallback, errorCallback) {
        opts = opts || {};

        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "play", [fileName, opts]
        );
    },
    stop: function(channel, successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "stop", [channel]
        );
    },
    onfree: function(channel) {}
};
