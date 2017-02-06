//  AttributedLabel.m
//
//  Created by 学无境－imac1 on 16/10/3.
//  Copyright © 2016年 学无境－imac1. All rights reserved.
//

#import "AttributedLabel.h"
#import "NSString+Japanese.h"
@import CoreText;

@interface AttributedLabel () {
    CGFloat normalWidth;
    CFAttributedStringRef stringForRuby;
    CGFloat overflowWidth;
}
@property (nonatomic,strong) NSString * compareString_m;
@property (nonatomic) AttributedLabelType type;
@property (nonatomic,strong) NSDictionary * furiganaRangeDic;
@end

@implementation AttributedLabel

// Note: TODO 潜在问题，删除update逻辑，发现暴露更多bug + 内存泄露检查; 包括 sizeFactor
-(void)update
{
    //Set up some default values.
    self.compareString_m = [[NSString alloc] init];
    overflowWidth = 0;
    normalWidth = 0;
    stringForRuby = NULL;
    if (stringForRuby) {
        CFRelease(stringForRuby);
    }
    _needToTransform = NO;
    self.autoresizingMask = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.replace_range = NSMakeRange(0,0);
    self.sizeFactor = 0.5;
    self.showReplaceTextUnderLine = NO;
    self.showErrorCross = NO;
    self.font = [UIFont fontWithName:@"HiraginoSans-W3" size:self.font.pointSize];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self == [super initWithCoder:aDecoder]) {
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)setRubyAnnotationWithCompareString:(NSString *)compareString highlightedString:(NSString *)highlightedString highlightedColor:(UIColor *)color type:(AttributedLabelType)labelType
{
    self.type = labelType;
    [self setRubyAnnotationWithCompareString:compareString];
    [self setHighlightedStringWithString:highlightedString highlightedColor:color];
    [self setNeedsDisplay];
}

- (void) setRubyAnnotationWithCompareString:(NSString *)compareString
{
    [self update];

    if (compareString==nil) {
        self.text = nil;
        return;
    }
    if ([compareString isEqualToString:@""]) {
        self.text = nil;
        return;
    }

    _needToTransform = YES;
    self.text = [compareString defaultString];
    self.compareString_m = compareString;

    [self creatRubyAttributedStringWithCompareString:compareString];
}

- (void) creatRubyAttributedStringWithCompareString:(NSString*)compareString
{
    NSDictionary * hiraganaDict = [self.text hiraganaReplacementsForStringWithCompareString:compareString];
//    if (hiraganaDict == nil) {
//        self.needToTransform = NO;
//        return;
//    }
    self.furiganaRangeDic = hiraganaDict;
    CFAttributedStringRef string = (__bridge CFAttributedStringRef)self.attributedText;

    if (stringForRuby) {
        CFRelease(stringForRuby);
    }
     stringForRuby = [self createRubyAttributedString:string furiganaRanges:hiraganaDict];
}

- (CFAttributedStringRef)createRubyAttributedString:(CFAttributedStringRef)string furiganaRanges:(NSDictionary*)furiganaDic
{
    CFMutableAttributedStringRef stringMutable=CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(string), string);
    CFAttributedStringBeginEditing(stringMutable);
    //TODO:Add version control
    for (NSValue *value in furiganaDic.keyEnumerator) {
        NSRange range=value.rangeValue;
        NSString * furiganaStr=[furiganaDic objectForKey:value];

        CFStringRef furigana[kCTRubyPositionCount] = {(__bridge CFStringRef)furiganaStr,NULL,NULL,NULL};
        CTRubyAnnotationRef  rubyRef = CTRubyAnnotationCreate(kCTRubyAlignmentAuto, kCTRubyOverhangAuto, self.sizeFactor, furigana);
        CFRange r=CFRangeMake(range.location, range.length);
        CFAttributedStringSetAttribute(stringMutable, r, kCTRubyAnnotationAttributeName, rubyRef);
        CFRelease(rubyRef);

        [self caculateOverflowWidthWithTextRange:range furigana:furiganaStr];
    }
    CFAttributedStringEndEditing(stringMutable);
    CFAttributedStringRef rubyString=CFAttributedStringCreateCopy(NULL, stringMutable);
    CFRelease(stringMutable);

    return rubyString;
}

