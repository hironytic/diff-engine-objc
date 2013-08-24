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

// furthest point に関する情報
struct FPData
{
    NSInteger y;            // furthest point の y 座標（論文アルゴリズム中の fp[k] に相当）
    NSInteger x;            // furthest point の x 座標
    FPDataVector::difference_type prevFPDataIndex;    // スネーク前の点の FPData （HNDiffのm_fpDataVectorメンバのインデックス）
};

@implementation HNDiff {
@private
    id <HNSequences> m_sequences;   // 差分抽出を行う符号列たち
    BOOL m_isSwapped;               // m <= n の条件を満たすために入れ替えを行っているならYES
    NSMutableArray *m_diffResult;   // 差分抽出結果

    // 以下、detect:中にのみ有効な情報
    FPDataVector m_fpDataVector;            // 生成した FPData を入れておく配列
    FPDataVector::size_type *m_fp;          // diagonal k 上の furthest point 情報（論文アルゴリズム中の fp に相当。ただし、値が fpDataVectorのインデックス + 1 となっている点が異なる。0 は未探査（論文中では -1）を表す）
    FPDataVector::size_type *m_fpBuffer;    // m_fp のメモリを確保している実体（m_fp はこれをずらしている）
}

/**
 * 差分を抽出します。
 * @param sequences 差分抽出を行う符号列
 */
- (void)detect:(id<HNSequences>)sequences {

    // 探索結果となる FPData の x, y はそれぞれ
    // 短い符号列のインデックス + 1、長い符号列のインデックス + 1 に
    // なっていることに注意。
    
    m_sequences = sequences;
    m_isSwapped = ([sequences lengthOfSequence:0] > [sequences lengthOfSequence:1]);
    m_diffResult = [[NSMutableArray alloc] init];
    
    if (nil == sequences) {
        // 符号列がセットされてない場合は結果をクリアするだけ
        return;
    }
    
    // 前処理
    NSInteger m = [self lengthOfSequence:0];
    NSInteger n = [self lengthOfSequence:1];
    NSInteger delta = n - m;
    
    if (0 == m) {
        // 片方のシーケンスの長さが0の場合は特別にハンドリング
        if (0 != n) {
            // もう一方は長さがある場合
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
        // メモリが足りない
        return;
    }
    memset(m_fpBuffer, 0, (m + n + 3) * sizeof(FPDataVector::size_type));
    m_fp = m_fpBuffer + m + 1;
    
    // 探索
    NSInteger p;
    for (p = 0; p < m; ++p) {   // p < m は念のため
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
    
    // 探索したパスを復元して差分抽出結果を作る
    [self makeResult];
    
    // 後処理
    free(m_fpBuffer);
    m_fpBuffer = m_fp = NULL;
    m_fpDataVector.clear();
}

/**
 * snake処理
 * 単に diagonal edge をたどる処理（snake 処理）に加え、
 * たどったパスの記憶も行います。
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
 * 探索のパスをたどって差分抽出結果を求めます。
 */
- (void)makeResult {
    // まず、fp[delta] - 1 のインデックスを代入
    // これは最後のスネークで見つかるはずなので
    // 最後に追加された furthest pint 情報のインデックスに等しい
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
            // 挿入
            if (from1 + 1 < to1) {
                // スネークの分を先に出力
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
            // 削除
            if (from0 + 1 < to0) {
                // スネークの分を先に出力
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
        // 最初のoperationが変化なしの場合のみここにくる
        // 最初が追加や削除なら、初回の探索で (0,0) が furthest point になるので
        // ループを抜けた時点で to0 == to1 == 0 になっているはずだから。
        [self outputOperation:HNDiffOperatorNotChanged
                        from0:0
                        from1:0
                       count0:to0
                       count1:to0];
    }
    
    
}

/**
 * makeResultの過程でdiff操作を（後ろから）出力します。
 * @param op 操作の種類
 * @param from0 符号列0のインデックス
 * @param from1 符号列1のインデックス
 * @param count0 符号列0がこの操作でどれだけ進むか（操作の符号数）
 * @param count1 符号列1がこの操作でどれだけ進むか（操作の符号数）
 */
- (void)outputOperation:(HNDiffOperator)op
                  from0:(NSInteger)from0
                  from1:(NSInteger)from1
                 count0:(NSInteger)count0
                 count1:(NSInteger)count1 {
    // 連続する削除、連続する挿入は、まとめる。
    // 挿入－(削除または変更)、削除－(挿入または変更)は、変更にまとめる。
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
    
    // まとめられなかった場合は追加する
    HNDiffOperation *operation = [[HNDiffOperation alloc] init];
    operation.op = op;
    operation.from0 = from0;
    operation.from1 = from1;
    operation.count0 = count0;
    operation.count1 = count1;
    [m_diffResult addObject:operation];
}

/**
 * 指定したインデックスの差分操作を返します。
 * @param index インデックス
 * @return 差分操作が返ります。
 */
- (HNDiffOperation *)operationAtIndex:(NSInteger)index {
    if (nil == m_diffResult) {
        return nil;
    }
    
    // m_diffResult は逆順に出力されているのでインデックスを逆順に調整する
    NSInteger resultIndex = [m_diffResult count] - 1 - index;
    if (resultIndex < 0 || index < 0) {
        return nil;
    }
    
    return [m_diffResult objectAtIndex:resultIndex];
}

/**
 * 差分操作の数を返します。
 */
- (NSInteger)operationCount {
    return (nil == m_diffResult) ? 0 : [m_diffResult count];
}


/**
 * 指定した符号列の長さを得ます。
 * @param seqNo 0または1を指定します。
 * @return 符号列の長さを返します。
 */
- (NSInteger)lengthOfSequence:(NSInteger)seqNo {
    if (m_isSwapped) {
        seqNo = (seqNo == 0) ? 1 : 0;
    }
    return [m_sequences lengthOfSequence:seqNo];
}

/**
 * 指定したインデックスの符号が一致するかどうかを調べます。
 * @param index0 符号列0のインデックス
 * @param index1 符号列1のインデックス
 * @return 一致するならYES、一致しないならNO
 */
- (BOOL)isSameElementAtIndexInSequence0:(NSInteger)index0 andElementAtIndexInSequence1:(NSInteger)index1 {
    if (m_isSwapped) {
        return [m_sequences isSameElementAtIndexInSequence0:index1 andElementAtIndexInSequence1:index0];
    } else {
        return [m_sequences isSameElementAtIndexInSequence0:index0 andElementAtIndexInSequence1:index1];
    }
}

@end
