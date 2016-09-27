//
//  LFAudioRecorder.h
//  WiseUC
//
//  Created by mxc235 on 16/9/27.
//  Copyright © 2016年 WiseUC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFAudioRecorder : NSObject

@property (nonatomic, strong) NSDateFormatter *fileNameFormatter;   // 文件名字时间格式
@property (nonatomic, strong) NSString *folderName;   // 文件夹路径

- (BOOL)startRecorder;      // 开始录音

// 结束录音
- (void)stopRecorderWithCompletion:(void(^)(NSString *recordPath,
                                            NSInteger aDuration,
                                            NSError *error))completion;

- (BOOL)playVoice;          // 播放录音文件

@end
