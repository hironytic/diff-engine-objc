/*
 * HNDiffOperation.h
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

typedef enum {
    HNDiffOperatorInserted,     // (the elements of sequence 1 are) inserted
    HNDiffOperatorModified,     // modified
    HNDiffOperatorDeleted,      // (the elements of sequence 0 are) deleted
    HNDiffOperatorNotChanged,   // no change
} HNDiffOperator;

/**
 * one diff-operaton
 */
@interface HNDiffOperation : NSObject

/** operator */
@property(nonatomic, assign) HNDiffOperator op;

/** index in sequence 0 */
@property(nonatomic, assign) NSInteger from0;

/** index in sequence 1 */
@property(nonatomic, assign) NSInteger from1;

/** count of elements in sequence 0 from from0 */
@property(nonatomic, assign) NSInteger count0;

/** count of elements in sequence 1 from from1 */
@property(nonatomic, assign) NSInteger count1;

@end
