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

#define PROGRAM_NAME                @"SnapDart"
#define PROGRAM_VERSION             @"1.0"
#define PROGRAM_CREATOR_STAMP       [NSString stringWithFormat:@"%@-%@", PROGRAM_NAME, PROGRAM_VERSION]
#define PROGRAM_MIN_SYS_VERSION     @"10.8.0"
#define PROGRAM_BUNDLE_IDENTIFIER   @"org.sveinbjorn.SnapDart"
#define PROGRAM_AUTHOR              @"Sveinbjorn Thordarson"
#define PROGRAM_WEBSITE             @"http://sveinbjorn.org/SnapDart"
#define PROGRAM_GITHUB_WEBSITE      @"http://github.com/sveinbjornt/SnapDart"
#define PROGRAM_DONATIONS           @"http://sveinbjorn.org/donations"

#define PROGRAM_MANPAGE             @"snap.man.html"
#define PROGRAM_LICENSE_FILE        @"License.html"
#define PROGRAM_DOCUMENTATION       @"Documentation.html"

#define PROGRAM_MANPAGE_URL         @"http://sveinbjorn.org/files/manpages/snap.man.html"
#define PROGRAM_DOCUMENTATION_URL   @"http://sveinbjorn.org/files/manpages/SnapDartDocumentation.html"

#define PROGRAM_APP_SUPPORT_PATH    [[NSString stringWithFormat:@"~/Library/Application Support/%@", PROGRAM_NAME] stringByExpandingTildeInPath]
#define PROGRAM_HISTORY_PATH        [NSString stringWithFormat:@"%@/History", PROGRAM_APP_SUPPORT_PATH]
#define PROGRAM_HISTORY_BOOKMARKS   [NSString stringWithFormat:@"%@/Bookmarks", PROGRAM_APP_SUPPORT_PATH]
#define PROGRAM_REQUIRED_DIRS       @[PROGRAM_APP_SUPPORT_PATH, PROGRAM_HISTORY_PATH, PROGRAM_HISTORY_BOOKMARKS]

#define COLUMNS @[@"Icon", @"Path", @"File Size", @"Kind", @"Date Modified", @"Date Created", @"Date Accessed", @"User:Group", @"Permission", @"UTI"]

// abbreviations
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
#define FILEMGR     [NSFileManager defaultManager]
#define WORKSPACE   [NSWorkspace sharedWorkspace]


