//
//  HFCoreTextView.m
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import "HFCoreTextView.h"
#import <CoreText/CoreText.h>


#import "SDWebImage/SDWebImageManager.h"

#import <float.h>

// 行距
const CGFloat kGlobalLineLeading = 5.0;


// 在15字体下，比值小于这个计算出来的高度会导致emoji显示不全
const CGFloat kPerLineRatio = 1.4;

NSString *kAtRegularExpression = @"@[^\\s@]+?\\s{1}";
NSString *kNumberRegularExpression = @"\\d+[^\\d]{1}";

@interface HFCoreTextView ()<
UIGestureRecognizerDelegate
>
@property (nonatomic, assign) CTFrameRef ctFrame;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) CGFloat textHeight;
@property (nonatomic, assign) NSRange pressRange;

// 换成UITapGestureRecognizer目测也可以
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@end

@implementation HFCoreTextView

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self configSettings];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self configSettings];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        [self configSettings];
    }
    
    return self;
}

- (void)configSettings
{
    self.font = [UIFont systemFontOfSize:15];
    
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    self.longPressGesture.minimumPressDuration = 0.01;
    self.longPressGesture.delegate = self;
    [self addGestureRecognizer:self.longPressGesture];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if (self.drawType == HFDrawPureText)
    {
        [self drawRectWithPureText];
        
    } else if (self.drawType == HFDrawTextAndPicture)
    {
        [self drawRectWithPictureAndContent];
        
    } else if (self.drawType == HFDrawTextLineByLine)
    {
        [self drawRectWithLineByLine];
        
    } else if (self.drawType == HFDrawTextLineByLineAlignment)
    {
        [self drawRectWithLineByLineAlignment];
        
    } else if (self.drawType == HFDrawTextWithEllipses)
    {
        [self drawRectWithLineByLineAlignmentAndEllipses];
        
    } else if (self.drawType == HFDrawTextWithCheckClick)
    {
        [self drawRectWithCheckClick];
    }
}

#pragma mark - 绘制部分
#pragma mark - 纯文本
- (void)drawRectWithPureText
{
    // 1.获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 2.转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.bounds.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 3.创建绘制区域，可以对path进行个性化裁剪以改变显示区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    // 4.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    // 加点料
    [attributed addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(10, 5)];
    
    [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(5, 10)];
    
    // 5.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    // 6.绘制
    CTFrameDraw(ctFrame, contextRef);
}

#pragma mark - 图文混排
// 对应第二篇博文
- (void)drawRectWithPictureAndContent
{
    // 1.获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 2.转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.bounds.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 3.创建绘制区域，可以对path进行个性化裁剪以改变显示区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    // 4.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    // 加点料
    [attributed addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(10, 5)];
    
    [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(5, 10)];
    
    // 插入图片部分
    //为图片设置CTRunDelegate,delegate决定留给图片的空间大小
    NSString *weicaiImageName = @"about";
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = RunDelegateDeallocCallback;
    imageCallbacks.getAscent = RunDelegateGetAscentCallback;
    imageCallbacks.getDescent = RunDelegateGetDescentCallback;
    imageCallbacks.getWidth = RunDelegateGetWidthCallback;
    
    // ①该方式适用于图片在本地的情况
    // 设置CTRun的代理
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)(weicaiImageName));
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];//空格用于给图片留位置
    
    [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
    CFRelease(runDelegate);
    
    [imageAttributedString addAttribute:@"imageName" value:weicaiImageName range:NSMakeRange(0, 1)];
    
    // 在index处插入图片，可插入多张
    [attributed insertAttributedString:imageAttributedString atIndex:5];
    //    [attributed insertAttributedString:imageAttributedString atIndex:10];
    
    
    // ②若图片资源在网络上，则需要使用0xFFFC作为占位符
    // 图片信息字典
    NSString *picURL =@"http://weicai-hearsay-avatar.qiniudn.com/b4f71f05a1b7593e05e91b0175bd7c9e?imageView2/2/w/192/h/277";
    NSDictionary *imgInfoDic = @{@"width":@192,@"height":@277}; // 宽高跟具体图片有关
    // 设置CTRun的代理
    CTRunDelegateRef delegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)imgInfoDic);
    
    // 使用0xFFFC作为空白的占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString *content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSMutableAttributedString *space = [[NSMutableAttributedString alloc] initWithString:content];
    [space addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)delegate range:NSMakeRange(0, 1)];
