package com.platogo.cordova.bassaudio;

import com.un4seen.bass.BASS;
import java.util.Hashtable;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class BASSAudio extends CordovaPlugin {
    public static final String ACTION_PLAY = "play";
    public static final String ACTION_STOP = "stop";

    private Hashtable<Integer, Double> restartTimes = new Hashtable<Integer, Double>();

    private BASS.SYNCPROC onSync = new BASS.SYNCPROC() {
        public void SYNCPROC(int handle, int channel, int data, Object user) {
            if (restartTimes.containsKey(channel)) {
                long restartTimeInBytes = BASS.BASS_ChannelSeconds2Bytes(channel, restartTimes.get(channel));
                BASS.BASS_ChannelSetPosition(channel, restartTimeInBytes, BASS.BASS_POS_BYTE);

                if (BASS.BASS_ChannelIsActive(channel) != BASS.BASS_ACTIVE_PLAYING) {
                    BASS.BASS_ChannelPlay(channel, false);
                }
            } else {
                stopAndFreeChannel(channel);
            }
        }
    };

    private BASS.SYNCPROC onFadeOutSync = new BASS.SYNCPROC() {
        public void SYNCPROC(int handle, int channel, int data, Object user) {
            stopAndFreeChannel(channel);
        }
    };

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        BASS.BASS_Init(-1, 44100, 0);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals(ACTION_PLAY)) {
            play(args.getString(0), args.getJSONObject(1), callbackContext);
            return true;
        } else if (action.equals(ACTION_STOP)) {
            stop(args.getInt(0), args.getInt(1), callbackContext);
            return true;
        }
        return false;
    }

    private void play(final String fileName, final JSONObject opts, final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                int channel = BASS.BASS_StreamCreateFile(fileName, 0, 0, 0);

                float volume = (float) opts.optDouble("volume");
                if (!Float.isNaN(volume)) {
                    BASS.BASS_ChannelSetAttribute(channel, BASS.BASS_ATTRIB_VOL, volume);
                }

                float pan = (float) opts.optDouble("pan");
                if (!Float.isNaN(pan)) {
                    BASS.BASS_ChannelSetAttribute(channel, BASS.BASS_ATTRIB_PAN, pan);
                }

                double startTime = opts.optDouble("startTime");
                if (!Double.isNaN(startTime)) {
                    long startTimeInBytes = BASS.BASS_ChannelSeconds2Bytes(channel, startTime);
                    BASS.BASS_ChannelSetPosition(channel, startTimeInBytes, BASS.BASS_POS_BYTE);
                }

                double restartTime = opts.optDouble("restartTime");
                if (!Double.isNaN(restartTime)) {
                    restartTimes.put(channel, restartTime);
                }

                double endTime = opts.optDouble("endTime");
                if (!Double.isNaN(endTime)) {
                    long endTimeInBytes = BASS.BASS_ChannelSeconds2Bytes(channel, endTime);
                    BASS.BASS_ChannelSetSync(channel, BASS.BASS_SYNC_POS, endTimeInBytes, onSync, null);
                }
                BASS.BASS_ChannelSetSync(channel, BASS.BASS_SYNC_END, 0, onSync, null);

                BASS.BASS_ChannelPlay(channel, false);

                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, channel));
            }
        });
    }

    private void stop(final int channel, final int fadeout, final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                if (fadeout > 0) {
                    BASS.BASS_ChannelSetSync(channel, BASS.BASS_SYNC_SLIDE, 0, onFadeOutSync, null);
                    BASS.BASS_ChannelSlideAttribute(channel, BASS.BASS_ATTRIB_VOL, 0, fadeout);
                } else {
                    stopAndFreeChannel(channel);
                }
            }
        });
    }

    private void stopAndFreeChannel(final int channel) {
        restartTimes.remove(channel);

        BASS.BASS_ChannelStop(channel);
        BASS.BASS_StreamFree(channel);

        String js = "setTimeout('bassaudio.onfree(" + channel + ")',0)";
        webView.sendJavascript(js);
    }
}
