//
//  main.m
//  FTFirmwareGenerator
//
//  Created by ldc on 2021/1/19.
//

#import <Foundation/Foundation.h>

void helpLog() {
    
    NSLog(@"\nSYNOPSIS:\n\t cm_ftfg [file]");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if (argc != 2) {
            helpLog();
            return -1;
        }else {
            
            NSString *path = [NSString stringWithUTF8String:argv[1]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSLog(@"file not exists");
                return -1;
            }
            
            NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:path];
            NSData *data = [handle readDataToEndOfFile];
            
            NSMutableData *result = [NSMutableData new];
            uint32 fileCount = 1;
            [result appendBytes:&fileCount length:4];
            [result appendBytes:"\xaa\x55\xaa\x55" length:4];
            uint32 fileLength = (uint32)data.length;
            [result appendBytes:&fileLength length:4];
            Byte temp[56] = {0};
            [result appendBytes:temp length:56];
            [result appendData:data];
            
            [handle truncateFileAtOffset:result.length];
            [handle seekToFileOffset:0];
            [handle writeData:result];
        }
    }
    return 0;
}
