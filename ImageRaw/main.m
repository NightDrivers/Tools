//
//  main.m
//  ImageRaw
//
//  Created by ldc on 2021/1/27.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if (argc != 2) {
            return -1;
        }
        NSURL *url = [NSURL fileURLWithPath:[[NSString alloc] initWithUTF8String:argv[1]]];
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
        if (dataProvider == nil) {
            return -1;
        }
        CFDataRef data = CGDataProviderCopyData(dataProvider);
        const UInt8 *bytes = CFDataGetBytePtr(data);
        CFIndex length = CFDataGetLength(data);
        NSMutableArray<NSString *> *arr = [NSMutableArray new];
        for (int i = 0; i < length; i++) {
            [arr addObject:[NSString stringWithFormat:@"%02x", bytes[i]]];
        }
        NSLog(@"\n%@", [arr componentsJoinedByString:@" "]);
    }
    return 0;
}
