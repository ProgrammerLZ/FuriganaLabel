//
//  AttributedLabel.h
//
//  Created by 学无境－imac1 on 16/10/3.
//  Copyright © 2016年 学无境－imac1. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,AttributedLabelType)
{
    kWordAttributedLabel = 0,
    kSentenceAttributedLabel
};
@interface AttributedLabel : UILabel
@property (nonatomic) BOOL needToTransform;
@property (nonatomic) CGFloat sizeFactor;
@property (nonatomic) NSRange replace_range;
@property (nonatomic) BOOL showReplaceTextUnderLine;
@property (nonatomic) BOOL isWord;
@property (nonatomic) BOOL showErrorCross;
@property(nonatomic,strong) NSString * replaceText;

-(void) update;

- (CGFloat) caculateFuriganaHeight;

- (BOOL) haveAnnotationInFirstLine;

- (void) setRubyAnnotationWithCompareString:(NSString *)compareString highlightedString:(NSString*)highlightedString highlightedColor:(UIColor*)color type:(AttributedLabelType) labelType;

- (void)setHighlightedStringWithString:(NSString*) highlightedString highlightedColor:(UIColor*)color;

- (void) setRubyAnnotationWithCompareString:(NSString *)compareString;

- (void) setReplaceTextForLabelWithReplaceText:(NSString*) replaceText replaceRange:(NSRange) range;

- (void) addErrorLineForReplaceText;
@end
