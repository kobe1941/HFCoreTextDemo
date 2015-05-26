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
const CGFloat globalLineLeading = 5.0;

@interface HFCoreTextView ()

@property (nonatomic, strong) UIImage *image;


@property (nonatomic, assign) CGFloat textHeight;
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
//    self.font = [UIFont systemFontOfSize:15];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

//    [self drawRectWithPictureAndContent];
//    return;

    // 4.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    // 设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    

    self.textHeight = [[self class] textHeightWithText3:self.text width:CGRectGetWidth(self.bounds) font:self.font];
    
    // 3.创建绘制区域，path的高度对绘制有直接影响，如果高度不够，则计算出来的CTLine的数量会少一行或者多行，所以这里先乘以2，下边再一行一行的画
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, CGRectGetWidth(self.bounds), self.textHeight));
    
    // 5.根据NSAttributedString生成CTFramesetterRef
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
    
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, NULL);
    
    // 6.绘制
//    CTFrameDraw(ctFrame, contextRef);

    // 1.获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // 2.转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.textHeight); // 此处用计算出来的高度
    CGContextScaleCTM(contextRef, 1.0, -1.0);

    // 重置高度，呵呵，上面高度乘以2是为了准确生成CTLine
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
    
    // 距离左上角的高度
    CGFloat tempHeight = 0;
    
//    self.font.ascender;
//    self.font.descender;
//    self.font.leading;
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
        
//        tempHeight += lineAscent + lineDescent;
//        lineOrigin.y = self.textHeight - tempHeight;
//        tempHeight += globalLineLeading;
        
        
        
        // 微调Y值，需要注意的是CoreText的Y值是在baseLine处，而不是下方的descent。
        // lineDescent为正数，self.font.descender为负数
        
//        if (frameY == 0)
//        {
//            lineOrigin.y = lineOrigin.y + lineDescent + self.font.descender;
//            
//            frameY = lineOrigin.y;
//            
//        } else
        if (i > 0)
        {
            // 第二行之后需要计算
            frameY = frameY - globalLineLeading - lineAscent;
            
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
            
//            NSLog(@"runAscent = %f",runAscent);
//            NSLog(@"runDescent = %f",runDescent);
//            NSLog(@"lineOrigin.y = %f",lineOrigin.y);
            
            NSString *imageName = [attributes objectForKey:@"imageName"];
            
            
            
        }
    }
  

    
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(ctFrame);

}

#pragma mark - 图文混排
// 对应第二篇博文
- (void)drawRectWithPictureAndContent
{
    // 1.获取上下文
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // [a,b,c,d,tx,ty]
    NSLog(@"转换前的坐标：%@",NSStringFromCGAffineTransform(CGContextGetCTM(contextRef)));
    
    // 2.转换坐标系
    CGContextSetTextMatrix(contextRef, CGAffineTransformIdentity);
    CGContextTranslateCTM(contextRef, 0, self.bounds.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    NSLog(@"转换后的坐标：%@",NSStringFromCGAffineTransform(CGContextGetCTM(contextRef)));
    
    
    // 3.创建绘制区域，可以对path进行个性化裁剪以改变显示区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    
    
    // 4.创建需要绘制的文字
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:self.text];
    
    
    // 设置行距等样式
    [[self class] addGlobalAttributeWithContent:attributed font:self.font];
    
    
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
+ (CGFloat)textHeightWithText:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont
{
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:aText];
    
    // 给字符串设置字体行距等样式
    [self addGlobalAttributeWithContent:content font:aFont];
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)content);
    
    // 粗略的高度，该高度不准，仅供参考
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetterRef, CFRangeMake(0, content.length), NULL, CGSizeMake(aWidth, MAXFLOAT), NULL);
    
    NSLog(@"suggestHeight = %f",suggestSize.height);
    
//    return suggestSize.height;
    
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL, CGRectMake(0, 0, aWidth, suggestSize.height));
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, content.length), pathRef, NULL);
    
    
    CGPathRef path = CTFrameGetPath(frameRef);
    CGRect testRect1 = CGPathGetBoundingBox(path);
    CGRect testRect2 = CGPathGetPathBoundingBox(path);
    
    NSLog(@"testRect1 = %@",NSStringFromCGRect(testRect1));
    NSLog(@"testRect2 = %@",NSStringFromCGRect(testRect2));
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CGPoint lineOrigins[lineCount];
    
    
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), lineOrigins);
    
    NSLog(@"after");
    for (int i = 0; i < lineCount; i++)
    {
        CGPoint origin = lineOrigins[i];
        NSLog(@"i = %d,origin = %@",i,NSStringFromCGPoint(origin));
    }
  

//    NSLog(@"aFont.ascender = %f",aFont.ascender);
//    NSLog(@"aFont.descender = %f",aFont.descender);
//    NSLog(@"aFont.leading = %f",aFont.leading);
//    NSLog(@"aFont.lineHeight = %f",aFont.lineHeight);
    
#warning 高度的计算方式需要重构
    
    CGFloat accurateHeight = lineCount * 18; // 行数*每行的高度，18是随意给的
    
    CGFloat height = suggestSize.height;
    
    CFRelease(pathRef);
    CFRelease(frameRef);
    
    return height;
    
//    return accurateHeight;
}

#pragma 这个跟第一个方法的数值一样，不准
+ (CGFloat)textHeightWithText2:(NSString *)aText width:(CGFloat)aWidth font:(UIFont *)aFont
{
    CFRange textRange = CFRangeMake(0, aText.length);
    
    //  Create an empty mutable string big enough to hold our test
    CFMutableAttributedStringRef string = CFAttributedStringCreateMutable(kCFAllocatorDefault, aText.length);
    
    //  Inject our text into it
    CFAttributedStringReplaceString(string, CFRangeMake(0, 0), (CFStringRef)aText);

    
    [[self class] addGlobalAttributeWithContent:(__bridge id)string font:aFont];
    
//    CFAttributedStringSetAttribute(string, textRange, kCTParagraphStyleAttributeName, paragraphStyle);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(string);
    CFRange fitRange;
    
    CGFloat testHeight = MAXFLOAT;
//    testHeight = 10000;
    
    CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, textRange, NULL, CGSizeMake(aWidth, testHeight), &fitRange);
    
    CFRelease(framesetter);
    CFRelease(string);
    
    NSLog(@"newHeight = %f",frameSize.height);
    
    return frameSize.height;
}

/**
 *  高度 = 每行的asent + 每行的descent + (行数 -1)*行距
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
    
    leading = globalLineLeading; // 行间距，
    
    totalHeight += (lineCount ) * leading;
    
    
    NSLog(@"totalHeight = %f",totalHeight);
    
    NSLog(@"高度计算完毕");
    
    return totalHeight;
}

#pragma mark - 工具方法
#pragma mark 给字符串添加全局属性，比如行距，字体大小，默认颜色
+ (void)addGlobalAttributeWithContent:(NSMutableAttributedString *)aContent font:(UIFont *)aFont
{
    CGFloat lineLeading = globalLineLeading; // 行间距

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
    
    // test
//    CGFloat leading = aFont.lineHeight - aFont.ascender + aFont.descender;
//    CTParagraphStyleSetting paragraphSettings[1] = { kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof (CGFloat), &leading };
//    theParagraphRef = CTParagraphStyleCreate(paragraphSettings, 1);
    
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
@end
