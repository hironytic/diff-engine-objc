/*
 * main.m
 *
 * Copyright (c) 2008, 2013 Hironori Ichimiya <hiron@hironytic.com>
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
#import "HNStringSequences.h"
#import "HNDiff.h"
#import "HNDiffOperation.h"

NSString *stringFromDiffOperator(HNDiffOperator op);

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        //                   01234567890123456
        NSString *first  = @"abdefggghiJKlmnop";
        NSString *second = @"abcdefghijklmnop";
        HNStringSequences *sequences = [[HNStringSequences alloc] initWithFirstString:first andSecondString:second];

        // diff them
        HNDiff *diff = [[HNDiff alloc] init];
        [diff detect:sequences];
        
        // print result
        NSInteger count = [diff operationCount];
        for (NSInteger index = 0; index < count; ++index) {
            HNDiffOperation *operation = [diff operationAtIndex:index];
            NSLog(@"op:%@, from0:%2ld, count0:%2ld, from1:%2ld, count1:%2ld\n", stringFromDiffOperator(operation.op), operation.from0, operation.count0, operation.from1, operation.count1);
        }
    }
    return 0;
}

NSString *stringFromDiffOperator(HNDiffOperator op) {
    NSString *result = nil;
    switch (op) {
        case HNDiffOperatorInserted:
            result = @"Inserted   ";
            break;
        case HNDiffOperatorModified:
            result = @"Modified   ";
            break;
        case HNDiffOperatorDeleted:
            result = @"Deleted    ";
            break;
        case HNDiffOperatorNotChanged:
            result = @"Not Changed";
    }
    return result;
}