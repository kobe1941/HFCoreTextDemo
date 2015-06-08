//
//  HFCoreTextView.h
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import <UIKit/UIKit.h>

// 行距
extern const CGFloat kGlobalLineLeading;

// 在15字体下，比值小于这个则显示emoji不全
extern const CGFloat kPerLineRatio;


typedef NS_ENUM(NSInteger, HFDrawType){
    HFDrawPureText,                // 只绘制纯文本，对应第一篇博文
    HFDrawTextAndPicture,          // 图文混排，对应第二篇博文
    HFDrawTextLineByLine,          // 一行一行的绘制纯文本，不对齐，对应第三篇博文
    HFDrawTextLineByLineAlignment, // 一行一行的绘制纯文本，对齐，对应第三篇博文
    HFDrawTextWithEllipses,        // 一行一行的绘制纯文本，高度不够加省略号
    HFDrawTextWithCheckClick       // 识别点击特定字符串
};
@interface HFCoreTextView : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) HFDrawType drawType;


// 计算高度的代码
+ (CGFloat)textHeightWithText:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont type:(HFDrawType)drawType;

@end
