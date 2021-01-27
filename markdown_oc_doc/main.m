//
//  main.m
//  markdown_oc_doc
//
//  Created by ldc on 2021/1/27.
//

#import <Foundation/Foundation.h>

#define RemoveEnumItemComment @""

void help_log() {
    NSLog(@"\nSYNOPSIS:\n\t cm_mddoc [-e|-c] file directory\nDESCRIPTION:\n\t-e\tenglish\n\t-c\tchinese\n\tfile\tsource file for generate markdown file\n\tdirectory\tdirectory for store markdown file\n");
}

typedef NS_ENUM(NSInteger, MDRegularExpress) {
    //注释枚举实例
    MDRegularExpressCommentEnum,
    //注释属性实例
    MDRegularExpressCommentProperty,
    //注释方法实例
    MDRegularExpressCommentMethod,
    //属性实例
    MDRegularExpressProperty,
    //方法实例
    MDRegularExpressMethod,
    //枚举值注释及代码
    MDRegularExpressEnumItemCommentAndCode,
    //从枚举代码中获取枚举类型名
    MDRegularExpressEnumTypeFromEnumCode
};


NSArray<NSString *> *commentGetComponents(NSString *lang, NSString *comment);

NSArray<NSString *> *getComponents(MDRegularExpress re, NSString *content);

NSString *getFirstComponent(MDRegularExpress re, NSString *content);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc != 4) {
            help_log();
            return -1;
        }
        
        NSString *lang_input = [[NSString alloc] initWithUTF8String:argv[1]];
        NSString *lang;
        if ([lang_input isEqualToString:@"-e"]) {
            lang = @"english";
        }else if ([lang_input isEqualToString:@"-c"]) {
            lang = @"chinese";
        }else {
            help_log();
            return -1;
        }
        NSString *path = [[NSString alloc] initWithUTF8String:argv[2]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"file not exist");
            return -1;
        }
        
        NSString *destination_directory = [[NSString alloc] initWithUTF8String:argv[3]];
        BOOL isDirectory = false;
        if (![[NSFileManager defaultManager] fileExistsAtPath:destination_directory isDirectory:&isDirectory]) {
            NSLog(@"directory not exist");
            return -1;
        }
        if (!isDirectory) {
            NSLog(@"you should input a directory");
            return -1;
        }
        
        NSError *error;
        NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@", error);
            return -1;
        }
        //        NSLog(@"%@", content);
        
        NSRegularExpression *non_white_space_re = [NSRegularExpression regularExpressionWithPattern:@"\\S+" options:0 error:&error];
        if (error) {
            NSLog(@"%@", error);
            return -1;
        }
        
        NSMutableString *md = [[NSMutableString alloc] init];
        [md appendString:@"[TOC]\n\n"];
