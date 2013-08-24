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
    HNDiffOperatorInserted,     // （符号列1の符号が）挿入された
    HNDiffOperatorModified,     // 変更された
    HNDiffOperatorDeleted,      // （符号列0の符号が）削除された
    HNDiffOperatorNotChanged,   // 変化なし
} HNDiffOperator;

/**
 * 差分抽出結果に含まれる差分操作1つ分の情報を格納するオブジェクト
 */
@interface HNDiffOperation : NSObject

/** 操作の種類 */
@property(nonatomic, assign) HNDiffOperator op;

/** 符号列0のインデックス */
@property(nonatomic, assign) NSInteger from0;

/** 符号列1のインデックス */
@property(nonatomic, assign) NSInteger from1;

/** 符号列0がこの操作でどれだけ進むか（操作の符号数） */
@property(nonatomic, assign) NSInteger count0;

/** 符号列1がこの操作でどれだけ進むか（操作の符号数） */
@property(nonatomic, assign) NSInteger count1;

@end
