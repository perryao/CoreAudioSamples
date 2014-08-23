//
//  main.m
//  CAToneFileGenerator
//
//  Created by Mike Perry on 8/23/14.
//  Copyright (c) 2014 Anthony Perry. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioToolbox;

static const int SAMPLE_RATE = 44100;
static const float DURATION = 5.0;
//static NSString * const FILENAME_FORMAT = @"%0.3f-square.aif";
//static NSString * const FILENAME_FORMAT = @"%0.3f-saw.aif";
static NSString * const FILENAME_FORMAT = @"%0.3f-sine.aif";


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printf("Usage: CAToneFileGenerator n\n(where n is tone in Hz");
            return EXIT_FAILURE;
        }

        double hz = atof(argv[1]);
        assert(hz > 0);
        NSLog(@"generating %f hz tone", hz);
        NSString *fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz];
        NSString *filePath = [[[NSFileManager defaultManager]currentDirectoryPath]stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];

        //Prepare the format
        AudioStreamBasicDescription asbd;
        memset(&asbd, 0, sizeof(asbd));
        asbd.mSampleRate = SAMPLE_RATE;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        asbd.mBitsPerChannel = 16;
        asbd.mChannelsPerFrame = 1;
        asbd.mFramesPerPacket = 1;
        asbd.mBytesPerFrame = 2;
        asbd.mBytesPerPacket = 2;

        //Setup the file
        AudioFileID audioFile;
        OSStatus audioErr = noErr;
        audioErr = AudioFileCreateWithURL((__bridge CFURLRef)fileURL, kAudioFileAIFFType, &asbd, kAudioFileFlags_EraseFile, &audioFile);
        assert(audioErr == noErr);

        //Start writing samples
        long maxSampleCount = SAMPLE_RATE * DURATION;
        long sampleCount = 0;
        UInt32 bytesToWrite = 2;
        double wavelengthInSamples = SAMPLE_RATE / hz;

        while (sampleCount < maxSampleCount) {
            for (int i = 0; i < wavelengthInSamples; i++) {
                //Square wave
                //                SInt16 sample;
                //                if (i < wavelengthInSamples / 2) {
                //                    sample = CFSwapInt16HostToBig(SHRT_MAX);
                //                } else {
                //                    sample = CFSwapInt16HostToBig(SHRT_MIN);
                //                }

                //saw wave
                //SInt16 sample = CFSwapInt16HostToBig(((i / wavelengthInSamples) * SHRT_MAX * 2) - SHRT_MAX);

                //sine wave
                SInt16 sample = CFSwapInt16HostToBig((SInt16)SHRT_MAX * sin(2 * M_PI * (i / wavelengthInSamples)));
                audioErr = AudioFileWriteBytes(audioFile, false, sampleCount * 2, &bytesToWrite, &sample);
                assert(audioErr == noErr);
                sampleCount++;
            }
        }
        audioErr = AudioFileClose(audioFile);
        assert(audioErr == noErr);
        NSLog(@"Wrote %d samples", sampleCount);
    }
    return 0;
}
