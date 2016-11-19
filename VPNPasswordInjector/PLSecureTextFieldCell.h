//
//  PLSecureTextFieldCell.h
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 04/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PLSecureTextField : NSSecureTextField

@end

@interface PLSecureTextFieldCell : NSSecureTextFieldCell {
    BOOL mIsEditingOrSelecting;
}

@end