#pragma mark --枚举
        
        NSRegularExpression *comment_rex = [NSRegularExpression regularExpressionWithPattern:@"/\\*.*?\\*/\n" options:0 error:&error];
        if (error) {
            NSLog(@"%@", error);
            return -1;
        }
        
        int index = 0;
        
        NSString *enum_title = [lang isEqualToString:@"chinese"] ? @"枚举" : @"Enum";
        NSString *code_title = [lang isEqualToString:@"chinese"] ? @"代码" : @"Code";
        NSString *specification_title = [lang isEqualToString:@"chinese"] ? @"说明" : @"Specification";
        NSString *enum_name_title = [lang isEqualToString:@"chinese"] ? @"枚举名" : @"Enum Name";
        NSString *enum_value_title = [lang isEqualToString:@"chinese"] ? @"枚举值" : @"Enum Value";
        NSString *description = [lang isEqualToString:@"chinese"] ? @"描述" : @"Description";
        NSArray<NSString *> *enum_components = getComponents(MDRegularExpressCommentEnum, content);
        if (enum_components && enum_components.count > 0) {
            index += 1;
            [md appendFormat:@"## %i.%@\n\n\n", index, enum_title];
            for (int i = 1; i <= enum_components.count; i++) {
                NSString *enum_code = enum_components[i-1];
                NSString *enum_type = getFirstComponent(MDRegularExpressEnumTypeFromEnumCode, enum_code);
                [md appendFormat:@"### %i.%i %@\n", index, i, enum_type];
                [md appendFormat:@"* %@\n", code_title];
                [md appendString:@"  ```objective-c\n"];
                enum_code = [enum_code stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  "];
#ifdef RemoveEnumItemComment
                NSRegularExpression *temp_rex = [NSRegularExpression regularExpressionWithPattern:@"\n.*?/\\*.*?\\*/\n" options:0 error:&error];
                if (error) {
                    NSLog(@"%@", error);
                    return -1;
                }
                NSString *temp_code = [enum_code copy];
                NSTextCheckingResult *temp_result = [temp_rex firstMatchInString:temp_code options:0 range:NSMakeRange(0, temp_code.length)];
                while (temp_result) {
                    temp_code = [temp_code stringByReplacingCharactersInRange:temp_result.range withString:@"\n"];
                    temp_result = [temp_rex firstMatchInString:temp_code options:0 range:NSMakeRange(0, temp_code.length)];
                }
                [md appendFormat:@"  %@\n", temp_code];
#else
                [md appendFormat:@"  %@\n", enum_code];
#endif
                [md appendString:@"  ```\n"];
                
                NSArray<NSString *> *enum_item_comment_and_code_components = getComponents(MDRegularExpressEnumItemCommentAndCode, enum_code);
                if (enum_item_comment_and_code_components && enum_item_comment_and_code_components.count > 0) {
                    [md appendFormat:@"* %@\n\n", specification_title];
                    [md appendFormat:@"  |%@|%@|%@|\n", enum_name_title, enum_value_title, description];
                    [md appendString:@"  |:----|:---:|----:|\n"];
                    for (int i = 1; i <= enum_item_comment_and_code_components.count; i++) {
                        NSString *component = enum_item_comment_and_code_components[i-1];
                        NSTextCheckingResult *commentResult = [comment_rex firstMatchInString:component options:0 range:NSMakeRange(0, component.length)];
                        NSRange range = commentResult.range;
                        NSString *code = [component substringFromIndex:range.location+range.length];
                        code = [code substringToIndex:code.length-1];
                        if ([code hasSuffix:@","]) {
                            code = [code substringToIndex:code.length-1];
                        }
                        //                        NSLog(@"%@", code);
                        NSArray<NSString *> *comment_components = commentGetComponents(lang, component);
                        
                        NSString *desc = @"", *enumName = @"", *enumValue = @"";
                        if (comment_components && comment_components.count > 0) {
                            desc = comment_components[0];
                        }
                        
                        NSArray<NSTextCheckingResult *> *code_components_result = [non_white_space_re matchesInString:code options:0 range:NSMakeRange(0, code.length)];
                        //                        NSLog(@"%@", code_components_result);
                        if (code_components_result && code_components_result.count > 0) {
                            enumName = [code substringWithRange:code_components_result[0].range];
                        }
                        if (code_components_result && code_components_result.count > 2) {
                            enumValue = [code substringWithRange:code_components_result[2].range];
                        }
                        [md appendFormat:@"  |%@|%@|%@|\n", enumName, enumValue, desc];
                    }
                    [md appendString:@"\n\n"];
                }
            }
        }
        
#pragma mark --属性
        
        NSString *propert_title = [lang isEqualToString:@"chinese"] ? @"属性" : @"Property";
        NSArray<NSString *> *property_components = getComponents(MDRegularExpressCommentProperty, content);
        if (property_components && property_components.count > 0) {
            index += 1;
            [md appendFormat:@"## %i.%@\n\n", index, propert_title];
            for (int i = 1; i <= property_components.count; i++) {
                NSString *comment_property = property_components[i-1];
                NSString *property = getFirstComponent(MDRegularExpressProperty, comment_property);
                
                NSString *propertyName = [[property componentsSeparatedByString:@" "] lastObject];
                propertyName = [propertyName substringToIndex:propertyName.length-1];
                if ([propertyName hasPrefix:@"*"]) {
                    propertyName = [propertyName substringFromIndex:1];
                }
                [md appendFormat:@"### %i.%i %@\n\n", index, i, propertyName];
                [md appendFormat:@"* %@\n\n", code_title];
                [md appendString:@"  ```objective-c\n"];
                [md appendFormat:@"  %@\n", property];
                [md appendString:@"  ```\n\n\n"];
                
                NSArray *des_arr = commentGetComponents(lang, comment_property);
                if (des_arr.count > 0) {
                    [md appendFormat:@"* %@\n\n", specification_title];
                    [md appendFormat:@"  > %@\n\n\n",des_arr[0]];
                }
            }
        }
#pragma mark --接口
        
        NSString *method_title = [lang isEqualToString:@"chinese"] ? @"方法" : @"Method";
        NSString *note_title = [lang isEqualToString:@"chinese"] ? @"备注" : @"Note";
        NSString *param_title = [lang isEqualToString:@"chinese"] ? @"参数" : @"Paramater";
        NSArray<NSString *> *method_components = getComponents(MDRegularExpressCommentMethod, content);
        if (method_components && method_components.count > 0) {
            index += 1;
            [md appendFormat:@"## %i.%@\n\n", index, method_title];
            for (int i = 1; i <= method_components.count; i++) {
                
                NSString *comment_method = method_components[i-1];
                
                NSArray<NSString *> *comment_components = commentGetComponents(lang, comment_method);
                if (comment_components && comment_components.count > 0) {
                    
                    NSMutableArray<NSString *> *comment_parameters = [NSMutableArray new];
                    NSString *desc;
                    NSString *note;
                    NSString *brief = @"";
                    for (int i = 1; i <= comment_components.count; i++) {
                        
                        NSString *component = comment_components[i-1];
                        //NSLog(@"\n%@***********\n", component);
                        if (i == 1 && ![component hasPrefix:@" @"]) {
                            desc = component;
                        }else {
                            if ([component hasPrefix:@"@note "]) {
                                component = [component substringFromIndex:6];
                                note = component;
                            }else if ([component hasPrefix:@"@brief "]){
                                component = [component substringFromIndex:7];
                                brief = component;
                            }else {
                                if ([component hasPrefix:@"@param "]) {
                                    component = [component substringFromIndex:7];
                                    [comment_parameters addObject:component];
                                }
                            }
                        }
                    }
                    
                    [md appendFormat:@"### %i.%i %@\n\n", index, i, brief];
                    if (desc) {
                        [md appendFormat:@"* %@\n\n", description];
                        [md appendFormat:@"  > %@\n\n", desc];
                    }
                    if (note) {
                        [md appendFormat:@"* %@\n\n", note_title];
                        [md appendFormat:@"  > %@\n\n", note];
                    }
                    
                    if (comment_parameters.count > 0) {
                        [md appendFormat:@"* %@\n\n", param_title];
                        [md appendFormat:@"  |%@|%@|\n", param_title, description];
                        [md appendString:@"  |:-----|----:|\n"];
                        for (int i = 0; i < comment_parameters.count; i++) {
                            
                            NSString *param = comment_parameters[i];
                            NSArray<NSTextCheckingResult *> *non_white_space_contents = [non_white_space_re matchesInString:param options:0 range:NSMakeRange(0, param.length)];
                            if (non_white_space_contents.count < 2) {
                                continue;
                            }
                            NSString *name = [param substringWithRange:non_white_space_contents[0].range];
                            NSRange range = non_white_space_contents[1].range;
                            NSString *desc = [param substringFromIndex:range.location];
                            [md appendFormat:@"|%@|%@|\n", name, desc];
                        }
                    }
                    
                    [md appendFormat:@"* %@\n\n", code_title];
                    NSString *method = getFirstComponent(MDRegularExpressMethod, comment_method);
                    [md appendString:@"  ```objective-c\n"];
                    method = [method stringByReplacingOccurrencesOfString:@"\n" withString:@"\n  "];
                    [md appendFormat:@"  %@\n", method];
                    [md appendString:@"  ```\n\n\n"];
                }
            }
        }
        
        NSString *lastComponent = [path lastPathComponent];
        NSString *destination = [destination_directory stringByAppendingPathComponent:lastComponent];
        destination = [destination stringByDeletingPathExtension];
        NSString *lang_flag = [lang isEqualToString:@"chinese"] ? @"_ch" : @"_en";
        destination = [destination stringByAppendingString:lang_flag];
        destination = [destination stringByAppendingPathExtension:@"md"];
        NSURL *url = [NSURL fileURLWithPath:destination];
        [md writeToURL:url atomically:true encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@", error);
            return -1;
        }
    }
    return 0;
}

