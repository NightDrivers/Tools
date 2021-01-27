//
//  main.m
//  hex_log
//
//  Created by ldc on 2021/1/27.
//

#import <Foundation/Foundation.h>

void help_log() {
    
    NSLog(@"\nSYNOPSIS:\n\t cm_hex [-c c] [file]\nDESCRIPTION:\n\t-c\tcount of bytes to print\n\tfile\tsource file\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        NSString *path;
        NSFileHandle *handle;
        NSUInteger readCount = 0;
        if (argc == 2) {
            path = [NSString stringWithUTF8String:argv[1]];
        }else if (argc == 4) {
            if (strcmp(argv[1], "-c") != 0) {
                help_log();
                return -1;
            }
            path = [NSString stringWithUTF8String:argv[3]];
            long count = strtol(argv[2], NULL, 0);
            if (count < 0) {
                readCount = 0;
            }else {
                readCount = (NSUInteger)count;
            }
        }else {
            help_log();
            return -1;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"file not exist");
            return -1;
        }
        handle = [NSFileHandle fileHandleForReadingAtPath:path];
        [handle seekToEndOfFile];
        if (readCount > handle.offsetInFile + 1 || readCount == 0) {
            readCount = handle.offsetInFile + 1;
        }
        [handle seekToFileOffset:0];
        NSData *data = [handle readDataOfLength:readCount];
        
        NSMutableString *result = [NSMutableString new];
        unsigned char *bytes = (unsigned char *)(data.bytes);
        for (int i = 0; i < data.length; i++) {
            [result appendFormat:@"%02x ", bytes[i]];
        }
        NSLog(@"\n%@", result);
    }
    return 0;
}
