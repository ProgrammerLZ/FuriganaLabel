
#import "NSString+Japanese.h"

@implementation NSString (NSString_Japanese)
 // TODO: 分割前未存在安全性检验，正则检验之后操作
- (NSString*) defaultString
{
    //转换成正常的string
    NSString * defaultString = @"";
    NSArray * components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    if (components.count == 0) {
        return self;
    }
    for (int i = 0; i < components.count; i++) {
        NSString * subString = components[i];
        if(subString!= nil ||![subString isEqualToString:@""]){
            if ([subString containsString:@";"]) {
                NSArray * seperateArray = [subString componentsSeparatedByString:@";"];
                NSString * appendString = seperateArray[0];
                defaultString = [defaultString stringByAppendingString:appendString];
            }else{
                defaultString = [defaultString stringByAppendingString:subString];
            }
        }
    }
    return  defaultString;
}

-(NSDictionary*)hiraganaReplacementsForStringWithCompareString:(NSString *)compareString
{
    
    NSString * str1 = [self defaultString];
    __block NSRange startRange;
    startRange.length = 0;
    __block NSRange endRange;
    endRange.length = 0;
    __block NSRange lastRange = NSMakeRange(0, 0);
    __block NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    
    //TODO:正则表达式
    if (![compareString containsString:@"{"]) {
        return nil;
    }
    if (![compareString containsString:@"}"]) {
        return nil;
    }
    
    [compareString enumerateSubstringsInRange:NSMakeRange(0, compareString.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if ([substring isEqualToString:@"{"] ) {
            startRange = NSMakeRange(substringRange.location, substringRange.length);
        }
        if ([substring isEqualToString:@"}"]) {
            endRange = NSMakeRange(substringRange.location, substringRange.length);
        }
        if (startRange.length != 0 && endRange.length != 0 && startRange.location < endRange.location) {
            NSString * newString = [compareString substringWithRange:NSMakeRange(startRange.location+1 , endRange.location - startRange.location-1)];
            
            NSArray * seperateArr = [newString componentsSeparatedByString:@";"];
            __block NSString * stringToTransform = seperateArr[0];
            __block NSString * furiganaStr = seperateArr[1];
            
            __block NSString * specialCharacterStr = @"";
            __block NSString * specialCharacter = @"";
            [stringToTransform enumerateSubstringsInRange:NSMakeRange(0, stringToTransform.length)
                                                  options:NSStringEnumerationByComposedCharacterSequences
                                               usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                                                   
                                                   __block NSString * temSubStr = substring;
                                                   [furiganaStr enumerateSubstringsInRange:NSMakeRange(0, furiganaStr.length)
                                                                                   options:NSStringEnumerationByComposedCharacterSequences
                                                                                usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                                                                                    if ([substring isEqualToString:temSubStr]) {
                                                                                        if ([specialCharacterStr containsString:temSubStr]) {
                                                                                            specialCharacter= [specialCharacter stringByAppendingString:temSubStr];//收集影响切割的字符,把他们从切割的阵营当中剔除，第二轮再进行特殊处理。
                                                                                        }else{
                                                                                            specialCharacterStr = [specialCharacterStr stringByAppendingString:temSubStr];
                                                   }
                                                                                    }
                                                   }];
                                               }];
            
            specialCharacterStr =  [specialCharacterStr stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:specialCharacter]];
            
            //如果有相同的字符，进行切割处理
            if (specialCharacterStr.length != 0 || specialCharacter.length != 0) {
                NSCharacterSet * specialCharacters = [[NSCharacterSet alloc] init];
                NSMutableArray * stringToTransform_splited = [NSMutableArray array];
                NSMutableArray * furiganaString_splited = [NSMutableArray array];
                
                //两个字符串共有的字符集合
                if ([stringToTransform containsString:specialCharacterStr]) {
                    stringToTransform_splited = [[stringToTransform componentsSeparatedByString:specialCharacterStr] mutableCopy];
                    furiganaString_splited = [[furiganaStr componentsSeparatedByString:specialCharacterStr] mutableCopy];
                }else{
                    specialCharacters = [NSCharacterSet characterSetWithCharactersInString:specialCharacterStr];
                    stringToTransform_splited = [[stringToTransform componentsSeparatedByCharactersInSet:specialCharacters] mutableCopy];
                    furiganaString_splited = [[furiganaStr componentsSeparatedByCharactersInSet:specialCharacters] mutableCopy];
                }
                
                NSInteger totalLength = 0;
                for (int i = 0; i<stringToTransform_splited.count; i++) {
                    NSString * stringToTransform_real = stringToTransform_splited[i];
                    NSString * furiganaStr_real = furiganaString_splited[i];
                    
                    //特殊处理：暂时只处理开头和结尾的情况
                    if (specialCharacter.length > 0) {
                        for (int i = 0 ; i < specialCharacter.length ; i++) {
                            NSString * subStr = [specialCharacter substringWithRange:NSMakeRange(i, 1)];
                            
                            if ([stringToTransform_real hasPrefix:subStr] && [furiganaStr_real hasPrefix:subStr]) {
                                stringToTransform_real = [stringToTransform_real substringWithRange:NSMakeRange(1, stringToTransform_real.length - 1)];
                                furiganaStr_real = [furiganaStr_real substringWithRange:NSMakeRange(1, furiganaStr_real.length - 1)];
                                
                            }else if( [stringToTransform_real hasSuffix:subStr] && [furiganaStr_real hasSuffix:subStr] ){
                                stringToTransform_real = [stringToTransform_real substringWithRange:NSMakeRange(0, stringToTransform_real.length - 1)];
                                furiganaStr_real = [furiganaStr_real substringWithRange:NSMakeRange(0, furiganaStr_real.length - 1)];
                            }
                                
                        }
                    }
                    
                    if (stringToTransform_real !=nil && ![stringToTransform_real isEqualToString:@""]) {
                        
                        stringToTransform_real= [stringToTransform_real filterSpecialCharacter];
                        
                        NSRange furiganaRange = NSMakeRange(0, 0);
                        if (lastRange.location == 0) {//第一次进行
                            furiganaRange= [str1 rangeOfString:stringToTransform_real];
                        }else{
                            NSRange nextRange = NSMakeRange(lastRange.location + lastRange.length, str1.length - lastRange.location - lastRange.length );
                            furiganaRange = [str1 rangeOfString:stringToTransform_real options:NSLiteralSearch range:nextRange];
                        }
                        //要标注假名的文字在正常的句子当中不存在。
                        if ( furiganaRange.location  <= str1.length - 1 && furiganaRange.length <= str1.length ) {
                            lastRange = furiganaRange;
                            totalLength += lastRange.length;
                            NSValue * rangeValue = [NSValue valueWithRange:furiganaRange];
                            [dict setObject:furiganaStr_real forKey:rangeValue];
                        }else{
                            //error
                            NSLog(@"Some wrong happend.--%@,error code:0",[self description]);
                        }
                    }
                }
                startRange.length = 0;
                endRange.length = 0;
            }else{
                //假名和要标注的中文没有相同的字符串
                stringToTransform= [stringToTransform filterSpecialCharacter];
                NSRange furiganaRange ;
                if (lastRange.location == 0) {
                    furiganaRange= [str1 rangeOfString:stringToTransform];
                }else{
                    NSRange nextRange = NSMakeRange(lastRange.location + lastRange.length, str1.length - lastRange.location - lastRange.length );
                    furiganaRange = [str1 rangeOfString:stringToTransform options:NSLiteralSearch range:nextRange];
                }
                if ( furiganaRange.location <= str1.length -1 && furiganaRange.length <= str1.length ) {
                    lastRange = furiganaRange;
                    NSValue * rangeValue = [NSValue valueWithRange:furiganaRange];
                    [dict setObject:furiganaStr forKey:rangeValue];
                }else{
                    //error
                    NSLog(@"Some wrong happend.--%@,error code:1",[self description]);
                }
                startRange.length = 0 ;
                endRange.length = 0;
            }
        }
    }];
    return [dict copy];
}

-(NSString*)filterSpecialCharacter{
    NSString * stringCopy = [self copy];
    NSMutableString *str1 = [NSMutableString stringWithString:stringCopy];
    if ([str1 containsString:@"～"]) {
        NSRange range = [str1 rangeOfString:@"～"];
        [str1 deleteCharactersInRange:range];
    }
    return [str1 copy];
}

@end