- (void)setHighlightedStringWithString:(NSString*) highlightedString highlightedColor:(UIColor*)color
{
    if (!stringForRuby) {
        return;
    }
    NSRange range;

    if (highlightedString == nil  || [highlightedString isEqualToString:@""]) {
        return;
    }else{
        if ([self.text containsString:highlightedString]) {
            range = [self getRightHighlightedStringRange:[self.text rangeOfString:highlightedString]];
        }else{
            NSLog(@"Error:Highlighted string not found!  --  text is :%@  highlighted string is:%@",self.text,highlightedString);
            return;
        }
    }
    [self setRubyStringColorWithColor:color.CGColor andRange:CFRangeMake(range.location, range.length)];
}

- (void) setRubyStringColorWithColor:(CGColorRef) color andRange:(CFRange) range
{
    if (range.length == NSNotFound || range.location == NSNotFound) {
        return;
    }
    if (!stringForRuby) {
        return;
    }

    CFMutableAttributedStringRef stringMutable=CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(stringForRuby), stringForRuby);
    CFAttributedStringBeginEditing(stringMutable);
    if (color) {
        CFAttributedStringSetAttribute(stringMutable, CFRangeMake(range.location, range.length), kCTForegroundColorAttributeName, color);
        CFAttributedStringSetAttribute(stringMutable, CFRangeMake(0, range.location), kCTForegroundColorAttributeName, self.textColor.CGColor);
        CFAttributedStringSetAttribute(stringMutable, CFRangeMake(range.location + range.length, self.text.length - range.location - range.length), kCTForegroundColorAttributeName, self.textColor.CGColor);
    }
    CFRelease(stringForRuby);
    stringForRuby= CFAttributedStringCreateCopy(NULL, stringMutable);
    CFAttributedStringEndEditing(stringMutable);
    CFRelease(stringMutable);
}


- (void) setReplaceTextForLabelWithReplaceText:(NSString*) replaceText replaceRange:(NSRange) range
{
    if (self.text == nil || [self.text isEqualToString:@""]) return;
    if (replaceText == nil || [replaceText isEqualToString:@""]) return;
    if (range.location == NSNotFound) return;


    CFMutableAttributedStringRef stringMutable=CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(stringForRuby), stringForRuby);
    CFAttributedStringBeginEditing(stringMutable);

    //正确的时候直接在原字符串上的指定范围加上一条下划线。
    if (self.replaceText) {
        if (self.showReplaceTextUnderLine) {
            CFRange r = CFRangeMake(range.location, range.length);
            NSDictionary * dict = @{(id)kCTUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)};
            CFDictionaryRef attributeDic = (__bridge CFDictionaryRef)(dict);
            CFAttributedStringSetAttributes(stringMutable, r, attributeDic, NO);
            //同步text与stringForRuby
            NSMutableAttributedString * attributedStr = (__bridge NSMutableAttributedString *)(stringMutable);
            self.text = attributedStr.string;

            CFRelease(stringForRuby);
            stringForRuby = CFAttributedStringCreateCopy(NULL, stringMutable);
            CFAttributedStringEndEditing(stringMutable);
            CFRelease(stringMutable);
            self.replaceText = replaceText;
            [self setNeedsDisplay];
            return;
        }
    }

    NSDictionary * attributeDict = @{(id)kCTForegroundColorAttributeName:(id)self.textColor.CGColor,NSFontAttributeName:self.font,(id)kCTUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)};
    //属性字符串替换
    CFAttributedStringReplaceAttributedString(stringMutable, CFRangeMake(range.location, range.length),CFAttributedStringCreate(NULL, (__bridge CFStringRef)replaceText,(__bridge CFDictionaryRef)attributeDict));

    CFRelease(stringForRuby);
    stringForRuby = CFAttributedStringCreateCopy(NULL, stringMutable);

    //同步text与stringForRuby
    NSMutableAttributedString * attributedStr = (__bridge NSMutableAttributedString *)(stringForRuby);
    self.text = attributedStr.string;
    self.attributedText = attributedStr;

    CFAttributedStringEndEditing(stringMutable);
    CFRelease(stringMutable);
    self.replaceText = replaceText;
    [self setNeedsDisplay];
}

