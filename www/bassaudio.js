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
    stop: function(channel, fadeout, successCallback, errorCallback) {
        fadeout = fadeout || 0;

        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "stop", [channel, fadeout]
        );
    },
    setVolume: function(channel, volume, successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "setVolume", [channel, volume]
        );
    },
    onfree: function(channel) {}
};
