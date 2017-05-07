/*
 Copyright (c) 2010-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import <Foundation/Foundation.h>

@implementation NSFileManager (FileOrFolderSize)

- (UInt64) fileOrFolderSize:(NSString *)path {
	UInt64 size = 0;
	BOOL isDir;
	
    if (path == nil || ![self fileExistsAtPath:path isDirectory:&isDir]) {
		return 0;
    }
        
	if (isDir) {
		NSDirectoryEnumerator *dirEnumerator = [self enumeratorAtPath:path];
        while ([dirEnumerator nextObject]) {
            if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]]) {
				size += [[dirEnumerator fileAttributes] fileSize];
            }
        }
    } else {
        size = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    }
    
	return size;
}

- (NSString *)fileOrFolderSizeAsHumanReadable:(NSString *)path {
	return [self sizeAsHumanReadable:[self fileOrFolderSize:path]];
}

- (NSString *)sizeAsHumanReadable:(UInt64)size {
	NSString	*str;
	
	if (size < 1024ULL) 
		str = [NSString stringWithFormat:@"%u bytes", (unsigned int)size];
	else if (size < 1048576ULL) 
		str = [NSString stringWithFormat:@"%ld KB", (long)size/1024];
	else if (size < 1073741824ULL) 
		str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
	else 
		str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
    
	return str;
}

- (BOOL)isFolder:(NSString *)path {
    BOOL isDir = NO;
    BOOL exists = [self fileExistsAtPath:path isDirectory:&isDir];
    return (exists && isDir);
}

@end
