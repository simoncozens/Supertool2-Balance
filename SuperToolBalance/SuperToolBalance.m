//
//  SuperToolBalance.m
//  SuperToolBalance
//
//  Created by Simon Cozens on 13/01/2021.
//
//

#import "SuperToolBalance.h"
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>
#import <GlyphsCore/GSGlyph.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import "GSNode+SCNodeUtils.h"

@implementation SuperToolBalance

- (NSUInteger) interfaceVersion {
	// Distinguishes the API verison the plugin was built for. Return 1.
	return 1;
}

- (NSString*) title {
	// Return the name of the tool as it will appear in the menu.
	return @"SuperTool - Balance";
}

- (NSString*) keyEquivalent {
	// The key together with Cmd+Shift will be the shortcut for the filter.
	// Return nil if you do not want to set a shortcut.
	// Users can set their own shortcuts in System Prefs.
	return @"E";
}

- (void) setController:(NSViewController <GSGlyphEditViewControllerProtocol>*)Controller {
    // Use [self controller]; as object for the current view controller.
    controller = Controller;
}

-(void) addNode:(GSNode*)n toSegmentSet:(NSMutableOrderedSet*) segments {
    // Find the segment for this node and add it to the set
    if ([n type] == OFFCURVE && [[n nextNode] type] == OFFCURVE) {
        // Add prev, this, next, and next next to the set
        NSArray* a = [NSArray arrayWithObjects:[n prevNode],n,[n nextNode],[[n nextNode] nextNode],nil];
        [segments addObject:a];
    } else if ([n type] == OFFCURVE && [[n prevNode] type] == OFFCURVE) {
        // Add prev prev, prev, this and next to the set
        NSArray* a = [NSArray arrayWithObjects:[[n prevNode] prevNode],[n prevNode],n,[n nextNode],nil];
        [segments addObject:a];
    }
}

- (BOOL)runFilterWithLayer:(GSLayer *)layer error:(out NSError **)error {
    NSMutableOrderedSet* segments = [[NSMutableOrderedSet alloc] init];
    GSNode* n;
    if ([[layer selection] count] > 0) {
        for (n in [layer selection]) {
            if (![n isKindOfClass:[GSNode class]]) continue;
            [self addNode:n toSegmentSet:segments];
        }
    } else {
        // Everything
        for (GSPath* p in [layer paths]) {
            for (GSNode* n in [p nodes]) {
                [self addNode:n toSegmentSet:segments];
            }
        }
    }
    NSArray* seg;
    for (seg in segments) {
        NSPoint p1 = [(GSNode*)seg[0] position];
        NSPoint p2 = [(GSNode*)seg[1] position];
        NSPoint p3 = [(GSNode*)seg[2] position];
        NSPoint p4 = [(GSNode*)seg[3] position];
        NSPoint t = GSIntersectLineLineUnlimited(p1,p2,p3,p4);
        CGFloat sDistance = GSDistance(p1,t);
        CGFloat eDistance = GSDistance(p4, t);
        if (sDistance <= 0 || eDistance <= 0) continue;
        CGFloat xPercent = GSDistance(p1,p2) / sDistance;
        CGFloat yPercent = GSDistance(p3,p4) / eDistance;
        if (xPercent > 1 && yPercent >1) continue; // Inflection point
        if (xPercent < 0.01 && yPercent <0.01) continue; // Inflection point
        CGFloat avg = (xPercent+yPercent)/2.0;
        NSPoint newP2 = GSLerp(p1, t, avg);
        NSPoint newP3 = GSLerp(p4, t, avg);
        [(GSNode*)seg[1] setPosition:newP2];
        [(GSNode*)seg[2] setPosition:newP3];
    }
    return YES;
}

- (BOOL)runFilterWithLayer:(GSLayer *)Layer options:(NSDictionary *)options error:(out NSError *__autoreleasing *)error {
    return [self runFilterWithLayer:Layer error:error];
}


- (BOOL)runFilterWithLayers:(NSArray *)Layers error:(out NSError *__autoreleasing *)error {
    return NO;

}


- (NSError *)setup {
    return nil;
}


@synthesize controller;

@end
