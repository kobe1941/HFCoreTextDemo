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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *content = @"这是我的第一个coreText demo,This is my first CoreText demo,how are you ?去年今日此门中，人面桃花相映红。人面不知何处去，桃花依旧笑春风。少年不知愁滋味，更上层楼，更上层楼，为赋新词强说愁。而今识尽愁滋味，欲说还休，欲说还休，却道天凉好个秋。";
   
    self.coreTextView.backgroundColor = [UIColor grayColor];
    
    self.coreTextView.text = content;
   
    // 对应第二篇博文
//    self.contentViewHeightConstraint.constant = 400*3;
    
    // 对应第三篇博文
    self.contentViewHeightConstraint.constant = [HFCoreTextView textHeightWithText:content width:CGRectGetWidth(self.coreTextView.frame) font:self.coreTextView.font];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
