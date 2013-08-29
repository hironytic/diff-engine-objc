/*
 * HNDiff.mm
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

#import <vector>
#import "HNDiff.h"
#import "HNSequences.h"
#import "HNDiffOperation.h"

struct FPData;

typedef std::vector<FPData>	FPDataVector;

// data about a furthest point
struct FPData
{
    NSInteger y;            // y-coordinate of the furthest point (corresponding to fp[k] in Wu's algorithm)
    NSInteger x;            // x-coordinate of the furthest point
    FPDataVector::difference_type prevFPDataIndex;    // FPData located before snake (as index for m_fpDataVector)
};

@implementation HNDiff {
@private
    id <HNSequences> m_sequences;   // target sequences
    BOOL m_isSwapped;               // YES if swapped so that it meets the condition of m <= n
    NSMutableArray *m_diffResult;   // result of detection

    // the following is available only in detect:
    FPDataVector m_fpDataVector;            // array to which generated FPData is added.
    FPDataVector::size_type *m_fp;          // working storage for furthest point on diagonal k
                                            // (corresponding to fp in Wu's algorithm except that the value is (index-of-fpDataVector + 1).
                                            // if the value is 0, it meens "not computed" and is described as -1 in Wu's one.)
    FPDataVector::size_type *m_fpBuffer;    // actual allocated buffer of m_fp. (m_fp is moved pointer from this)
}

/**
 * Detects differences.
 * @param sequences target sequences
 */
- (void)detect:(id<HNSequences>)sequences {

    // Note that each x, y in FPData equals to
    // index-of-shorter-sequence + 1, index-of-longer-sequence + 1.
    
    m_sequences = sequences;
    m_isSwapped = ([sequences lengthOfSequence:0] > [sequences lengthOfSequence:1]);
    m_diffResult = [[NSMutableArray alloc] init];
    
    if (nil == sequences) {
        // only clear the result if the target sequences are not set.
        return;
    }
    
    // preprocess
    NSInteger m = [self lengthOfSequence:0];
    NSInteger n = [self lengthOfSequence:1];
    NSInteger delta = n - m;
    
    if (0 == m) {
        // special handling of an empty sequence
        if (0 != n) {
            // the longer sequence is not empty
            if (m_isSwapped) {
                [self outputOperation:HNDiffOperatorDeleted
                                from0:0
                                from1:0
                               count0:n
                               count1:0];
            } else {
                [self outputOperation:HNDiffOperatorInserted
                                from0:0
                                from1:0
                               count0:0
                               count1:n];
            }
        }
        return;
    }
    
    m_fpBuffer = static_cast<FPDataVector::size_type *>(malloc((m + n + 3) * sizeof(FPDataVector::size_type)));
    if (NULL == m_fpBuffer) {
        // out of memory
        return;
    }
    memset(m_fpBuffer, 0, (m + n + 3) * sizeof(FPDataVector::size_type));
    m_fp = m_fpBuffer + m + 1;
    
    // traverse
    NSInteger p;
    for (p = 0; p < m; ++p) {   // "p < m" is for just in case
        NSInteger k;
        for (k = -p; k <= delta - 1; ++k) {
            [self snake:k];
        }
        for (k = delta + p; k >= delta; --k) {
            [self snake:k];
        }
        
        FPDataVector::difference_type fpDataIndexDelta = m_fp[delta] - 1;
        NSInteger fpDelta = (0 > fpDataIndexDelta) ? -1 : m_fpDataVector[fpDataIndexDelta].y;
        if (fpDelta == n) {
            break;
        }
    }
    
    // trace the path and make a diff-result
    [self makeResult];
    
    // postprocess
    free(m_fpBuffer);
    m_fpBuffer = m_fp = NULL;
    m_fpDataVector.clear();
}

/**
 * The "snake"
 *
 * It does not only traverse diagnonal edges, but remember its path
 */
- (void)snake:(NSInteger)k {
    FPDataVector::difference_type fpDataIndex0 = m_fp[k - 1] - 1;
    FPDataVector::difference_type fpDataIndex1 = m_fp[k + 1] - 1;
    
    NSInteger fpY0 = (0 > fpDataIndex0) ? -1 : m_fpDataVector[fpDataIndex0].y;
    NSInteger fpY1 = (0 > fpDataIndex1) ? -1 : m_fpDataVector[fpDataIndex1].y;
    
    FPData data;
    if (fpY0 + 1 > fpY1) {
        data.y = fpY0 + 1;
        data.prevFPDataIndex = fpDataIndex0;
    } else {
        data.y = fpY1;
        data.prevFPDataIndex = fpDataIndex1;
    }
    data.x = data.y - k;
    
    while (data.x < [self lengthOfSequence:0] && data.y < [self lengthOfSequence:1] && [self isSameElementAtIndexInSequence0:data.x andElementAtIndexInSequence1:data.y]) {
        ++(data.x);
        ++(data.y);
    }
    
    m_fpDataVector.push_back(data);
    m_fp[k] = static_cast<NSInteger>(m_fpDataVector.size());
}

/**
 * Traces the path and makes a diff-result
 */
