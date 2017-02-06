//
//  ViewController.m
//  FuriganaLabelDemo
//
//  Created by 刘哲 on 2017/2/6.
//  Copyright © 2017年 刘哲. All rights reserved.
//

#import "ViewController.h"
#import "AttributedLabel.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet AttributedLabel *furiganaLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* str = @"{正文;标注}";
    [self.furiganaLabel setRubyAnnotationWithCompareString:str
                                         highlightedString:@"正文"
                                          highlightedColor:[UIColor orangeColor] type:0];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
