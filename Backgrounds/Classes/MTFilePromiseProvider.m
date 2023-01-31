/*
     MTFilePromiseProvider.m
     Copyright 2022 SAP SE
     
     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at
     
     http://www.apache.org/licenses/LICENSE-2.0
     
     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/

#import "MTFilePromiseProvider.h"
#import "Constants.h"


@implementation MTFilePromiseProvider

- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray *writableTypes = [[NSMutableArray alloc] init];
    [writableTypes addObjectsFromArray:[super writableTypesForPasteboard:pasteboard]];
    [writableTypes addObject:kMTFileTypeExport];
    
    return writableTypes;
}

- (id)pasteboardPropertyListForType:(NSPasteboardType)type
{
    id returnValue = [super pasteboardPropertyListForType:type];
        
    if ([type isEqualToString:kMTFileTypeExport]) {
        returnValue = [[self userInfo] valueForKey:kMTFileProviderIndexPathKey];
    }
    
    return returnValue;
}

@end
