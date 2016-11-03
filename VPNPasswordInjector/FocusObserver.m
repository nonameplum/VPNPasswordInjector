//
//  CurrentApplicationState.m
//  VIntage
//
//  Created by Sean Hess on 11/5/11.
//  Copyright (c) 2011 I.TV. All rights reserved.
//

// Detect Application Starting or Quitting - Process Manager or NSWorkspace
// NSRunningApplication - http://developer.apple.com/library/mac/#documentation/AppKit/Reference/NSRunningApplication_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40008799
// NSWorkspace - runningApplications - NSWorkspaceDidLaunchApplicationNotification, NSWorkspaceWillLaunchApplicationNotification. - event contains: NSWorkspaceApplicationKey with NSRunningApplicaiton information
// NSRunningApplication currentApplication
// NSWorkspaceDidActivateApplicationNotification
// NSWorkspaceDidDeactivateApplicationNotification

// http://stackoverflow.com/questions/853833/how-can-my-app-detect-a-change-to-another-apps-window
// AXObserverAddNotification(myObserver, thirdAppElement, kAXApplicationDeactivatedNotification, NULL)
// AXObserverAddNotification(<#AXObserverRef observer#>, <#AXUIElementRef element#>, <#CFStringRef notification#>, <#void *refcon#>)

// kAXApplicationActivatedNotification -- I could use it to detect when MY applications activate / deactivate?
// http://www.monkeybreadsoftware.net/example-macosx-accessibilityservices-activewindowlogging.shtml

// Also need to detect

#import "FocusObserver.h"

void MyAXObserverCallback( AXObserverRef observer, AXUIElementRef element,
                          CFStringRef notificationName, void * contextData )
{
    // handle the notification appropriately
    // when using ObjC, your contextData might be an object, therefore you can do:
    //    SomeObject * obj = (SomeObject *) contextData;
    // now do something with obj
}

@implementation FocusObserver

- (void) fillPasswordForVPNWindowWithPID:(pid_t)vpnPid {
    [NSThread sleepForTimeInterval:.2f];
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    NSArray* arr = CFBridgingRelease(windowList);
    // Loop through the windows
    for (NSMutableDictionary* entry in arr)
    {
        // Get window PID
        pid_t pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
        
        if (vpnPid == pid) {
            // Get AXUIElement using PID
            AXUIElementRef appRef = AXUIElementCreateApplication(pid);
            
            // Get the windows
            CFArrayRef windowList;
            AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
            if ((!windowList) || CFArrayGetCount(windowList)<1)
                continue;
            
            // Get just the first window for now
            AXUIElementRef windowRef = (AXUIElementRef) CFArrayGetValueAtIndex(windowList, 0);
            
            //////////////////////////////////////////////////////////////////////////
            {
                CFIndex objectChildrenCount;
                AXError axErr = AXUIElementGetAttributeValueCount(windowRef, kAXChildrenAttribute, &objectChildrenCount);
                assert(kAXErrorSuccess == axErr);
                CFArrayRef objectChildren;
                axErr = AXUIElementCopyAttributeValues(windowRef, kAXChildrenAttribute, 0, objectChildrenCount, &objectChildren);
                assert(kAXErrorSuccess == axErr);
                assert(CFArrayGetCount(objectChildren) == objectChildrenCount);
                
                for (CFIndex i = 0; i < objectChildrenCount; ++i) {
                    AXUIElementRef objectChild = CFArrayGetValueAtIndex(objectChildren, i);
                    
                    CFStringRef role = [self getStringRoleFrom:objectChild];
                    if (kCFCompareEqualTo == CFStringCompare(role, kAXStaticTextRole, 0)) {
                        CFTypeRef text;
                        AXUIElementCopyAttributeValue(objectChild, kAXValueAttribute, &text);
                        NSString *textStr = (__bridge NSString*)text;
                        // Search for label with VPN Connection text
                        if ([textStr isEqualToString:@"VPN Connection"]) {
                            // We found VPN Connection window
                            AXUIElementRef textFieldObject = CFArrayGetValueAtIndex(objectChildren, 7);
                            role = [self getStringRoleFrom:textFieldObject];
                            if (kCFCompareEqualTo == CFStringCompare(role, kAXTextFieldRole, 0)) {
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
                                
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
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
        NSLog(@"Found VPN window");
        [self fillPasswordForVPNWindowWithPID:app.processIdentifier];
    }
}


- (void) startObservingApplicationsActivation {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onActivate:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void) dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end
