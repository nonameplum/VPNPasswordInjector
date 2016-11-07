//
//  PLSecureTextFieldCell.m
//  VPNPasswordInjector
//
//  Created by Łukasz Śliwiński on 04/11/2016.
//  Copyright © 2016 Łukasz Śliwiński. All rights reserved.
//

#import "PLSecureTextFieldCell.h"

@implementation PLSecureTextField

+ (Class)cellClass {
    return [PLSecureTextFieldCell class];
}

@end

@implementation PLSecureTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
    // Get the parent's idea of where we should draw
    NSRect newRect = [super drawingRectForBounds:theRect];
    
    // When the text field is being
    // edited or selected, we have to turn off the magic because it screws up
    // the configuration of the field editor.  We sneak around this by
    // intercepting selectWithFrame and editWithFrame and sneaking a
    // reduced, centered rect in at the last minute.
    if (mIsEditingOrSelecting == NO)
    {
        // Get our ideal size for current text
        NSSize textSize = [self cellSizeForBounds:theRect];
        
        // Center that in the proposed rect
        float heightDelta = newRect.size.height - textSize.height;
        if (heightDelta > 0)
        {
            newRect.size.height -= heightDelta;
            newRect.origin.y += (heightDelta / 2);
        }
    }
    
    return newRect;
}

- (void)selectWithFrame:(NSRect)rect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)delegate start:(NSInteger)selStart length:(NSInteger)selLength {
    CGRect aRect = [self drawingRectForBounds:rect];
    mIsEditingOrSelecting = YES;
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:delegate start:selStart length:selLength];
    mIsEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)rect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)delegate event:(NSEvent *)event {
    CGRect aRect = [self drawingRectForBounds:rect];
    mIsEditingOrSelecting = YES;
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:delegate event:event];
    mIsEditingOrSelecting = NO;
}

@end
