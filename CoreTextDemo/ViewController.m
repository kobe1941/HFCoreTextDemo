//
//  ViewController.m
//  CoreTextDemo
//
//  Created by hufeng on 15/5/7.
//  Copyright (c) 2015年 hufeng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.contentViewHeightConstraint.constant = 400*3;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