//    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)space, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    
    // 将创建的空白AttributedString插入进当前的attrString中，位置可以随便指定，不能越界
    [attributed insertAttributedString:space atIndex:10];
    
    
    // 5.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    // 6.绘制除图片以外的部分
    CTFrameDraw(ctFrame, contextRef);
    
    
    // 处理绘制图片的逻辑
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    
    // 把ctFrame里每一行的初始坐标写到数组里
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    // 遍历CTRun找出图片所在的CTRun并进行绘制
    for (int i = 0; i < CFArrayGetCount(lines); i++)
    {
        // 遍历每一行CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        
        // 往lineAscent等数据里写值?
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int j = 0; j < CFArrayGetCount(runs); j++)
        {
            // 遍历每一个CTRun
            CGFloat runAscent;
            CGFloat runDescent;
            CGPoint lineOrigin = lineOrigins[i]; // 获取该行的初始坐标
            CTRunRef run = CFArrayGetValueAtIndex(runs, j); // 获取当前的CTRun
            NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
            CGRect runRect;
            runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
            
            // 这一段可参考Nimbus的NIAttributedLabel
            runRect = CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
            
            NSString *imageName = [attributes objectForKey:@"imageName"];
            
            if ([imageName isKindOfClass:[NSString class]])
            {
                // 绘制本地图片
                UIImage *image = [UIImage imageNamed:imageName];
                CGRect imageDrawRect;
                imageDrawRect.size = image.size;
                NSLog(@"%.2f",lineOrigin.x); // 该值是0,runRect已经计算过起始值
                imageDrawRect.origin.x = runRect.origin.x;// + lineOrigin.x;
                imageDrawRect.origin.y = lineOrigin.y;
                CGContextDrawImage(contextRef, imageDrawRect, image.CGImage);
                
                NSLog(@"本地图片啊啊啊");
            } else
            {
                
                imageName = nil;
                
                CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes objectForKey:(__bridge id)kCTRunDelegateAttributeName];
                if (!delegate)
                {
                    // 如果是非图片的CTRun则跳过
                    continue;
                }
                
                NSLog(@"网络图片啊啊啊");
                // 网络图片
                UIImage *image;
                
                if (!self.image)
                {
                    // 图片未下载完成，使用占位图片
                    image = [UIImage imageNamed:weicaiImageName];
                    
                    // 去下载图片
                    [self downLoadImageWithURL:[NSURL URLWithString:picURL]];
                    
                } else
                {
                    image = self.image;
                }
                
                // 绘制网络图片
                CGRect imageDrawRect;
                imageDrawRect.size = image.size;
                NSLog(@"%.2f",lineOrigin.x); // 该值是0,runRect已经计算过起始值
                imageDrawRect.origin.x = runRect.origin.x;// + lineOrigin.x;
                imageDrawRect.origin.y = lineOrigin.y;
                CGContextDrawImage(contextRef, imageDrawRect, image.CGImage);
                
            }
            
        }
    }
    
    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);
}