- (void) addErrorLineForReplaceText
{
    NSString * labelText = self.text;
    if ([labelText containsString:self.replaceText]) {
        NSRange range = [labelText rangeOfString:self.replaceText];
        CFMutableAttributedStringRef stringMutable=CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(stringForRuby), stringForRuby);
        CFAttributedStringBeginEditing(stringMutable);
        NSDictionary * attributeDict = @{(id)kCTForegroundColorAttributeName:(id)self.textColor.CGColor, NSFontAttributeName:self.font, (id)kCTStrokeWidthAttributeName:@(NSUnderlineStyleSingle)};
        CFAttributedStringReplaceAttributedString(stringMutable, CFRangeMake(range.location, range.length),CFAttributedStringCreate(NULL, (__bridge CFStringRef)_replaceText,(__bridge CFDictionaryRef)attributeDict));
        CFRelease(stringForRuby);
        stringForRuby = CFAttributedStringCreateCopy(NULL, stringMutable);
        CFAttributedStringEndEditing(stringMutable);
        CFRelease(stringMutable);
    }
}

- (NSRange) getRightHighlightedStringRange:(NSRange) range
{
    NSRange rightRange_highlighted = NSMakeRange(0, 0);
    BOOL findErrorRange = NO;
    //如果设置高亮的单词的范围 ！= 假名标注的范围，高亮范围变为假名标注的范围。
    for (NSValue * rangeValue in self.furiganaRangeDic.allKeys) {
        if ( NSLocationInRange(range.location, rangeValue.rangeValue) ) {
            if (range.location != rangeValue.rangeValue.location || range.location + range.length <  rangeValue.rangeValue.location + rangeValue.rangeValue.length) {
                findErrorRange = YES;
                rightRange_highlighted = NSMakeRange(rangeValue.rangeValue.location, rangeValue.rangeValue.length);
                break;
            }
        }else if (NSLocationInRange(range.location + range.length, rangeValue.rangeValue)){
            //一般情况下不会发生
            findErrorRange = YES;
            rightRange_highlighted = NSMakeRange(range.location, rangeValue.rangeValue.location - range.location);
        }
    }
    if (findErrorRange) {
        return rightRange_highlighted;
    }else{
        return range;
    }
}

- (CGFloat)sizeFactor
{
    if (_sizeFactor == 0){
        //default value for size factor
        return 0.5;
    }
    return _sizeFactor;
}

- (CGSize)intrinsicContentSize
{
    CGSize textSize = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];
    CGSize size =  [super intrinsicContentSize];
    if (!_needToTransform) {
        return size;
    }

    CFRange fitrange;
    CGSize newSize;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(stringForRuby);
    CGSize constraints=CGSizeMake(self.preferredMaxLayoutWidth, CGFLOAT_MAX);
    newSize=CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, CFAttributedStringGetLength(stringForRuby)), NULL, constraints, &fitrange);
    CFRelease(framesetter);
    CGSize integerSize=CGSizeMake(ceil(newSize.width), ceil(newSize.height));
    return integerSize;
    // Note: 同样的数据下，食堂 iOS 10 比 iOS 9 高度+3
    // 引っ越しを手伝わなくてもいいですか。 结尾换行计算，高度是由问题的
}

#pragma mark - Caculate width and height
-(void) caculateOverflowWidthWithTextRange:(NSRange) textRange furigana:(NSString*) furigana
{
    NSString * text = [self.text substringWithRange:textRange];
    CGFloat textWidth =[text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.font.pointSize]}].width;
    CGFloat furiganaWidth = [furigana sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.font.pointSize * self.sizeFactor]}].width;
    if (furiganaWidth > textWidth) {
        overflowWidth +=(furiganaWidth - textWidth);
    }
}

