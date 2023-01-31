/*
     MTFilePromiseProvider.h
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

#import <Cocoa/Cocoa.h>

@interface MTFilePromiseProvider : NSFilePromiseProvider

/*!
 @method        writableTypesForPasteboard:
 @abstract      Returns an array of UTI strings of data types the receiver can write to pasteboard.
 @param         pasteboard The pasteboard to write to.
 */
- (NSArray<NSPasteboardType> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard;

/*!
 @method        pasteboardPropertyListForType:
 @abstract      Returns the appropriate property list object for the provided type.
 @param         type One of the types the receiver supports for writing (one of the UTIs returned by its implementation of writableTypesForPasteboard:).
 @discussion    The returned value will commonly be the NSData object for the specified data type. However, if this method returns either a string, or any other property-list type, the pasteboard will automatically convert these items to the correct data format required for the pasteboard.
 */
- (id)pasteboardPropertyListForType:(NSPasteboardType)type;

@end

