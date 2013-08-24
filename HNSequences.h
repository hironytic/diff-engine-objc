/*
 * HNSequences.h
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

/**
 * 差分抽出を行う対象の符号列にアクセスするためのプロトコル
 */
@protocol HNSequences <NSObject>

/**
 * 指定した符号列の長さを得ます。
 * @param seqNo 0または1を指定します。
 * @return 符号列の長さを返します。
 */
- (NSInteger)lengthOfSequence:(NSInteger)seqNo;

/**
 * 指定したインデックスの符号が一致するかどうかを調べます。
 * @param index0 符号列0のインデックス
 * @param index1 符号列1のインデックス
 * @return 一致するならYES、一致しないならNO
 */
- (BOOL)isSameElementAtIndexInSequence0:(NSInteger)index0 andElementAtIndexInSequence1:(NSInteger)index1;

@end