#pragma mark - 一行一行绘制，未调整行高
// 对应第三篇博文里的第一个例子
- (void)drawRectWithLineByLine
{
    // 1.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 2.设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    self.textHeight = [[self class] textHeightWithText:self.text width:CGRectGetWidth(self.bounds) font:self.font type:self.drawType];
    
    // 3.创建绘制区域，path的高度对绘制有直接影响，如果高度不够，则计算出来的CTLine的数量会少一行或者少多行
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight));
    
    // 4.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    
    // 获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.textHeight); // 此处用计算出来的高度
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 重置高度
    //    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight));
    
    // 一行一行绘制
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    
    // 把ctFrame里每一行的初始坐标写到数组里，注意CoreText的坐标是左下角为原点
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < lineCount; i++)
    {
        CGPoint point = lineOrigins[i];
        NSLog(@"point.y = %f",point.y);
    }
    
    
    NSLog(@"font.ascender = %f,descender = %f,lineHeight = %f,leading = %f",self.font.ascender,self.font.descender,self.font.lineHeight,self.font.leading);
    
    CGFloat frameY = 0;
    
    
    for (CFIndex i = 0; i < lineCount; i++)
    {
        // 遍历每一行CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        // 该函数除了会设置好ascent,descent,leading之外，还会返回这行的宽度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        NSLog(@"lineAscent = %f",lineAscent);
        NSLog(@"lineDescent = %f",lineDescent);
        NSLog(@"lineLeading = %f",lineLeading);
        
        
        CGPoint lineOrigin = lineOrigins[i];
        
        NSLog(@"i = %ld, lineOrigin = %@",i,NSStringFromCGPoint(lineOrigin));
        
        
        // 微调Y值，需要注意的是CoreText的Y值是在baseLine处，而不是下方的descent。
        // lineDescent为正数，self.font.descender为负数
        if (i > 0)
        {
            // 第二行之后需要计算
            frameY = frameY - kGlobalLineLeading - lineAscent;
            
            lineOrigin.y = frameY;
            
        } else
        {
            // 第一行可直接用
            frameY = lineOrigin.y;
        }
        
        
        NSLog(@"frameY = %f",frameY);
        
        // 调整坐标
        CGContextSetTextPosition(contextRef, lineOrigin.x, lineOrigin.y);
        CTLineDraw(line, contextRef);
        
        // 微调
        frameY = frameY - lineDescent;
        
        // 该方式与上述方式效果一样
//        frameY = frameY - lineDescent - self.font.descender;
    }
    
    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);
}

#pragma mark - 一行一行绘制，行高确定，行与行之间对齐
- (void)drawRectWithLineByLineAlignment
{
    // 1.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 2.设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    
    self.textHeight = [[self class] textHeightWithText:self.text width:CGRectGetWidth(self.bounds) font:self.font type:self.drawType];
    
    // 3.创建绘制区域，path的高度对绘制有直接影响，如果高度不够，则计算出来的CTLine的数量会少一行或者少多行
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight*2));
    
    // 4.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    
    // 获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.textHeight); // 此处用计算出来的高度
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 重置高度
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight));
    
    // 一行一行绘制
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    
    // 把ctFrame里每一行的初始坐标写到数组里，注意CoreText的坐标是左下角为原点
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < lineCount; i++)
    {
        CGPoint point = lineOrigins[i];
        NSLog(@"point.y = %f",point.y);
    }
    
    
    NSLog(@"font.ascender = %f,descender = %f,lineHeight = %f,leading = %f",self.font.ascender,self.font.descender,self.font.lineHeight,self.font.leading);
    
    CGFloat frameY = 0;
    
    NSLog(@"self.textHeight = %f,lineHeight = %f",self.textHeight,self.font.pointSize * kPerLineRatio);
    
    for (CFIndex i = 0; i < lineCount; i++)
    {
        // 遍历每一行CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        // 该函数除了会设置好ascent,descent,leading之外，还会返回这行的宽度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        NSLog(@"lineAscent = %f",lineAscent);
        NSLog(@"lineDescent = %f",lineDescent);
        NSLog(@"lineLeading = %f",lineLeading);
        
        
        CGPoint lineOrigin = lineOrigins[i];
        
        NSLog(@"i = %ld, lineOrigin = %@",i,NSStringFromCGPoint(lineOrigin));
        
        
        // 微调Y值，需要注意的是CoreText的Y值是在baseLine处，而不是下方的descent。
        
        CGFloat lineHeight = self.font.pointSize * kPerLineRatio;
        frameY = self.textHeight - (i + 1)*lineHeight - self.font.descender;
        
        
        NSLog(@"frameY = %f",frameY);
        
        lineOrigin.y = frameY;
        
        // 调整坐标
        CGContextSetTextPosition(contextRef, lineOrigin.x, lineOrigin.y);
        CTLineDraw(line, contextRef);

    }
    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);

}

