//
//  main.m
//  txt_line_feed_convert
//
//  Created by ldc on 2021/1/27.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if (argc != 3) {
            NSLog(@"\nSYNOPSIS:\n\t [-m2w|-w2m] [file]\nDESCRIPTION:\n\t-m2w\tmac to windows\n\t-w2m\twindows to mac\n");
            return -1;
        }
        
        NSString *path = [[NSString alloc] initWithUTF8String:argv[2]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"file not exists");
            return -1;
        }
        
        if (![path hasSuffix:@".txt"]) {
            NSLog(@"请传入txt文件");
            return -1;
        }
        
        NSError *error;
        NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%@",error);
            return -1;
        }
        
        NSString *option = [NSString stringWithUTF8String:argv[1]];
        NSString *re_str;
        NSString *templete;
        if ([option isEqualToString:@"-w2m"]) {
            re_str = @"\r\n";
            templete = @"\n";
        }else if ([option isEqualToString:@"-m2w"]) {
            if ([content containsString:@"\r\n"]) {
                return 0;
            }
            re_str = @"\n";
            templete = @"\r\n";
        }else {
            NSLog(@"invalid option parameter");
            return -1;
        }
        
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:re_str options:0 error:&error];
        if (error) {
            NSLog(@"%@", error);
            return -1;
        }
        
        NSString *newContent = [re stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:templete];
        [newContent writeToFile:path atomically:true encoding:NSUTF8StringEncoding error:nil];
        if (error) {
            NSLog(@"%@",error);
            return -1;
        }
    }
    return 0;
}
