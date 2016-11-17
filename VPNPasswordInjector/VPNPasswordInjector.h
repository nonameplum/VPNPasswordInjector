//
//  VPNPasswordInjector.h
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 02/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@protocol VPNPasswordInjectorDelegate <NSObject>

- (void)startedFillPassword;
- (void)finishedFillPassword;

@end

@interface VPNPasswordInjector : NSObject

@property (weak) id<VPNPasswordInjectorDelegate> delegate;

- (void) startWatchingToFillVPNPassword;

@end
