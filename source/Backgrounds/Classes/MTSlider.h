/*
     MTSlider.h
     Copyright 2022-2024 SAP SE
     
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
 @abstract This class defines a slider that can return it's previous value.
 */

@interface MTSlider : NSSlider

/*!
 @property      previousValue
 @abstract      Returns the previous value of the slider.
 @discussion    The property returns a double value.
*/
@property (assign, readonly) double previousValue;

@end
