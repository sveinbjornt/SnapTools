//
//  NSData+LZ4.m
//  lz4-objc
//
//  Created by Josh Chung on 2/18/13.
//  Copyright (c) 2013 Josh Chung. All rights reserved.
//

#import "NSData+LZ4.h"

#import "lz4.h"
#import "lz4hc.h"

static const int lz4_header_size = sizeof(uint32_t);

@implementation NSData (LZ4)

- (NSData *)compressLZ4 {
    return [self compressLZ4WithLevel:kLZ4FastCompression];
}

- (NSData *)compressLZ4WithLevel:(LZ4CompressionLevel)level {
    int (*compressFunction)(const char *, char *, int);
    switch (level) {
        case kLZ4FastCompression:
            compressFunction = LZ4_compress;
            break;
        case kLZ4HighCompression:
            compressFunction = LZ4_compressHC;
            break;
        default:
            NSAssert(NO, @"Invalid Compression Level");
            return nil;
    }

    uint32_t original_size = (uint32_t)self.length;
    char *out_buff = (char *)malloc(lz4_header_size + LZ4_compressBound(original_size));
    memcpy(out_buff, &original_size, lz4_header_size);
    int out_size = compressFunction(self.bytes, out_buff + lz4_header_size, self.length);
    if (out_size < 0) {
        free(out_buff);
        return nil;
    }
    return [[NSData alloc] initWithBytesNoCopy:out_buff length:lz4_header_size + out_size];
}

- (NSData *)decompressLZ4 {
    uint32_t original_size;
    memcpy(&original_size, self.bytes, lz4_header_size);

    char *out_buff = (char *)malloc(original_size);
    if (LZ4_uncompress(self.bytes + lz4_header_size, out_buff, original_size) < 0) {
        free(out_buff);
        return nil;
    }
    return [[NSData alloc] initWithBytesNoCopy:out_buff length:original_size];
}
@end
