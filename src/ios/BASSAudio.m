#import "BASSAudio.h"

void CALLBACK onPosSync(HSYNC handle, DWORD channel, DWORD data, void* user)
{
    BASSAudio* bassAudio = (__bridge BASSAudio*) user;
    id restartObj = [bassAudio.restartTimes objectForKey:[@(channel) stringValue]];

    if (restartObj != nil) {
        QWORD restartTimeInBytes = BASS_ChannelSeconds2Bytes(channel, [restartObj intValue] / 1000.0);
        BASS_ChannelSetPosition(channel, restartTimeInBytes, BASS_POS_BYTE);

        if (BASS_ChannelIsActive(channel) != BASS_ACTIVE_PLAYING) {
            BASS_ChannelPlay(channel, FALSE);
        }
    } else {
        [bassAudio stopAndFreeChannel:channel];
    }
}

void CALLBACK onFadeOutSync(HSYNC handle, DWORD channel, DWORD data, void* user)
{
    BASSAudio* bassAudio = (__bridge BASSAudio*) user;
    [bassAudio stopAndFreeChannel:channel];
}

@implementation BASSAudio

- (void)pluginInitialize
{
    BASS_Init(-1, 44100, 0, 0, NULL);
    BASS_SetConfig(BASS_CONFIG_IOS_MIXAUDIO, 4);

    self.restartTimes = [[NSMutableDictionary alloc] init];
}

- (void)play: (CDVInvokedUrlCommand*)command
{
    NSString* fileName = [command.arguments objectAtIndex:0];
    NSDictionary* opts = [command.arguments objectAtIndex:1];

    HSTREAM channel = BASS_StreamCreateFile(FALSE, [fileName UTF8String], 0, 0, 0);

    id optObj = [opts objectForKey:@"volume"];
    if (optObj != nil) {
        BASS_ChannelSetAttribute(channel, BASS_ATTRIB_VOL, [optObj doubleValue]);
    }

    optObj = [opts objectForKey:@"pan"];
    if (optObj != nil) {
        BASS_ChannelSetAttribute(channel, BASS_ATTRIB_PAN, [optObj doubleValue]);
    }

    optObj = [opts objectForKey:@"startTime"];
    if (optObj != nil) {
        QWORD startTimeInBytes = BASS_ChannelSeconds2Bytes(channel, [optObj intValue] / 1000.0);
        BASS_ChannelSetPosition(channel, startTimeInBytes, BASS_POS_BYTE);
    }

    optObj = [opts objectForKey:@"restartTime"];
    if (optObj != nil) {
        [self.restartTimes setObject:optObj forKey:[@(channel) stringValue]];
    }

    optObj = [opts objectForKey:@"endTime"];
    if (optObj != nil) {
        QWORD endTimeInBytes = BASS_ChannelSeconds2Bytes(channel, [optObj intValue] / 1000.0);
        BASS_ChannelSetSync(channel, BASS_SYNC_POS, endTimeInBytes, onPosSync, (__bridge void *)(self));
    }
    BASS_ChannelSetSync(channel, BASS_SYNC_END, 0, onPosSync, (__bridge void *)(self));

    BASS_ChannelPlay(channel, FALSE);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:channel];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop: (CDVInvokedUrlCommand*)command
{
    DWORD channel = [[command.arguments objectAtIndex:0] intValue];
    DWORD fadeout = [[command.arguments objectAtIndex:1] intValue];

    if (fadeout > 0) {
        BASS_ChannelSetSync(channel, BASS_SYNC_SLIDE, 0, onFadeOutSync, (__bridge void *)(self));
        BASS_ChannelSlideAttribute(channel, BASS_ATTRIB_VOL, 0, fadeout);
    } else {
        [self stopAndFreeChannel:channel];
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setVolume: (CDVInvokedUrlCommand*)command
{
    DWORD channel = [[command.arguments objectAtIndex:0] intValue];
    double volume = [[command.arguments objectAtIndex:1] doubleValue];

    BASS_ChannelSetAttribute(channel, BASS_ATTRIB_VOL, volume);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pause: (CDVInvokedUrlCommand*)command
{
    BASS_Pause();

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)resume: (CDVInvokedUrlCommand*)command
{
    BASS_Start();

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)mute: (CDVInvokedUrlCommand*)command
{
    BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, 0);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unmute: (CDVInvokedUrlCommand*)command
{
    BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, 10000);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopAndFreeChannel: (DWORD)channel
{
    [self.restartTimes removeObjectForKey:[@(channel) stringValue]];

    BASS_ChannelStop(channel);
    BASS_StreamFree(channel);

    NSString* js = [NSString stringWithFormat:@"setTimeout('bassaudio.onfree(%d)',0)", channel];
    [self.commandDelegate evalJs:js];
}

@end
