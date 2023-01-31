/*
     MTCollectionViewItem.m
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

#import "MTCollectionViewItem.h"

@implementation MTCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self view] setWantsLayer:YES];
    [[[self view] layer] setBorderWidth:0.0];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [[self view] layer].backgroundColor = (selected) ? [NSColor controlAccentColor].CGColor : [NSColor clearColor].CGColor;
}

- (BOOL)setImage:(NSImage*)anImage withTooltip:(NSString*)toolTip
{
    BOOL success = NO;
    
    if ([anImage isValid]) {
        [[self imageView] setImage:anImage];
        [[self imageView] setToolTip:toolTip];
        success = YES;
    }
    
    return success;
}

@end
