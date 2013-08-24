/*
 * main.m
 *
 * Copyright (c) 2013 Hironori Ichimiya <hiron@hironytic.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "HNFileLineSequences.h"
#import "HNDiff.h"
#import "HNDiffOperation.h"

@interface Example2 : NSObject
+ (int)runWithArgc:(int)argc argv:(const char **)argv;
@end

@implementation Example2

+ (int)runWithArgc:(int)argc argv:(const char **)argv {
    if (argc < 2) {
        fputs("Usage: Example2 <first-text-file> <second-text-file>", stderr);
        return -1;
    }
    
    // load files
    HNFileLineSequences *sequences = [[HNFileLineSequences alloc] init];
    if (![sequences loadFile:[NSString stringWithUTF8String:argv[1]] forSequence:0]) {
        fputs("can't read first file.", stderr);
        return -2;
    }
    if (![sequences loadFile:[NSString stringWithUTF8String:argv[2]] forSequence:1]) {
        fputs("can't read second file.", stderr);
        return -3;
    }
    
    // execute diff
    HNDiff *diff = [[HNDiff alloc] init];
    [diff detect:sequences];
    
    // output
    NSInteger opCount = [diff operationCount];
    for (NSInteger opIndex = 0; opIndex < opCount; ++opIndex) {
        HNDiffOperation *operation = [diff operationAtIndex:opIndex];
        switch (operation.op) {
            case HNDiffOperatorInserted:
                [self outputLineWithOperation:@"+"
                                    fromIndex:operation.from1
                                        count:operation.count1
                                   ofSequence:1
                                    sequences:sequences];
                break;
            case HNDiffOperatorDeleted:
                [self outputLineWithOperation:@"-"
                                    fromIndex:operation.from0
                                        count:operation.count0
                                   ofSequence:0
                                    sequences:sequences];
                break;
            case HNDiffOperatorModified:
                [self outputLineWithOperation:@"-"
                                    fromIndex:operation.from0
                                        count:operation.count0
                                   ofSequence:0
                                    sequences:sequences];
                [self outputLineWithOperation:@"+"
                                    fromIndex:operation.from1
                                        count:operation.count1
                                   ofSequence:1
                                    sequences:sequences];
                break;
            case HNDiffOperatorNotChanged:
                [self outputLineWithOperation:@" "
                                    fromIndex:operation.from0
                                        count:operation.count0
                                   ofSequence:0
                                    sequences:sequences];
                break;
        }
    }
    return 0;
}

+ (void)outputLineWithOperation:(NSString *)operation
                      fromIndex:(NSInteger)from
                          count:(NSInteger)count
                     ofSequence:(NSInteger)seqNo
                      sequences:(HNFileLineSequences *)sequences {
    for (NSInteger index = 0; index < count; ++index) {
        printf("%s%s\n", [operation UTF8String], [[sequences lineForIndex:from + index ofSequence:seqNo] UTF8String]);
    }
}

@end

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        return [Example2 runWithArgc:argc argv:argv];
    }
}