#pragma mark - 一行一行绘制，行高确定，高度不够时加上省略号
- (void)drawRectWithLineByLineAlignmentAndEllipses
{
    // 1.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 2.设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    
    self.textHeight = [[self class] textHeightWithText:self.text width:CGRectGetWidth(self.bounds) font:self.font type:self.drawType];
    
    // 3.创建绘制区域，path的高度对绘制有直接影响，如果高度不够，则计算出来的CTLine的数量会少一行或者少多行
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight*2));
    
    // 4.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    // 重置高度
    CGFloat realHeight = self.textHeight;
    // 绘制全部文本需要的高度大于实际高度则调整，并加上省略号
    if (realHeight > CGRectGetHeight(self.frame))
    {
        realHeight = CGRectGetHeight(self.frame);
    }

    NSLog(@"realHeight = %f",realHeight);
    
    // 获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, realHeight); // 这里跟着调整
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 这里可调整可不调整
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), realHeight));
    
    // 一行一行绘制
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    
    // 把ctFrame里每一行的初始坐标写到数组里，注意CoreText的坐标是左下角为原点
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);

    
    CGFloat frameY = 0;
    
    
    for (CFIndex i = 0; i < lineCount; i++)
    {
        // 遍历每一行CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        // 该函数除了会设置好ascent,descent,leading之外，还会返回这行的宽度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);

        CGPoint lineOrigin = lineOrigins[i];
        
        // 微调Y值，需要注意的是CoreText的origin的Y值是在baseLine处，而不是下方的descent。
        CGFloat lineHeight = self.font.pointSize * kPerLineRatio;
        
        // 调节self.font.descender该值可改变文字排版的上下间距，此处下间距为0
        frameY = realHeight - (i + 1)*lineHeight - self.font.descender;
        
        NSLog(@"frameY = %f",frameY);
        
        lineOrigin.y = frameY;
        
        // 调整坐标
        CGContextSetTextPosition(contextRef, lineOrigin.x, lineOrigin.y);
        
        // 反转坐标系
        frameY = realHeight - frameY;
        
        NSLog(@"realHeight = %f,font.descender = %f",realHeight,self.font.descender);
        NSLog(@"反转后的坐标 y = %f",frameY);
        
        // 行高
        CGFloat heightPerLine = self.font.pointSize * kPerLineRatio;
        
        if (realHeight - frameY > heightPerLine)
        {
            CTLineDraw(line, contextRef);
            
            NSLog(@"一行一行的画 i = %ld",i);
            
        } else
        {
            NSLog(@"最后一行");
            
            // 最后一行，加上省略号
            static NSString* const kEllipsesCharacter = @"\u2026";
            
            CFRange lastLineRange = CTLineGetStringRange(line);
            
            // 一个emoji表情占用两个长度单位
            NSLog(@"range.location = %ld,range.length = %ld,总长度 = %ld",lastLineRange.location,lastLineRange.length,(unsigned long)attributed.length);
            
            if (lastLineRange.location + lastLineRange.length < (CFIndex)attributed.length)
            {
                // 这一行放不下所有的字符（下一行还有字符），则把此行后面的回车、空格符去掉后，再把最后一个字符替换成省略号
                
                CTLineTruncationType truncationType = kCTLineTruncationEnd;
                NSUInteger truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
                
                // 拿到最后一个字符的属性字典
                NSDictionary *tokenAttributes = [attributed attributesAtIndex:truncationAttributePosition
                                                                     effectiveRange:NULL];
                // 给省略号字符设置字体大小、颜色等属性
                NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:kEllipsesCharacter
                                                                                  attributes:tokenAttributes];
                
                // 用省略号单独创建一个CTLine，下面在截断重新生成CTLine的时候会用到
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
                
                // 把这一行的属性字符串复制一份，如果要把省略号放到中间或其他位置，只需指定复制的长度即可
                NSUInteger copyLength = lastLineRange.length/3;
                
                NSMutableAttributedString *truncationString = [[attributed attributedSubstringFromRange:NSMakeRange(lastLineRange.location, copyLength)] mutableCopy];
                
                if (lastLineRange.length > 0)
                {
                    // Remove any whitespace at the end of the line.
                    unichar lastCharacter = [[truncationString string] characterAtIndex:copyLength - 1];
                    
                    // 如果复制字符串的最后一个字符是换行、空格符，则删掉
                    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter])
                    {
                        [truncationString deleteCharactersInRange:NSMakeRange(copyLength - 1, 1)];
                    }
                }
                
                // 拼接省略号到复制字符串的最后
                [truncationString appendAttributedString:tokenString];
                
                // 把新的字符串创建成CTLine
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                
                // 创建一个截断的CTLine，该方法不能少，具体作用还有待研究
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, self.frame.size.width, truncationType, truncationToken);
                
                if (!truncatedLine)
                {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    truncatedLine = CFRetain(truncationToken);
                }
                
                CFRelease(truncationLine);
                CFRelease(truncationToken);
                
                CTLineDraw(truncatedLine, contextRef);
                CFRelease(truncatedLine);
                
            } else
            {
                
                // 这一行刚好是最后一行，且最后一行的字符可以完全绘制出来
                CTLineDraw(line, contextRef);
            }
            
            // 跳出循环，避免绘制剩下的多余的CTLine
            break;
            
        }
        
    }
    
    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);
}


