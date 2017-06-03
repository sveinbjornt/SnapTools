/*
 Copyright (c) 2012-2017, Sveinbjorn Thordarson <sveinbjornt@gmail.com>
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

#import "PathParser.h"

@implementation PathParser

+ (NSString *)makeAbsolutePath:(NSString *)path {
    NSString *currDir = [[NSFileManager defaultManager] currentDirectoryPath];
    return [self makeAbsolutePath:path relativeToDirectory:currDir];
}

+ (NSString *)makeAbsolutePath:(NSString *)path relativeToDirectory:(NSString *)dirPath {
    NSString *absPath = [path stringByExpandingTildeInPath];
    if ([absPath isAbsolutePath] == NO) {
        absPath = [dirPath stringByAppendingPathComponent:path];
    }
    return [absPath stringByStandardizingPath];
}

+ (NSString *)trim:(NSString *)str {
    return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (BOOL)isHiddenFileAtPath:(NSString *)path {
    return [[path lastPathComponent] hasPrefix:@"."];
}

+ (NSMutableSet *)parse:(NSString *)str {
    
    // empty string?
    str = [self trim:str];
    if (![str length]) {
        return [NSMutableSet set];
    }
    
    NSMutableSet *potentialPaths = [NSMutableSet set];
    
    // Separate each line of input, parse it for potential paths
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    for (NSString *l in lines) {
        NSString *line = [self trim:l];
        
        // is the full line a valid path?
        NSString *abs = [self makeAbsolutePath:line];
        if ([[NSFileManager defaultManager] fileExistsAtPath:abs]) {
            [potentialPaths addObject:line];
            continue;
        }
        
        // otherwise, try to find a path within the string
        NSUInteger len = [line length];
        for (int i = 0; i < len; i++) {
            if ([line characterAtIndex:i] == ' ') {
                NSString *preStr = [line substringToIndex:i];
                NSString *postStr = [line substringFromIndex:i];
                [potentialPaths addObject:[self trim:preStr]];
                [potentialPaths addObject:[self trim:postStr]];
            }
        }
    }
    
    // Standardise paths and filter out invalid ones
    NSMutableSet *paths = [NSMutableSet set];
    for (NSString *p in potentialPaths) {
        NSString *absPath = [self makeAbsolutePath:p];
        if ([[NSFileManager defaultManager] fileExistsAtPath:absPath]) {
            [paths addObject:absPath];
        }
    }
    return paths;
}

@end
