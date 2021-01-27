//
//  main.swift
//  file_lock
//
//  Created by ldc on 2021/1/22.
//

#import <Foundation/Foundation.h>

void helpLog() {
    
    NSLog(@"\nSYNOPSIS:\n\t cm_flk [file]");
}

static uint32 p_key = 0x66696c65;

void appendSymbolData(NSMutableData *data) {
    
    uint32_t head1 = arc4random();
    uint32_t head2 = head1^p_key;
    HTONL(head2);
    [data appendBytes:&head1 length:4];
    [data appendBytes:&head2 length:4];
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
            unsigned char *bytes = (unsigned char *)data.bytes;
            
            NSMutableData *result = [NSMutableData new];
            NSData *symbolData;
            if (data.length >= 8) {
                uint32_t *bytes32 = (uint32_t *)bytes;
                uint32_t head1 = bytes32[0];
                uint32_t head2 = bytes32[1];
                NTOHL(head2);
                
                if ((head1 ^ p_key) == head2) {
                    symbolData = [data subdataWithRange:NSMakeRange(0, 8)];
                    data = [data subdataWithRange:NSMakeRange(8, data.length - 8)];
                    bytes = (unsigned char *)data.bytes;
                }else {
                    appendSymbolData(result);
                    symbolData = result;
                }
            }else {
                appendSymbolData(result);
                symbolData = result;
            }
            
            int sum = 0;
            for (int i = 0; i < 8; i++) {
                sum += ((Byte *)symbolData.bytes)[i];
            }
            
            uint8 key = (uint8)sum%256;
            for (int i = 0; i < data.length; i++) {
                uint8 temp = bytes[i] ^ key;
                [result appendBytes:&temp length:1];
                key >= 0x80 ? key = 1 : (key = key*2);
            }
            
            [handle truncateFileAtOffset:result.length];
            [handle seekToFileOffset:0];
            [handle writeData:result];
        }
    }
    return 0;
}