#pragma mark - 加上监测点击
- (void)drawRectWithCheckClick
{
    // 1.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    // 2.1设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    // 2.2识别特定字符串并改变其颜色
    [self recognizeSpecialStringWithAttributed:attributed];
    
    // 2.3加一个点击改变字符串颜色的效果
    if (self.pressRange.location != 0 && self.pressRange.length != 0)
    {
        [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor yellowColor] range:self.pressRange];
    }
    
    self.textHeight = [[self class] textHeightWithText:self.text width:CGRectGetWidth(self.bounds) font:self.font type:self.drawType];
    
    // 3.创建绘制区域，path的高度对绘制有直接影响，如果高度不够，则计算出来的CTLine的数量会少一行或者少多行
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight*2));
    
    // 4.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    self.ctFrame = CFRetain(ctFrame);
    
    // 重置高度
    CGFloat realHeight = self.textHeight;
    // 绘制全部文本需要的高度大于实际高度则调整，并加上省略号
    if (realHeight > CGRectGetHeight(self.frame))
    {
        realHeight = CGRectGetHeight(self.frame);
    }
    
    // 获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, realHeight); // 这里跟着调整
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    // 这里可调整可不调整
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), realHeight));
    
    // 一行一行绘制
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    
    // 把ctFrame里每一行的初始坐标写到数组里，注意CoreText的坐标是左下角为原点
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    CGFloat frameY = 0;
    
    for (CFIndex i = 0; i < lineCount; i++)
    {
        // 遍历每一行CTLine
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        // 该函数除了会设置好ascent,descent,leading之外，还会返回这行的宽度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        CGPoint lineOrigin = lineOrigins[i];
        
        // 微调Y值，需要注意的是CoreText的origin的Y值是在baseLine处，而不是下方的descent。
        CGFloat lineHeight = self.font.pointSize * kPerLineRatio;
        
        // 调节self.font.descender该值可改变文字排版的上下间距，此处下间距为0
        frameY = realHeight - (i + 1)*lineHeight - self.font.descender;
        
        lineOrigin.y = frameY;
        
        // 调整坐标
        CGContextSetTextPosition(contextRef, lineOrigin.x, lineOrigin.y);
        
        // 反转坐标系
        frameY = realHeight - frameY;

        
        // 行高
        CGFloat heightPerLine = self.font.pointSize * kPerLineRatio;
        
        if (realHeight - frameY > heightPerLine)
        {
            CTLineDraw(line, contextRef);
            
        } else
        {
            
            // 最后一行，加上省略号
            static NSString* const kEllipsesCharacter = @"\u2026";
            
            CFRange lastLineRange = CTLineGetStringRange(line);
            
            if (lastLineRange.location + lastLineRange.length < (CFIndex)attributed.length)
            {
                // 这一行放不下所有的字符（下一行还有字符），则把此行后面的回车、空格符去掉后，再把最后一个字符替换成省略号
                
                CTLineTruncationType truncationType = kCTLineTruncationEnd;
                NSUInteger truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
                
                // 拿到最后一个字符的属性字典
                NSDictionary *tokenAttributes = [attributed attributesAtIndex:truncationAttributePosition
                                                               effectiveRange:NULL];
                // 给省略号字符设置字体大小、颜色等属性
                NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:kEllipsesCharacter
                                                                                  attributes:tokenAttributes];
                
                // 用省略号单独创建一个CTLine，下面在截断重新生成CTLine的时候会用到
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
                
                // 把这一行的属性字符串复制一份，如果要把省略号放到中间或其他位置，只需指定复制的长度即可
                NSUInteger copyLength = lastLineRange.length/3;
                
                NSMutableAttributedString *truncationString = [[attributed attributedSubstringFromRange:NSMakeRange(lastLineRange.location, copyLength)] mutableCopy];
                
                if (lastLineRange.length > 0)
                {
                    // Remove any whitespace at the end of the line.
                    unichar lastCharacter = [[truncationString string] characterAtIndex:copyLength - 1];
                    
                    // 如果复制字符串的最后一个字符是换行、空格符，则删掉
                    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter])
                    {
                        [truncationString deleteCharactersInRange:NSMakeRange(copyLength - 1, 1)];
                    }
                }
                
                // 拼接省略号到复制字符串的最后
                [truncationString appendAttributedString:tokenString];
                
                // 把新的字符串创建成CTLine
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                
                // 创建一个截断的CTLine，该方法不能少，具体作用还有待研究
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, self.frame.size.width, truncationType, truncationToken);
                
                if (!truncatedLine)
                {
                    // If the line is not as wide as the truncationToken, truncatedLine is NULL
                    truncatedLine = CFRetain(truncationToken);
                }
                
                CFRelease(truncationLine);
                CFRelease(truncationToken);
                
                CTLineDraw(truncatedLine, contextRef);
                CFRelease(truncatedLine);
                
            } else
            {
                
                // 这一行刚好是最后一行，且最后一行的字符可以完全绘制出来
                CTLineDraw(line, contextRef);
            }
            
            // 跳出循环，避免绘制剩下的多余的CTLine
            break;
            
        }
        
        
        
        
    }
    
    
    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);
}

