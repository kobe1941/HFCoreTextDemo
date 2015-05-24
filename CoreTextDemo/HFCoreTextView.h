//
//  HFCoreTextView.h
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HFCoreTextView : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;

// 计算高度的代码
+ (CGFloat)textHeightWithText:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont;
@end
