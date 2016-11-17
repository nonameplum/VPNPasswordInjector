//
//  NSWindow+canBecomeKeyWindow.h
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 07/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern BOOL shouldBecomeKeyWindow;
extern NSWindow* windowToOverride;

@interface NSWindow (canBecomeKeyWindow)

@end
