/*
     MTPopUpButton.h
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
 @abstract This class defines a popup button that can return the index of the previously selected item.
 */

@interface MTPopUpButton : NSPopUpButton <NSMenuDelegate>

/*!
 @property      previousSelectionIndex
 @abstract      Returns the index of the previously selected menu item.
 @discussion    The property returns an integer value.
*/
@property (assign, readonly) NSInteger previousSelectionIndex;

@end