#pragma mark - 下载图片的方法
- (void)downLoadImageWithURL:(NSURL *)url
{
    
    __weak typeof(self) weakSelf = self;
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        SDWebImageOptions options = SDWebImageRetryFailed | SDWebImageHandleCookies | SDWebImageContinueInBackground;
        options = SDWebImageRetryFailed | SDWebImageContinueInBackground;
        [[SDWebImageManager sharedManager] downloadImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            
            weakSelf.image = image;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (weakSelf.image)
                {
                    [self setNeedsDisplay];
                }
                
            });
            
            
        }];
        
    });
    
    
}


#pragma mark - 图片代理
void RunDelegateDeallocCallback(void *refCon)
{
    NSLog(@"RunDelegate dealloc");
}


CGFloat RunDelegateGetAscentCallback(void *refCon)
{

    NSString *imageName = (__bridge NSString *)refCon;
    
    if ([imageName isKindOfClass:[NSString class]])
    {
        // 对应本地图片
        return [UIImage imageNamed:imageName].size.height;
    }

    // 对应网络图片
    return [[(__bridge NSDictionary *)refCon objectForKey:@"height"] floatValue];
}


CGFloat RunDelegateGetDescentCallback(void *refCon)
{
    return 0;
}


CGFloat RunDelegateGetWidthCallback(void *refCon)
{
    
    NSString *imageName = (__bridge NSString *)refCon;
    
    if ([imageName isKindOfClass:[NSString class]])
    {
        // 本地图片
        return [UIImage imageNamed:imageName].size.width;
    }
    
    
    // 对应网络图片
    return [[(__bridge NSDictionary *)refCon objectForKey:@"width"] floatValue];
}

#pragma mark - 计算高度
+ (CGFloat)textHeightWithText:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont type:(HFDrawType)drawType
{
    if (drawType == HFDrawPureText)
    {
        return 400;
        
    } else if (drawType == HFDrawTextAndPicture)
    {
        return 400*3;
        
    } else if (drawType == HFDrawTextLineByLine)
    {
        return [self textHeightWithText3:aText width:aWidth font:aFont];
        
    } else if (drawType == HFDrawTextLineByLineAlignment)
    {
        return [self textHeightWithText2:aText width:aWidth font:aFont];
        
    } else if (drawType == HFDrawTextWithEllipses)
    {
        // 跟上方保持一致
        return [self textHeightWithText2:aText width:aWidth font:aFont];
        
    } else if (drawType == HFDrawTextWithCheckClick)
    {
        return [self textHeightWithText2:aText width:aWidth font:aFont];
    }
    
    return 0;
}

/**
 *  高度 = 每行的固定高度 * 行数
 */
