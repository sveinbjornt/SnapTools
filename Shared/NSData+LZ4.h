//
//  NSData+LZ4.h
//  lz4-objc
//
//  Created by Josh Chung on 2/18/13.
//  Copyright (c) 2013 Josh Chung. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kLZ4FastCompression = 0,
    kLZ4HighCompression
} LZ4CompressionLevel;

@interface NSData (LZ4)

- (NSData *)compressLZ4;
- (NSData *)compressLZ4WithLevel:(LZ4CompressionLevel)level;
- (NSData *)decompressLZ4;

@end
