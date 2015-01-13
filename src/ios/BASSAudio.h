#import <Cordova/CDV.h>
#import "bass.h"

@interface BASSAudio: CDVPlugin

- (void)play: (CDVInvokedUrlCommand*)command;
- (void)stop: (CDVInvokedUrlCommand*)command;

- (void)stopAndFreeChannel: (DWORD)channel;

@property (strong, nonatomic) NSMutableDictionary* restartTimes;

@end
