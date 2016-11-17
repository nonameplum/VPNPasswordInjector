//
//  VPNPasswordInjector.m
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import "VPNPasswordInjector.h"

@implementation VPNPasswordInjector

- (void) fillPasswordForVPNWindowWithPID:(pid_t)vpnPid {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:.2f];
        CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
        NSArray* arr = CFBridgingRelease(windowList);
        
        // Loop through the windows
        for (NSMutableDictionary* entry in arr)
        {
            // Get window PID
            pid_t pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
            
            
            // Look for the VPN Connection window
            if (vpnPid == pid) {
                // Get AXUIElement using PID
                AXUIElementRef appRef = AXUIElementCreateApplication(pid);
                
                // Get the windows
                CFArrayRef windowList;
                AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
                if ((!windowList) || CFArrayGetCount(windowList)<1)
                    continue;
                
                // Get the first window
                AXUIElementRef windowRef = (AXUIElementRef) CFArrayGetValueAtIndex(windowList, 0);
                
                CFIndex objectChildrenCount;
                AXError axErr = AXUIElementGetAttributeValueCount(windowRef, kAXChildrenAttribute, &objectChildrenCount);
                assert(kAXErrorSuccess == axErr);
                CFArrayRef objectChildren;
                axErr = AXUIElementCopyAttributeValues(windowRef, kAXChildrenAttribute, 0, objectChildrenCount, &objectChildren);
                assert(kAXErrorSuccess == axErr);
                assert(CFArrayGetCount(objectChildren) == objectChildrenCount);
                
                // Loop through the children elements of the window
                for (CFIndex i = 0; i < objectChildrenCount; ++i) {
                    AXUIElementRef objectChild = CFArrayGetValueAtIndex(objectChildren, i);
                    
                    CFStringRef role = [self getStringRoleFrom:objectChild];
                    if (kCFCompareEqualTo == CFStringCompare(role, kAXStaticTextRole, 0)) {
                        CFTypeRef text;
                        AXUIElementCopyAttributeValue(objectChild, kAXValueAttribute, &text);
                        NSString *textStr = (__bridge NSString*)text;
                        
                        // Search for label with "VPN Connection" text to determine whether it is really the VPN Connection window
                        if ([textStr isEqualToString:@"VPN Connection"]) {
                            // We found VPN Connection window
                            AXUIElementRef textFieldObject = CFArrayGetValueAtIndex(objectChildren, 7);
                            CFStringRef textFieldRole = [self getStringRoleFrom:textFieldObject];
                            if (kCFCompareEqualTo == CFStringCompare(textFieldRole, kAXTextFieldRole, 0)) {
                                // Fill password
                                textStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"vpnPasswordKeyPath"];
                                AXUIElementSetAttributeValue(textFieldObject, kAXValueAttribute, (__bridge CFTypeRef _Nonnull)(textStr));
                                
                                [NSThread sleepForTimeInterval:0.1f];
                                
                                // Click OK
                                AXUIElementRef buttonObject = CFArrayGetValueAtIndex(objectChildren, 3);
                                role = [self getStringRoleFrom:buttonObject];
                                if (kCFCompareEqualTo == CFStringCompare(role, kAXButtonRole, 0)) {
                                    AXUIElementPerformAction(buttonObject, kAXPressAction);
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate finishedFillPassword];
                                });
                                
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate finishedFillPassword];
        });
    });
    

}

- (CFStringRef)getStringRoleFrom:(AXUIElementRef)element {
    CFTypeRef typeRef;
    AXError axErr = AXUIElementCopyAttributeValue(element, kAXRoleAttribute, &typeRef);
    assert(kAXErrorSuccess == axErr);
    assert([(__bridge id)typeRef isKindOfClass:[NSString class]]);
    CFStringRef role = (CFStringRef)typeRef;
    return role;
}

- (void) onActivate:(NSNotification*)event {
    NSRunningApplication *app = [[event userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    if ([app.bundleIdentifier isEqual: @"com.apple.UserNotificationCenter"]) {
        [self.delegate startedFillPassword];
        [self fillPasswordForVPNWindowWithPID:app.processIdentifier];
    }
}


- (void) startWatchingToFillVPNPassword {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onActivate:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void) dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end
