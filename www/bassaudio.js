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
    pause: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "pause", []
        );
    },
    resume: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "resume", []
        );
    },
    mute: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "mute", []
        );
    },
    unmute: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "BASSAudio",
            "unmute", []
        );
    },
    onfree: function(channel) {}
};