- (CGFloat)caculateFuriganaHeight
{
    CGFloat defaultHeight = 0.f;
    CGFloat singleLineHeight = 27.f;
    CGFloat furiganaHeight = 0.f;
    if (self.font.pointSize>11 && self.font.pointSize<20) {
        defaultHeight = self.font.pointSize + 3;
    }
    furiganaHeight = singleLineHeight - defaultHeight;
    return furiganaHeight;
}

- (CGFloat) caculateHeightWithWidth:(CGFloat) width
{
    if (!stringForRuby) {
        return 0;
    }
    int total_height = 0;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(stringForRuby);
    CGRect drawingRect = CGRectMake(0, 0, width,1000);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);

    NSArray *linesArray =  (NSArray *) CTFrameGetLines(textFrame);
    CGPoint origins[[linesArray count]];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);


    int line_y = (int) origins[[linesArray count] -1].y;
    CGFloat ascent;//baseLine到最顶端
    CGFloat descent;//baseline到最低端
    CGFloat leading;//行间距
    CTLineRef line = (__bridge CTLineRef) [linesArray objectAtIndex:[linesArray count]-1];
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    total_height = 1000 - line_y + (int) descent +1;

    CFRelease(textFrame);

    return total_height;
}

- (BOOL) haveAnnotationInFirstLine
{
    if (!_needToTransform) {
        return NO;
    }
    NSArray * linesArray = [self getAllTextLines];

    if (0<linesArray.count) {
        CTLineRef line = (__bridge CTLineRef)linesArray[0] ;
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        for (int j = 0; j<CFArrayGetCount(runs); j++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            CFDictionaryRef attributes = CTRunGetAttributes(run);
            NSString * ns_key = @"CTRubyAnnotation";
            const CFStringRef key = (__bridge CFStringRef)(ns_key);
            CFDictionaryGetValue(attributes, key);
            if (CFDictionaryGetValue(attributes, key)) {
                return YES;
            }
        }
    }
    return NO;
}

-(NSArray*) getAllTextLines
{
    CGFloat width = self.intrinsicContentSize.width;

    CFMutableAttributedStringRef stringMutable = CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(stringForRuby), stringForRuby);
    CFAttributedStringRef rubyString = stringMutable;

    CTFramesetterRef frameSetter=CTFramesetterCreateWithAttributedString(rubyString);
    CGRect drawingRect = CGRectMake(0, 0, width, 1000);  //这里的高要设置足够大
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), path, NULL);
    CGPathRelease(path);
    CFRelease(frameSetter);
    CFRelease(stringMutable);

    NSArray *linesArray =  (NSArray *) CTFrameGetLines(frame);
    CFRelease(frame);
    return linesArray;
}

-(void)drawRect:(CGRect)rect
{
    if (_needToTransform) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
        CGContextTranslateCTM(ctx, 0, ([self bounds]).size.height +0 );
        CGContextScaleCTM(ctx, 1.0, -1.0);

        //seems a lot easier to use a framesetter than manual linebreaks

        CFMutableAttributedStringRef stringMutable = CFAttributedStringCreateMutableCopy(NULL, CFAttributedStringGetLength(stringForRuby), stringForRuby);
        CFAttributedStringRef rubyString = stringMutable;

        CTFramesetterRef frameSetter=CTFramesetterCreateWithAttributedString(rubyString);
        CGPathRef path = CGPathCreateWithRect(self.bounds, NULL);
        CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, CFAttributedStringGetLength(rubyString)), path, NULL);
        CTFrameDraw(frame, context);
        CFRelease(frame);
        CFRelease(path);
        CFRelease(frameSetter);
        CFRelease(stringMutable);

        if( self.showErrorCross ){
            CGContextSetLineWidth(context, 1);
            CGContextSetStrokeColorWithColor(context, self.textColor.CGColor);

            CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y);
            CGContextAddLineToPoint(context, self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y + self.bounds.size.height );

            CGContextMoveToPoint(context, self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y);
            CGContextAddLineToPoint(context, self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height );

            CGContextStrokePath(context);
        }
    }else{
        [super drawRect:rect];
    }
}

@end
