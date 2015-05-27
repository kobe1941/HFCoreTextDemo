//
//  HFCoreTextView.h
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HFDrawType){
    HFDrawPureText,                // 只绘制纯文本，对应第一篇博文
    HFDrawTextAndPicture,          // 图文混排，对应第二篇博文
    HFDrawTextLineByLine,          // 一行一行的绘制纯文本，不对齐，对应第三篇博文
    HFDrawTextLineByLineAlignment, // 一行一行的绘制纯文本，对齐，对应第三篇博文
};
@interface HFCoreTextView : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) HFDrawType drawType;

// 计算高度的代码
+ (CGFloat)textHeightWithText:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont type:(HFDrawType)drawType;

@end
