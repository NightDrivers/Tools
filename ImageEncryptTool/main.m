//
//  main.m
//  ImageEncryptTool
//
//  Created by ldc on 2021/1/27.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

void help_log() {
    
    NSLog(@"\nSYNOPSIS:\n\t -e [image] [file]\n\t -d [image] [directory]");
}

void decryptBytesFromImage(Byte *bitmap, int bytePosition, int length, Byte *outBuffer) {
    
    int bitPosition = bytePosition*8;
    for (int i = bitPosition; i < bitPosition + length*8; i++) {
        int index = i/3*4 + i%3;
        uint8_t flag = bitmap[index]%2 == 1 ? 1 : 0;
        if (flag == 1) {
            outBuffer[(i - bitPosition)/8] |= (flag<<(7-i%8));
        }
    }
}

int encryptBytesIntoImage(Byte *bitmap, int bitmapLength, Byte *content, int contentLength) {
    
    if (bitmapLength/4*3 < contentLength*8) {
        return -1;
    }
    
    for (int i = 0; i < bitmapLength/4; i++) {
        
        int index = 0;
        int loc = 0;
        int bit_loc = 0;
        
        for (int j = 0; j < 3; j++) {
            
            index = i*3+j;
            loc = index/8;
            bit_loc = index%8;
            
            uint8_t byte = content[loc];
            byte = (byte & (1<<(7-bit_loc)));
            if (byte == 0) {
                if (bitmap[index+i]%2!=0) {
                    bitmap[index+i] -= 1;
                }
            }else {
                if (bitmap[index+i]%2==0) {
                    bitmap[index+i] += 1;
                }
            }
            
            if (index >= contentLength*8) {
                break;
            }
        }
        if (index >= contentLength*8) {
            //                    NSLog(@"%i", index);
            break;
        }
    }
    return 0;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if (argc != 4) {
            help_log();
            return -1;
        }
        BOOL isEncrypt;
        if (strcmp(argv[1], "-d") == 0) {
            isEncrypt = false;
        }else if (strcmp(argv[1], "-e") == 0) {
            isEncrypt = true;
        }else {
            help_log();
            return -1;
        }
        NSString *imagePath = [NSString stringWithUTF8String:argv[2]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            NSLog(@"image file not exist");
            return -1;
        }
        NSString *destinationPath = [NSString stringWithUTF8String:argv[3]];
        BOOL isDirectory;
        BOOL isDestinationExist = [[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isDirectory];
        if (!isDestinationExist) {
            NSLog(@"destination path not exist");
            return -1;
        }
        if (isEncrypt == isDirectory) {
            NSLog(@"need a directory to save decrypt file or a file to encrypt");
            NSLog(@"%@--%@", @(isEncrypt), @(isDirectory));
            return -1;
        }
        NSURL *url = [NSURL fileURLWithPath:imagePath];
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
        if (CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) {
            NSLog(@"不支持的颜色空间");
            return -1;
        }
        int width = (int)CGImageGetWidth(image);
        int height = (int)CGImageGetHeight(image);
        CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
        if (dataProvider == nil) {
            NSLog(@"invalid image file");
            return -1;
        }
        CFDataRef data = CGDataProviderCopyData(dataProvider);
        const UInt8 *bytes = CFDataGetBytePtr(data);
        CFIndex count = CFDataGetLength(data);
        UInt8 *pixels = (UInt8 *)calloc(count, 1);
        for (int i = 0; i < count; i++) {
            pixels[i] = bytes[i];
        }
        
        if (isEncrypt) {
            NSString *fileName = [destinationPath lastPathComponent];
            //数据格式 4字节后续数据长度 + 2字节文件名长度 + 文件名数据 + 文件数据
            NSData *fileNameData = [fileName dataUsingEncoding:NSUTF8StringEncoding];
            NSData *fileData = [NSData dataWithContentsOfFile:destinationPath];
            uint16_t fileNameDataLength = (uint16_t)fileNameData.length;
            uint32_t contentDataLength = (uint32_t)(fileNameData.length + fileData.length + 2);
            NSMutableData *data = [NSMutableData dataWithBytes:&contentDataLength length:4];
            [data appendBytes:&fileNameDataLength length:2];
            [data appendData:fileNameData];
            [data appendData:fileData];
            
            int encryptResult = encryptBytesIntoImage(pixels, (int)count, (Byte *)data.bytes, (int)data.length);
            if (encryptResult != 0) {
                NSLog(@"图片太小，不足以填充信息");
                return -1;
            }
            
            CIImage *result = [CIImage imageWithBitmapData:[NSData dataWithBytes:pixels length:count] bytesPerRow:CGImageGetBytesPerRow(image) size:CGSizeMake(width, height) format:kCIFormatRGBA8 colorSpace:CGColorSpaceCreateDeviceRGB()];
            CIContext *ctx = [CIContext context];
            NSData *resultData = [ctx PNGRepresentationOfImage:result format:kCIFormatRGBA8 colorSpace:CGColorSpaceCreateDeviceRGB() options:@{}];
            NSString *resultPath = [NSString stringWithFormat:@"/Users/ldc/Desktop/%@.png",[NSUUID UUID].UUIDString];
            BOOL flag = [resultData writeToFile:resultPath atomically:true];
            if (!flag) {
                NSLog(@"写入失败");
                return -1;
            }else {
                NSLog(@"文件生成成功=> %@",resultPath);
            }
        }else {
            
            if (count/4*3 < 5*8) {
                NSLog(@"图片太小");
                return -1;
            }
            uint32_t length = 0;
            decryptBytesFromImage(pixels, 0, 4, (Byte *)&length);
            
            if (count/4*3 < (length+4)*8) {
                NSLog(@"图片太小与数据大小不匹配");
                return -1;
            }
            
            uint16_t fileNameLength = 0;
            decryptBytesFromImage(pixels, 4, 2, (Byte *)&fileNameLength);
            if (fileNameLength > 100) {
                NSLog(@"文件名太长");
                return -1;
            }
            
            uint8_t *fileNameBytes = calloc(fileNameLength, sizeof(uint8_t));
            decryptBytesFromImage(pixels, 6, fileNameLength, fileNameBytes);
            NSString *fileName = [[NSString alloc] initWithData:[NSData dataWithBytes:fileNameBytes length:fileNameLength] encoding:NSUTF8StringEncoding];
            free(fileNameBytes);
            if (fileName == nil || fileName.length == 0) {
                NSLog(@"解析文件名失败");
                return -1;
            }
            NSLog(@"文件名=> %@", fileName);
            
            int contetetLength = length - 2 - fileNameLength;
            uint8_t *content = calloc(contetetLength, 1);
            int contentPosition = 6+fileNameLength;
            decryptBytesFromImage(pixels, contentPosition, contetetLength, content);
            NSData *fileData = [NSData dataWithBytes:content length:contetetLength];
            NSError *error;
            BOOL flag = [fileData writeToURL:[NSURL fileURLWithPath:[destinationPath stringByAppendingPathComponent:fileName]] options:NSAtomicWrite error:&error];
            free(content);
            if (!flag) {
                NSLog(@"写入失败:%@", error);
                return -1;
            }
        }
    }
    return 0;
}
