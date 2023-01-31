/*
     MTLogoCollection.m
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

#import "MTLogoCollection.h"
#import "Constants.h"

@interface MTLogoCollection ()
@property (nonatomic, strong, readwrite) NSMutableArray *logoArray;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@end

@implementation MTLogoCollection


- (id)init
{
    self = [super init];
    
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        
        _logoArray = [[NSMutableArray alloc] init];
        [_logoArray addObjectsFromArray:[self getLogos]];
    }
    
    return self;
}

- (NSArray*)getLogos
{
    NSArray *allLogos = [_userDefaults arrayForKey:kMTDefaultsLogoImages];
    return allLogos;
}

- (NSArray*)logos
{
    return _logoArray;
}

- (NSDictionary*)logoWithName:(NSString*)logoName
{
    NSDictionary *logoDict = nil;
    NSArray *filteredArray = [_logoArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", kMTDefaultsLogoName, logoName]];
    
    if ([filteredArray count] > 0) {
        logoDict = [filteredArray firstObject];
    }
    
    return logoDict;
}

+ (NSImage*)logoImageWithDictionary:(NSDictionary*)dict
{
    NSImage *logoImage = nil;
    
    if (dict){
        
        NSString *imageFilePath = [dict valueForKey:kMTDefaultsLogoFilePath];
        
        if (imageFilePath) { logoImage = [[NSImage alloc] initWithContentsOfFile:imageFilePath]; }
        
        if (![logoImage isValid]) {
            NSData *imageData = [dict valueForKey:kMTDefaultsLogoImageData];
            if (imageData) { logoImage = [[NSImage alloc] initWithData:imageData]; }
        }
    }
    
    return logoImage;
}

@end
