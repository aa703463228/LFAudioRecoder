//
//  AppDelegate.m
//  LFAudioRecoder
//
//  Created by mxc235 on 16/9/27.
//  Copyright © 2016年 mxc235. All rights reserved.
//

#import "AppDelegate.h"
#import "LFAudioRecorder.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) LFAudioRecorder *recorder;

@end

@implementation AppDelegate

- (LFAudioRecorder *)recorder
{
    if (!_recorder) {
        _recorder = [[LFAudioRecorder alloc] init];
        _recorder.folderName = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES)[0];
    }
    return _recorder;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (IBAction)recorde:(NSButton *)sender {
    
    [self.recorder startRecorder];
    
}
- (IBAction)stop:(NSButton *)sender {
    
    [self.recorder stopRecorderWithCompletion:^(NSString *recordPath, NSInteger aDuration, NSError *error) {
        NSLog(@"%@",recordPath);
    }];
    
}

@end