+ (CGFloat)textHeightWithText2:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont
{
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:aText];
    
    // 给字符串设置字体行距等样式
    [self addGlobalAttributeWithContent:content font:aFont];
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)content);
    
    // 粗略的高度，该高度不准，仅供参考
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetterRef, CFRangeMake(0, content.length), NULL, CGSizeMake(aWidth, MAXFLOAT), NULL);
    
    NSLog(@"width = %f, suggestHeight = %f",aWidth,suggestSize.height);
    
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL, CGRectMake(0, 0, aWidth, suggestSize.height));
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, content.length), pathRef, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    NSLog(@"行数 = %ld",lineCount);
    
    
    // 总高度 = 行数*每行的高度，其中每行的高度为指定的值，不同字体大小不一样
    CGFloat accurateHeight = lineCount * (aFont.pointSize * kPerLineRatio);
    
    CGFloat height = accurateHeight;
    
    CFRelease(pathRef);
    CFRelease(frameRef);
    
    return height;
}


/**
 *  高度 = 每行的asent + 每行的descent + 行数*行间距
 *  行间距为指定的数值
 *  对应第三篇博文
 */
+ (CGFloat)textHeightWithText3:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont
{
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:aText];
    
    // 设置全局样式
    [self addGlobalAttributeWithContent:content font:aFont];
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)content);
    
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetterRef, CFRangeMake(0, aText.length), NULL, CGSizeMake(aWidth, MAXFLOAT), NULL);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, aWidth, suggestSize.height*10)); // 10这个数值是随便给的，主要是为了确保高度足够
    
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, aText.length), path, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CGFloat ascent = 0;
    CGFloat descent = 0;
    CGFloat leading = 0;
    
    CGFloat totalHeight = 0;
    
    NSLog(@"计算高度开始");
    for (CFIndex i = 0; i < lineCount; i++)
    {
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, i);
        
        CTLineGetTypographicBounds(lineRef, &ascent, &descent, &leading);
        
        NSLog(@"ascent = %f,descent = %f, leading = %f",ascent,descent,leading);
        
        totalHeight += ascent + descent;
        
    }
    
    leading = kGlobalLineLeading; // 行间距，
    
    totalHeight += (lineCount ) * leading;
    
    
    NSLog(@"totalHeight = %f",totalHeight);
    
    NSLog(@"高度计算完毕");
    
    return totalHeight;
}

#pragma mark - 工具方法
#pragma mark 给字符串添加全局属性，比如行距，字体大小，默认颜色
+ (void)addGlobalAttributeWithContent:(NSMutableAttributedString *)aContent font:(UIFont *)aFont
{
    CGFloat lineLeading = kGlobalLineLeading; // 行间距

    const CFIndex kNumberOfSettings = 2;
    
#warning 这几个属性有待研究
    
    CTParagraphStyleSetting lineBreakStyle;
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    lineBreakStyle.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakStyle.valueSize = sizeof(CTLineBreakMode);
    lineBreakStyle.value = &lineBreakMode;
    
    CTParagraphStyleSetting lineSpaceStyle;
    CTParagraphStyleSpecifier spec;
    spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
//    spec = kCTParagraphStyleSpecifierMaximumLineSpacing;
//    spec = kCTParagraphStyleSpecifierMinimumLineSpacing;
//    spec = kCTParagraphStyleSpecifierLineSpacing;
    
    lineSpaceStyle.spec = spec;
    lineSpaceStyle.valueSize = sizeof(CGFloat);
    lineSpaceStyle.value = &lineLeading;
    
    CTParagraphStyleSetting lineHeightStyle;
    lineHeightStyle.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
    lineHeightStyle.valueSize = sizeof(CGFloat);
    lineHeightStyle.value = &lineLeading;
    
    // 结构体数组
    CTParagraphStyleSetting theSettings[kNumberOfSettings] = {
        
        lineBreakStyle,
        lineSpaceStyle,
//        lineHeightStyle
    };
    
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, kNumberOfSettings);
    
    
    // 将设置的行距应用于整段文字
    [aContent addAttribute:NSParagraphStyleAttributeName value:(__bridge id)(theParagraphRef) range:NSMakeRange(0, aContent.length)];
    
    
    CFStringRef fontName = (__bridge CFStringRef)aFont.fontName;
    CTFontRef fontRef = CTFontCreateWithName(fontName, aFont.pointSize, NULL);
    
    // 将字体大小应用于整段文字
    [aContent addAttribute:NSFontAttributeName value:(__bridge id)fontRef range:NSMakeRange(0, aContent.length)];
    
    // 给整段文字添加默认颜色
    [aContent addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, aContent.length)];
    
    
    // 内存管理
    CFRelease(theParagraphRef);
    CFRelease(fontRef);
}

