/*
     MTLogoCollection.h
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
 @abstract This class provides methods to easily access logo data.
 */

@interface MTLogoCollection : NSObject

/*!
 @method        logos
 @abstract      Get all logos.
 @discussion    Returns an NSArray of NSDIctionaries, each containing the information for a logo.
 */
- (NSArray <NSDictionary*> *)logos;

/*!
 @method        logoWithName:
 @abstract      Get the dictionary for the logo with the given name.
 @param         logoName The name of the logo.
 @discussion    Returns an NSDictionary containing the information for the logo with the given name or nil,
 if no logo with this name exists.
 */
- (NSDictionary*)logoWithName:(NSString*)logoName;

/*!
 @method        logoImageWithDictionary:
 @abstract      Get the logo image from a given logo dictionary.
 @param         dict The dictionary of the logo.
 @discussion    Returns an NSImage object of the logo image or nil, if the logo image could not be found
 or was invalid. This method first evaluates kMTDefaultsLogoFilePath and if this does not return a valid image,
 it tries to get the data from kMTDefaultsLogoImageData.
 */
+ (NSImage*)logoImageWithDictionary:(NSDictionary*)dict;

@end