//从包含注释的字符串中提取注释内容
NSArray<NSString *> *commentGetComponents(NSString *lang, NSString *comment) {
    
    NSMutableArray<NSString *> *components = [NSMutableArray new];
    NSError *error;
    NSString *re_str = [NSString stringWithFormat:@"\\\\~%@.+?((\\\\~)|(\\*/))", lang];
    NSRegularExpression *comment_lang_re = [NSRegularExpression regularExpressionWithPattern:re_str options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    NSString *comment_component_re_str = [NSString stringWithFormat:@"(\\*  .+?\n)|(\\\\~%@ .+? ((\\\\~)|(\\*/)))", lang];
    NSRegularExpression *comment_component_re = [NSRegularExpression regularExpressionWithPattern:comment_component_re_str options:0 error:&error];
    if (error) {
        NSLog(@"%@", error);
        return components;
    }
    
    NSTextCheckingResult *comment_result = [comment_lang_re firstMatchInString:comment options:0 range:NSMakeRange(0, comment.length)];
    
    if (comment_result != nil) {
        NSString *lang_comment = [comment substringWithRange:comment_result.range];
        NSArray<NSTextCheckingResult *> *comment_components = [comment_component_re matchesInString:lang_comment options:0 range:NSMakeRange(0, lang_comment.length)];
        for (int i = 1; i <= comment_components.count; i++) {
            
            NSString *component = [lang_comment substringWithRange:comment_components[i-1].range];
            if ([component hasPrefix:@"*  "]) {
                component = [component substringFromIndex:3];
                component = [component substringToIndex:component.length-1];
            }else {
                component = [component substringFromIndex:3+lang.length];
                component = [component substringToIndex:component.length-2];
            }
            [components addObject:component];
        }
    }
    return components;
}
//提取符合正则类型的所有字符串
NSArray<NSString *> *getComponents(MDRegularExpress re, NSString *content) {
    
    NSRegularExpression *rex;
    NSError *error;
    switch (re) {
        case MDRegularExpressCommentEnum:
            rex = [NSRegularExpression regularExpressionWithPattern:@"typedef NS_ENUM.+?;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
            break;
        case MDRegularExpressCommentProperty:
            rex = [NSRegularExpression regularExpressionWithPattern:@"/\\*!\n( \\*[^\n]*?\n)*? \\*/\n@property.+?;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
            break;
        case MDRegularExpressCommentMethod:
            rex = [NSRegularExpression regularExpressionWithPattern:@"/\\*!\n( \\*[^\n]*?\n)*? \\*/\n- .+?;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
            break;
        case MDRegularExpressEnumItemCommentAndCode:
            rex = [NSRegularExpression regularExpressionWithPattern:@"/\\*[^\n]+?\\*/\n[^\n]+?\n" options:0 error:&error];
            break;
        default:
            break;
    }
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    if (rex == nil) {
        NSLog(@"不支持的正则类型");
        return nil;
    }
    NSMutableArray<NSString *> *result = [NSMutableArray new];
    NSArray<NSTextCheckingResult *> *results = [rex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
    for (NSTextCheckingResult *temp in results) {
        [result addObject:[content substringWithRange:temp.range]];
    }
    return result;
}
//提取第一个符合正则类型的字符串
NSString *getFirstComponent(MDRegularExpress re, NSString *content) {
    
    NSRegularExpression *rex;
    NSError *error;
    switch (re) {
        case MDRegularExpressProperty:
            rex = [NSRegularExpression regularExpressionWithPattern:@"@property.+?;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
            break;
        case MDRegularExpressMethod:
            rex = [NSRegularExpression regularExpressionWithPattern:@"- .+?;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
            break;
        case MDRegularExpressEnumTypeFromEnumCode:
            rex = [NSRegularExpression regularExpressionWithPattern:@", .+?\\)" options:0 error:&error];
        default:
            break;
    }
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    if (rex == nil) {
        NSLog(@"不支持的正则类型");
        return nil;
    }
    NSTextCheckingResult *result = [rex firstMatchInString:content options:0 range:NSMakeRange(0, content.length)];
    if (result) {
        NSString *temp = [content substringWithRange:result.range];
        if (re == MDRegularExpressEnumTypeFromEnumCode) {
            temp = [temp substringWithRange:NSMakeRange(2, temp.length - 3)];
        }
        return temp;
    }else {
        return nil;
    }
}