#pragma mark - 识别特定字符串并改其颜色，返回识别到的字符串所在的range
- (NSMutableArray *)recognizeSpecialStringWithAttributed:(NSMutableAttributedString *)attributed
{
    NSMutableArray *rangeArray = [NSMutableArray array];
    
    // 识别@人名
    NSRegularExpression *atRegular = [NSRegularExpression regularExpressionWithPattern:kAtRegularExpression options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *atResults = [atRegular matchesInString:self.text options:NSMatchingWithTransparentBounds range:NSMakeRange(0, self.text.length)];
    
    for (NSTextCheckingResult *checkResult in atResults)
    {
        if (attributed)
        {
            [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(checkResult.range.location, checkResult.range.length -1)];
        }
        
        [rangeArray addObject:[NSValue valueWithRange:checkResult.range]];
    }
    
    
    // 识别连续的数字
    NSRegularExpression *numberRegular = [NSRegularExpression regularExpressionWithPattern:kNumberRegularExpression options:NSRegularExpressionCaseInsensitive|NSRegularExpressionUseUnixLineSeparators error:nil];
    
    NSArray *numberResults = [numberRegular matchesInString:self.text options:NSMatchingWithTransparentBounds range:NSMakeRange(0, self.text.length)];
    
    for (NSTextCheckingResult *checkResult in numberResults)
    {
        if (attributed)
        {
            [attributed addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(checkResult.range.location, checkResult.range.length-1)];
        }
        
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(checkResult.range.location, checkResult.range.length -1)]];
    }
    
    
    return rangeArray;
}

#pragma mark - 工具方法，恢复最初状态
- (void)cancelColorAdded
{
    self.pressRange = NSMakeRange(0, 0);
    
    [self setNeedsDisplay];
}

#pragma mark - 手势识别相关
- (void)longPressed:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        
    } else if (gesture.state == UIGestureRecognizerStateChanged)
    {
    
    } else if (gesture.state == UIGestureRecognizerStateCancelled)
    {
    
    } else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        
        if (self.pressRange.location != 0 && self.pressRange.length != 0)
        {
            NSLog(@"识别到点击");
            
            NSString *clickStr = [self.text substringWithRange:self.pressRange];
            
            NSLog(@"点击了 %@",clickStr);
        }
        
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer == self.longPressGesture)
    {
        // 点击处在特定字符串内才进行识别
        BOOL gestureShouldBegin = NO;
        
        
        CGPoint location = [gestureRecognizer locationInView:self];
        
        CGFloat lineHeight = self.font.pointSize * kPerLineRatio;
        
        int lineIndex = location.y/lineHeight;
        
        NSLog(@"点击了第 %d 行",lineIndex);
        
        // 把点击的坐标转换为CoreText坐标系下
        CGPoint clickPoint = CGPointMake(location.x, self.textHeight-location.y);
        
        CFArrayRef lines = CTFrameGetLines(self.ctFrame);
        
        if (lineIndex < CFArrayGetCount(lines))
        {
            CTLineRef clickLine = CFArrayGetValueAtIndex(lines, lineIndex);
            
            // 点击处的字符位于总字符串的index
            CFIndex strIndex = CTLineGetStringIndexForPosition(clickLine, clickPoint);
            
            NSLog(@"strIndex = %ld",strIndex);
            
            NSMutableAttributedString *mutableAttributed = [[NSMutableAttributedString alloc] initWithString:self.text];
            NSArray *checkResults = [self recognizeSpecialStringWithAttributed:mutableAttributed];
            
            for (NSValue *value in checkResults)
            {
                NSRange range = [value rangeValue];
                
                if (strIndex >= range.location && strIndex <= range.location + range.length)
                {
                    self.pressRange = range;
                    gestureShouldBegin = YES;
                    NSLog(@"pressRange = %@",NSStringFromRange(range));
                    
                    // 改变字符串的颜色并进行重绘
//                    [self setNeedsDisplay];
                    
                    // 0.5秒后恢复颜色
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self cancelColorAdded];
//                    });
                }
                
            }
        }
        
        
        
        
        return gestureShouldBegin;
    }
    
    
    return YES;
}

// 该方法可实现也可不实现，取决于应用场景
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        return YES; // 避免应用在UITableViewCell上时，挡住拖动tableView的手势
    }
    
    return NO;
}



@end
