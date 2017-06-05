/*
 Copyright (c) 2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its contributors may
 be used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#import "SnapFileManager.h"
#import "Common.h"
#import "NSData+LZ4.h"

@implementation SnapFileManager

+ (NSArray *)readHistory {
    NSArray *files = [SnapFileManager snapFilesInDirectory:PROGRAM_HISTORY_PATH];
    return files;
}

+ (NSArray *)readBookmarks {
    NSArray *files = [SnapFileManager snapFilesInDirectory:PROGRAM_BOOKMARKS_PATH];
    return files;
}

+ (NSArray *)snapFilesInDirectory:(NSString *)path {
    // TODO: Add caching
    NSMutableArray *arr = [NSMutableArray array];
    NSDirectoryEnumerator *dirEnumerator = [FILEMGR enumeratorAtPath:path];
    NSString *filename;
    while ((filename = [dirEnumerator nextObject]) != nil) {
        if ([filename hasSuffix:PROGRAM_FILENAME_SUFFIX]) {
            [arr addObject:filename];
        }
    }
    return arr;
}

#pragma mark -

+ (NSArray *)readSnapFileAtPath:(NSString *)path {
    
    NSData *fileData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]
                                             options:NSDataReadingMappedAlways
                                               error:nil];
    if (!fileData) {
        NSLog(@"Unable to read file %@", path);
        return nil;
    }
    
    if ([SnapFileManager isCompressedData:fileData]) {
        fileData = [fileData decompressLZ4];
        if (!fileData) {
            NSLog(@"Unable to decompress data in file %@", path);
            return nil;
        }
    }
    
    NSString *str = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    if (!str) {
        NSLog(@"Unable to create string from data");
        return nil;
    }
    
    NSArray *paths = [str componentsSeparatedByString:@"\n"];
    
//    NSString *lz4path = [path stringByAppendingString:@".lz4"];
//    [SnapFileManager writeSnap:paths toPath:path];
    
    return paths;
}

+ (BOOL)writeSnap:(NSArray *)items toPath:(NSString *)path {
    NSString *str = [items componentsJoinedByString:@"\n"];
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        NSLog(@"Error encoding string data");
        return NO;
    }
    data = [data compressLZ4WithLevel:kLZ4HighCompression];
    if (!data) {
        NSLog(@"Failed to LZ4 compress data");
        return NO;
    }
    
    // write 4 byte header
    /* Magic Number */
//    LZ4F_writeLE32(dstPtr, LZ4F_MAGICNUMBER);
//    dstPtr += 4;
//    headerStart = dstPtr;
//    
//    /* FLG Byte */
//    *dstPtr++ = (uint8_t)(((1 & 0x03) << 6)    /* Version('01') */
//                       + ((cctxPtr->prefs.frameInfo.blockMode & 0x01 ) << 5)    /* Block mode */
//                       + ((cctxPtr->prefs.frameInfo.contentChecksumFlag & 0x01 ) << 2)   /* Frame checksum */
//                       + ((cctxPtr->prefs.frameInfo.contentSize > 0) << 3));   /* Frame content size */
//    /* BD Byte */
//    *dstPtr++ = (BYTE)((cctxPtr->prefs.frameInfo.blockSizeID & 0x07) << 4);
//    /* Optional Frame content size field */
//    if (cctxPtr->prefs.frameInfo.contentSize) {
//        LZ4F_writeLE64(dstPtr, cctxPtr->prefs.frameInfo.contentSize);
//        dstPtr += 8;
//        cctxPtr->totalInSize = 0;
//    }
//    /* CRC Byte */
//    *dstPtr = LZ4F_headerChecksum(headerStart, dstPtr - headerStart);
//    dstPtr++;

    
    
    return [data writeToFile:path atomically:YES];
}

+ (BOOL)isCompressedData:(NSData *)data {
//    if ([data length] < 4) {
//        return NO;
//    }
//    
//    unsigned long headerLong = 0;
//    [data getBytes:&headerLong length:4];
//    return (headerLong == LZ4_MAGIC_HEADER);
    
    if ([data length] == 0) {
        return NO;
    }

    unsigned char byte = NULL;
    [data getBytes:&byte length:1];
    return (byte != '/');
    
}

@end
