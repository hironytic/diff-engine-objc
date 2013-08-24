/*
 * HNFileLineSequences.m
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

#import "HNFileLineSequences.h"

@implementation HNFileLineSequences {
@private
    NSArray *m_firstLines;
    NSArray *m_secondLines;
}

- (BOOL)loadFile:(NSString *)filePath forSequence:(NSInteger)seqNo {
    NSString *wholeContents = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    if (nil == wholeContents) {
        return NO;
    }
    
    NSArray *lines = [wholeContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if (0 == seqNo) {
        m_firstLines = lines;
    } else {
        m_secondLines = lines;
    }
    return YES;
}

- (NSString *)lineForIndex:(NSInteger)index ofSequence:(NSInteger)seqNo {
    NSArray *lines = (0 == seqNo) ? m_firstLines : m_secondLines;
    return [lines objectAtIndex:index];
}

- (NSInteger)lengthOfSequence:(NSInteger)seqNo {
    if (0 == seqNo) {
        return [m_firstLines count];
    } else {
        return [m_secondLines count];
    }
}

- (BOOL)isSameElementAtIndexInSequence0:(NSInteger)index0 andElementAtIndexInSequence1:(NSInteger)index1 {
    NSString *first = [m_firstLines objectAtIndex:index0];
    NSString *second = [m_secondLines objectAtIndex:index1];
    return [first isEqualToString:second];
}

@end
