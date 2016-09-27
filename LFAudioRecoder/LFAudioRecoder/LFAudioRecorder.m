//
//  LFAudioRecorder.m
//  WiseUC
//
//  Created by mxc235 on 16/9/27.
//  Copyright © 2016年 WiseUC. All rights reserved.
//

#import "LFAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

const NSTimeInterval recordMinDuration  = 1.0;

typedef NS_ENUM(NSInteger,EMErrorType) {
    EMErrorAudioRecordDurationTooShort        //录音时间过短
};

@implementation LFAudioRecorder
{
    // Recorder & Player
    AVAudioRecorder *_avRecorder;
    AVAudioPlayer *_avPlayer;
    
    //    Flag
    BOOL _isRecording;
    BOOL _isConverting;
    
    NSDate   *_recorderStartDate;
    NSDate   *_recorderEndDate;
    
    NSString *_lastRecordFileName;
    NSString *_mp3FilePath;
}

- (instancetype)init
{
    if (self == [super init]) {
        _isRecording = NO;
        _isConverting = NO;
        _fileNameFormatter = [[NSDateFormatter alloc] init];
        [_fileNameFormatter setDateFormat:@"yyyyMMddhhmmss"];
    }
    return self;
}

- (BOOL)startRecorder
{
    NSString *fileName = [self.fileNameFormatter stringFromDate:[NSDate date]];
    fileName = [fileName stringByAppendingString:@".caf"];
    NSString *cafFilePath = [self.folderName stringByAppendingPathComponent:fileName];
    
    if (!fileName) {
        return NO;
    }
    
    NSURL *cafURL = [NSURL fileURLWithPath:cafFilePath];
    NSError *error;
    
    NSDictionary *recordFileSettings = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:AVAudioQualityMin],
                                        AVEncoderAudioQualityKey,
                                        [NSNumber numberWithInt:16],
                                        AVEncoderBitRateKey,
                                        [NSNumber numberWithInt: 2],
                                        AVNumberOfChannelsKey,
                                        [NSNumber numberWithFloat:44100.0],
                                        AVSampleRateKey,
                                        nil];
    
    
    @try {
        if (!_avRecorder) {
            _avRecorder = [[AVAudioRecorder alloc] initWithURL:cafURL settings:recordFileSettings error:&error];
        }else {
            if ([_avRecorder isRecording]) {
                [_avRecorder stop];
            }
            _avRecorder = nil;
            _avRecorder = [[AVAudioRecorder alloc] initWithURL:cafURL settings:recordFileSettings error:&error];
        }
        
        if (_avRecorder) {
            [_avRecorder prepareToRecord];
            _avRecorder.meteringEnabled = YES;
            
            [_avRecorder record];
            NSLog(@"_avRecorder recording");
            _recorderStartDate = [NSDate new];
            _lastRecordFileName = fileName;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"%@",[error description]);
    }
    return YES;
}

- (void)stopRecorderWithCompletion:(void (^)(NSString *, NSInteger, NSError *))completion
{
    _recorderEndDate = [NSDate new];

    if (_avRecorder) {
        // 如果录音时间太短，延迟一秒停止录音
        if ([_recorderEndDate timeIntervalSinceDate:_recorderStartDate] < recordMinDuration) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSError *error = [NSError errorWithDomain:@"Recording error"
                                                     code:EMErrorAudioRecordDurationTooShort
                                                 userInfo:nil];
                
                
                @try {
                    [_avRecorder stop];
                    _avRecorder = nil;
                    _mp3FilePath = [self toMp3:_lastRecordFileName];
                    
                }
                @catch (NSException *exception) {
                    
                }
                @finally {
            
                    NSInteger duration = (int)[self->_recorderEndDate timeIntervalSinceDate:self->_recorderStartDate];
                    if (_mp3FilePath && completion ) {
                        completion(_mp3FilePath,duration,nil);
                    }else{
                        completion(nil,0,error);
                    }
                }
            });
            
        }else{
            
            NSError *error = [NSError errorWithDomain:@"Recording error"
                                                 code:EMErrorAudioRecordDurationTooShort
                                             userInfo:nil];
            
            @try {
                [_avRecorder stop];
                _avRecorder = nil;
                _mp3FilePath = [self toMp3:_lastRecordFileName];
            }
            @catch (NSException *exception) {

            }
            @finally {
                
                NSInteger duration = (int)[self->_recorderEndDate timeIntervalSinceDate:self->_recorderStartDate];
                if (_mp3FilePath && completion ) {
                    completion(_mp3FilePath,duration,nil);
                }else{
                    completion(nil,0,error);
                }
                
            }
        }
    }
}

#pragma mark -

- (NSString *)toMp3:(NSString*)cafFileName
{
    NSString *cafFilePath = [_folderName stringByAppendingPathComponent:cafFileName];
    NSString *mp3FilePath = [[cafFilePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");//被转换的文件
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");//转换后文件的存放位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 44100);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
//        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:cafFilePath error:nil];
        
        BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:mp3FilePath];
        if (!isFileExists) {
            return nil;
        } else {
            return mp3FilePath;
        }
    }
    return nil;
}

- (BOOL)playVoice
{
    return YES;
}

@end
