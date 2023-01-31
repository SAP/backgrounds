/*
     MTCollectionViewItem.h
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

/*!
 @abstract This class defines how the collection view item of the collection view should look like.
 */

@interface MTCollectionViewItem : NSCollectionViewItem

/*!
 @method        setImage:withTooltip:
 @abstract      Set the collection view item's image and tooltip.
 @param         anImage A NSImage object.
 @param         toolTip A NSString object containing the text for the tooltip.
 @discussion    Returns YES if a valid image has been provided, otherwise returns NO.
 */
- (BOOL)setImage:(NSImage*)anImage withTooltip:(NSString*)toolTip;

@end