- (void)makeResult {
    // First of all, let fpDataIndex be the index of (fp[delta] - 1)
    // It was found in last snake, so it equals to the index of the last furthest point.
    FPDataVector::difference_type fpDataIndex = m_fpDataVector.size() - 1;
    const FPData *data = &m_fpDataVector[fpDataIndex];
    NSInteger to0 = (m_isSwapped) ? data->y : data->x;
    NSInteger to1 = (m_isSwapped) ? data->x : data->y;
    fpDataIndex = data->prevFPDataIndex;
    while (0 <= fpDataIndex) {
        data = &m_fpDataVector[fpDataIndex];
        fpDataIndex = data->prevFPDataIndex;
        NSInteger from0 = (m_isSwapped) ? data->y : data->x;
        NSInteger from1 = (m_isSwapped) ? data->x : data->y;
        if (from1 - from0 < to1 - to0) {
            // inserted
            if (from1 + 1 < to1) {
                // output the path of skane in advance
                [self outputOperation:HNDiffOperatorNotChanged
                                from0:from0
                                from1:from1 + 1
                               count0:to1 - (from1 + 1)
                               count1:to1 - (from1 + 1)];
            }
            [self outputOperation:HNDiffOperatorInserted
                            from0:from0
                            from1:from1
                           count0:0
                           count1:1];
        } else {
            // deleted
            if (from0 + 1 < to0) {
                // output the path of skane in advance
                [self outputOperation:HNDiffOperatorNotChanged
                                from0:from0 + 1
                                from1:from1
                               count0:to0 - (from0 + 1)
                               count1:to0 - (from0 + 1)];
            }
            [self outputOperation:HNDiffOperatorDeleted
                            from0:from0
                            from1:from1
                           count0:1
                           count1:0];
        }
        
        to0 = from0;
        to1 = from1;
    }
    if (to0 != 0) {
        // It reaches here when the first operation is "not changed".
        // Because the first furthest point should be (0,0) if the first operation is "inserted" or "deleted",
        // then it should be to0 == to1 == 0 at the end of the loop.
        [self outputOperation:HNDiffOperatorNotChanged
                        from0:0
                        from1:0
                       count0:to0
                       count1:to0];
    }
    
    
}

/**
 * Outputs the result. Called in makeResult.
 * @param op operator
 * @param from0 index in sequence 0
 * @param from1 index in sequence 1
 * @param count0 count of elements in sequence 0 from from0. (at this operation)
 * @param count1 count of elements in sequence 1 from from1. (at this operation)
 */
- (void)outputOperation:(HNDiffOperator)op
                  from0:(NSInteger)from0
                  from1:(NSInteger)from1
                 count0:(NSInteger)count0
                 count1:(NSInteger)count1 {
    // combine each consecutive "deletion"s or consequcive "insertion"s into one.
    // and if is is found that a consecutive "insertion"-("deletion" or "modification") or a consecutive "insertion"-("deletion" or "modification"),
    // then it comes into one "modification"
    NSUInteger diffResultSize = [m_diffResult count];
    if (0 < diffResultSize) {
        BOOL toBind = NO;
        HNDiffOperation *lastOperation = [m_diffResult lastObject];
        if (lastOperation.from0 == from0 + count0 && lastOperation.from1 == from1 + count1) {
            if (HNDiffOperatorInserted == op) {
                if (HNDiffOperatorInserted == lastOperation.op ||
                    HNDiffOperatorModified == lastOperation.op) {
                    toBind = YES;
                } else if (HNDiffOperatorDeleted == lastOperation.op) {
                    lastOperation.op = HNDiffOperatorModified;
                    toBind = YES;
                }
            } else if (HNDiffOperatorDeleted == op) {
                if (HNDiffOperatorDeleted == lastOperation.op ||
                    HNDiffOperatorModified == lastOperation.op) {
                    toBind = YES;
                } else if (HNDiffOperatorInserted == lastOperation.op) {
                    lastOperation.op = HNDiffOperatorModified;
                    toBind = YES;
                }
            }
        }
        if (toBind) {
            lastOperation.from0 = from0;
            lastOperation.from1 = from1;
            lastOperation.count0 += count0;
            lastOperation.count1 += count1;
            return;
        }
    }
    
    // not combined? then append it.
    HNDiffOperation *operation = [[HNDiffOperation alloc] init];
    operation.op = op;
    operation.from0 = from0;
    operation.from1 = from1;
    operation.count0 = count0;
    operation.count1 = count1;
    [m_diffResult addObject:operation];
}

/**
 * returns a diff-operation at specified index.
 * @param index index
 * @return diff-operation is returned
 */
- (HNDiffOperation *)operationAtIndex:(NSInteger)index {
    if (nil == m_diffResult) {
        return nil;
    }
    
    // note that m_diffResult is reverse-ordered
    NSInteger resultIndex = [m_diffResult count] - 1 - index;
    if (resultIndex < 0 || index < 0) {
        return nil;
    }
    
    return [m_diffResult objectAtIndex:resultIndex];
}

/**
 * returns the number of diff-operations.
 */
- (NSInteger)operationCount {
    return (nil == m_diffResult) ? 0 : [m_diffResult count];
}


/**
 * returns length of the sequence.
 * @param seqNo specify 0 or 1
 * @return length of the sequence
 */
- (NSInteger)lengthOfSequence:(NSInteger)seqNo {
    if (m_isSwapped) {
        seqNo = (seqNo == 0) ? 1 : 0;
    }
    return [m_sequences lengthOfSequence:seqNo];
}

/**
 * determine whether two elements are same
 * @param index0 index of sequence 0
 * @param index1 index of sequence 1
 * @return returns YES when elements are same
 */
- (BOOL)isSameElementAtIndexInSequence0:(NSInteger)index0 andElementAtIndexInSequence1:(NSInteger)index1 {
    if (m_isSwapped) {
        return [m_sequences isSameElementAtIndexInSequence0:index1 andElementAtIndexInSequence1:index0];
    } else {
        return [m_sequences isSameElementAtIndexInSequence0:index0 andElementAtIndexInSequence1:index1];
    }
}

@end
