//
//  ViewController.m
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import "ViewController.h"
#import "HFCoreTextView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet HFCoreTextView *coreTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *content = @"我自横刀向天笑，去留肝胆两昆仑。--谭嗣同同学你好啊。This is my first CoreText demo,how are you ?I love three things,the sun,the moon,and you.the sun for the day,the moon for the night,and you forever.😳😊😳😊😳😊😳去年今日此门中，人面桃花相映红。人面不知何处去，桃花依旧笑春风。😳😊😳😊😳😊😳少年不知愁滋味，爱上层楼，爱上层楼，为赋新词强说愁。56321363464.而今识尽愁滋味，欲说还休，欲说还休，却道天凉好个秋。123456，@习大大 ，56321267895434。缺月挂疏桐，漏断人初静。谁见幽人独往来，缥缈孤鸿影。惊起却回头，有恨无人省。捡尽寒枝不肯栖，寂寞沙洲冷。";
   
    self.coreTextView.backgroundColor = [UIColor grayColor];
    self.coreTextView.font = [UIFont systemFontOfSize:15];
    self.coreTextView.text = content;
    
    // 设置该值即可切换
    self.coreTextView.drawType = HFDrawTextWithCheckClick;
    
    // 此时self.coreTextView的宽度为320，为了在iPhone6上计算准确，使用屏幕宽度
    CGFloat realWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat height = [HFCoreTextView textHeightWithText:content width:realWidth font:self.coreTextView.font type:self.coreTextView.drawType];

    // 在这里控制显示的行数
    CGFloat maxHeight = (self.coreTextView.font.pointSize*kPerLineRatio)*6;
    
    if (height > maxHeight && self.coreTextView.drawType == HFDrawTextWithEllipses)
    {
        height = maxHeight;
    }
    
    NSLog(@"height = %f",height);
    
    self.contentViewHeightConstraint.constant = height;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
