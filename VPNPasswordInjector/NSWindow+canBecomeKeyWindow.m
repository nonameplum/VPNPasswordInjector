//
//  NSWindow+canBecomeKeyWindow.m
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 07/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import "NSWindow+canBecomeKeyWindow.h"
#import <objc/runtime.h>

BOOL shouldBecomeKeyWindow;
NSWindow* windowToOverride;

@implementation NSWindow (canBecomeKeyWindow)

//This is to fix a bug with 10.7 where an NSPopover with a text field
//cannot be edited if its parent window won't become key
//The pragma statements disable the corresponding warning for
//overriding an already-implemented method
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (BOOL)popoverCanBecomeKeyWindow
{
    if (self == windowToOverride) {
        return shouldBecomeKeyWindow;
    } else {
        return [self popoverCanBecomeKeyWindow];
    }
}

+ (void)load
{
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(canBecomeKeyWindow)),
                                   class_getInstanceMethod(self, @selector(popoverCanBecomeKeyWindow)));
}
#pragma clang diagnostic pop

@end
