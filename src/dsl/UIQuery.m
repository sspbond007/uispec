
#import "UIQuery.h"
#import "objc/runtime.h"
#import "UIDescendants.h"
#import "UIChildren.h"
#import "UIParents.h"
#import "WaitUntilIdle.h"
#import "UIRedoer.h"
#import "UIQueryTableViewCell.h"
#import "UIQueryTableView.h"
#import "UIQuerySearchBar.h"
#import "UIQueryTabBar.h"
#import "UIQuerySegmentedControl.h"
#import "UIQueryWebView.h"
#import "UIQueryAll.h"
#import "UIFilter.h"
#import "UIBug.h"
#import "UIQueryExpectation.h"

@implementation UIQuery

@synthesize with;
@synthesize should;
@synthesize parent, child, descendant, find;
@synthesize touch, flash, show, path, inspect;
@synthesize timeout;
@synthesize views;
@synthesize className;
@synthesize redoer;
@synthesize first, last, all, redo;
@synthesize exists;

static int defaultTimeout = 10;

+(id)withApplicationAndDefaultTimeout:(int)seconds {
    defaultTimeout = seconds;
	return [self withViews:[NSMutableArray arrayWithObject:[UIApplication sharedApplication]] className:NSStringFromClass([UIApplication class])];
}

+(id)withApplication {
	return [self withViews:[NSMutableArray arrayWithObject:[UIApplication sharedApplication]] className:NSStringFromClass([UIApplication class])];
}

-(UIQuery *)find {
	return [self descendant];
}

-(UIQuery *)descendant {
	[self wait:.25];
	return [UIQuery withViews:[[UIDescendants withTraversal] collect:views] className:className filter:YES];
}

-(UIQuery *)child {
	[self wait:.25];
	return [UIQuery withViews:[[UIChildren withTraversal] collect:views] className:className filter:YES];
}

-(UIQuery *)parent {
	[self wait:.25];
	return [UIQuery withViews:[[UIParents withTraversal] collect:views] className:className filter:YES];
}

-(UIQueryExpectation *)should {
	return [UIQueryExpectation withQuery:self];
}

-(UIFilter *)with {
	return [UIFilter withQuery:self];
}

+(id)withViews:(NSMutableArray *)views className:(NSString *)className {
	return [UIQuery withViews:views className:className filter:NO];
}

+(id)withViews:(NSMutableArray *)views className:(NSString *)className filter:(BOOL)filter {
    if ([className isEqualToString:@"UITableViewCell"]) {
		return [UIRedoer withTarget:[[[UIQueryTableViewCell alloc] initWithViews:views className:className filter:filter] autorelease]];
    }
    else if ([className isEqualToString:@"UITableView"]) {
		return [UIRedoer withTarget:[[[UIQueryTableView alloc] initWithViews:views className:className filter:filter] autorelease]];
    }
	else if ([className isEqualToString:@"UISearchBar"]) {
		return [UIRedoer withTarget:[[[UIQuerySearchBar alloc] initWithViews:views className:className filter:filter] autorelease]];
    }
	else if ([className isEqualToString:@"UITabBar"]) {
		return [UIRedoer withTarget:[[[UIQueryTabBar alloc] initWithViews:views className:className filter:filter] autorelease]];
	}
	else if ([className isEqualToString:@"UISegmentedControl"]) {
		return [UIRedoer withTarget:[[[UIQuerySegmentedControl alloc] initWithViews:views className:className filter:filter] autorelease]];
	}
	else if ([className isEqualToString:@"UIWebView"]) {
		return [UIRedoer withTarget:[[[UIQueryWebView alloc] initWithViews:views className:className filter:filter] autorelease]];
	}
	else {
		return [UIRedoer withTarget:[[[UIQuery alloc] initWithViews:views className:className filter:filter] autorelease]];
	}
}

-(id)initWithViews:(NSMutableArray *)_views className:(NSString *)_className filter:(BOOL)_filter {
	if (self = [super init]) {
		self.timeout = defaultTimeout;
		self.views = _views;
		self.className = _className;
		filter = _filter;
	}
	return self;
}

-(NSArray *)collect:(NSArray *)_views {
	return [[[[UIDescendants alloc] init] autorelease] collect:_views];
}

-(UIQuery *)target {
	return self;
}

-(NSArray *)targetViews {
	return (views.count == 0) ? [NSArray array] : [NSArray arrayWithObject:[views objectAtIndex:0]];
}

-(UIQuery *)timeout:(int)seconds {
	UIQuery *copy = [UIQuery withViews:views className:className];
	copy.timeout = seconds;
	return copy;
}

-(id)templateFilter {
	NSString *viewName = NSStringFromSelector(_cmd);
	return [self view:[NSString stringWithFormat:@"UI%@", [viewName stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[viewName substringWithRange:NSMakeRange(0,1)] uppercaseString]]]];
}

-(UIQuery *)index:(int)index {
	if (index >= views.count) {
		NSLog(@"UISPEC WARNING: %@ doesn't exist at index %i", className, index);
	}
	NSArray *resultViews = (index >= views.count) ? [NSArray array] : [NSArray arrayWithObject:[views objectAtIndex:index]];
	return [UIQuery withViews:resultViews className:className];
}

-(UIQuery *)first {
	return [self index:0];
}

-(UIQuery *)last {
	return [self index:views.count - 1];
}

-(UIQuery *)all {
	return [UIQueryAll withViews:views className:className];
}

-(UIQuery *)view:(NSString *)className {
	NSMutableArray *array = [NSMutableArray array];
	NSDate *start = [NSDate date];
	while ([start timeIntervalSinceNow] > (0 - timeout)) {
		NSArray *views = filter ? self.views : self.descendant.views;
		Class class = NSClassFromString(className);
		for (UIView * v in views) {
			if ([v isKindOfClass:class]) {
				[array addObject:v];
			} 
		}
		if (array.count > 0) {
			break;
		}
		self.redo;
	}
    return [UIQuery withViews:array className:className];
}

-(UIQuery *)marked:(NSString *)mark {
	return [self.with accessibilityLabel:mark];
}
 
-(UIQuery *)wait:(double)seconds {
    //NSLog(@"WAITING %d", seconds);
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, seconds, false);
	return [UIQuery withViews:views className:className];
}

-(id)redo {
	//NSLog(@"UIQuery redo");
	if (redoer != nil) {
		//NSLog(@"UIQuery redo redoer = %@", redoer);
		UIRedoer *redone = [redoer redo];
		redoer.target = redone.target;
		self.views = [[redoer play] views];
	}
	//return is provided by uiredoer
}

-(BOOL)exists {
	return [self targetViews].count > 0;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //NSLog(@"UIQuery methodSignatureForSelector %@", NSStringFromSelector(aSelector));
	if ([UIQuery instancesRespondToSelector:aSelector]) {
        //NSLog(@"UIQuery instancesRespondToSelector %@", NSStringFromSelector(aSelector));
		return [super methodSignatureForSelector:aSelector];
	}
	
	[[UIQueryExpectation withQuery:self] exist:[NSString stringWithFormat:@"before you can call %@", NSStringFromSelector(aSelector)]];
	NSString *selector = NSStringFromSelector(aSelector);
	
	for (UIView *target in [self targetViews]) {
		if ([target respondsToSelector:aSelector]) {
            //NSLog(@"UIQuery target respondsToSelector");
			return [target methodSignatureForSelector:aSelector];
		}
	}
	
	//Check if any view responds as a property match
	NSArray *selectors = [selector componentsSeparatedByString:@":"];
	if (selectors.count > 1) {
		return [self.with methodSignatureForSelector:aSelector];
	}
	return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    //NSLog(@"UIQuery forwardInvocation");
	BOOL isDirect = NO;
	for (UIView *target in [self targetViews]) {
		if ([target respondsToSelector:[anInvocation selector]]) {
            //NSLog(@"UIQuery target respondsToSelector");
			[anInvocation invokeWithTarget:target];
			isDirect = YES;
		}
	}
	//NSLog(@"UIQuery forwardInvocation isDirect=%d",isDirect);
	if (!isDirect) {
		[[[UIRedoer withTarget:self] with] forwardInvocation:anInvocation];
	}
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    //NSLog(@"UIQuery respondsToSelector");
	if ([UIQuery instancesRespondToSelector:aSelector]) {
		return YES;
	}
	for (UIView *target in [self targetViews]) {
		if ([target respondsToSelector:aSelector]) {
			return YES;
		}
	}
	return [super respondsToSelector:aSelector];
}

-(UIQuery *)flash {
	[[UIQueryExpectation withQuery:self] exist:@"before you can flash it"];
	for (UIView *view in [self targetViews]) {
		UIColor *tempColor = [view.backgroundColor retain];
		for (int i=0; i<5; i++) {
			view.backgroundColor = [UIColor yellowColor];
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
			view.backgroundColor = [UIColor blueColor];
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
		}
		view.backgroundColor = tempColor;
		[tempColor release];
	}
	return [UIQuery withViews:views className:className];
}

-(UIQuery *)show {
	//NSLog(@"calling show");
	[[UIQueryExpectation withQuery:self] exist:@"before you can show it"];
	[UIQuery show:[self targetViews]];
	return [UIQuery withViews:views className:className];
}

-(UIQuery *)path {
	[[UIQueryExpectation withQuery:self] exist:@"before you can show its path"];
	for (UIView *view in [self targetViews]) {
		NSMutableString *path = [NSMutableString stringWithString:@"\n"];
		NSArray *parentViews = [[UIParents withTraversal] collect:[NSArray arrayWithObject:view]];
		for (int i = parentViews.count-1; i>=0; i--) {
			[path appendFormat:@"%@ -> ", [[parentViews objectAtIndex:i] class]];
		}
		[path appendFormat:@"%@", [view class]];
		NSLog(path);
	}
	return [UIQuery withViews:views className:className]; 
}

-(UIQuery *)inspect {
	[UIBug openInspectorWithView:[views objectAtIndex:0]];
	return [UIQuery withViews:views className:className]; 
}

+(void)show:(NSArray *)views {
	for (UIView *view in views) {
		NSMutableDictionary *dict = [self describe:view];
		if ([dict allKeys].count > 0) {
			NSLog(@"\nClass: %@ \n%@", [view class], [dict description]);
		}
	}
}

+(NSDictionary *)describe:(id)object {
	//NSLog(@"describing object %@", object);
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	Class clazz = [object class];
	do {
		//NSLog(@"describing class %@", NSStringFromClass(clazz));
		unsigned i;
		id objValue;
		int intValue;
		long longValue;
		char *charPtrValue;
		char charValue;
		short shortValue;
		float floatValue;
		double doubleValue;
		
		int propertyCount = 0;
		objc_property_t *propertyList = class_copyPropertyList(clazz, &propertyCount);
		//NSLog(@"property count = %d", propertyCount);
		for (i=0; i<propertyCount; i++) {
			objc_property_t *thisProperty = propertyList + i;
			const char* propertyName = property_getName(*thisProperty);
			const char* propertyAttributes = property_getAttributes(*thisProperty);
			
			NSString *key = [NSString stringWithFormat:@"%s", propertyName];
			NSString *keyAttributes = [NSString stringWithFormat:@"%s", propertyAttributes];
			//NSLog(@"key = %@", key);
			//NSLog(@"keyAttributes = %@", keyAttributes);
			
			NSArray *attributes = [keyAttributes componentsSeparatedByString:@","];
			if ([[[attributes lastObject] substringToIndex:1] isEqualToString:@"G"]) {
				key = [[attributes lastObject] substringFromIndex:1];
			}
			
			SEL selector = NSSelectorFromString(key);
			if ([object respondsToSelector:selector]) {
				NSMethodSignature *sig = [object methodSignatureForSelector:selector];
				//NSLog(@"sig = %@", sig);
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
				[invocation setSelector:selector];
				//NSLog(@"invocation selector = %@", NSStringFromSelector([invocation selector]));
				[invocation setTarget:object];
				
				@try {
					[invocation invoke];
				}
				@catch (NSException *exception) {
					NSLog(@"UIQuery.describe caught %@: %@", [exception name], [exception reason]);
					continue;
				}
				
				const char* type = [[invocation methodSignature] methodReturnType];
				NSString *returnType = [NSString stringWithFormat:@"%s", type];
				const char* trimmedType = [[returnType substringToIndex:1] cStringUsingEncoding:NSASCIIStringEncoding];
				//NSLog(@"return type = %@", returnType);
				switch(*trimmedType) {
					case '@':
						[invocation getReturnValue:(void **)&objValue];
						if (objValue == nil) {
							[properties setObject:[NSString stringWithFormat:@"%@", objValue] forKey:key];
						} else {
							[properties setObject:objValue forKey:key];
						}
						break;
					case 'i':
						[invocation getReturnValue:(void **)&intValue];
						[properties setObject:[NSString stringWithFormat:@"%i", intValue] forKey:key];
						break;
					case 's':
						[invocation getReturnValue:(void **)&shortValue];
						[properties setObject:[NSString stringWithFormat:@"%ud", shortValue] forKey:key];
						break;
					case 'd':
						[invocation getReturnValue:(void **)&doubleValue];
						[properties setObject:[NSString stringWithFormat:@"%lf", doubleValue] forKey:key];
						break;
					case 'f':
						[invocation getReturnValue:(void **)&floatValue];
						[properties setObject:[NSString stringWithFormat:@"%f", floatValue] forKey:key];
						break;
					case 'l':
						[invocation getReturnValue:(void **)&longValue];
						[properties setObject:[NSString stringWithFormat:@"%ld", longValue] forKey:key];
						break;
					case '*':
						[invocation getReturnValue:(void **)&charPtrValue];
						[properties setObject:[NSString stringWithFormat:@"%s", charPtrValue] forKey:key];
						break;
					case 'c':
						[invocation getReturnValue:(void **)&charValue];
						[properties setObject:[NSString stringWithFormat:@"%d", charValue] forKey:key];
						break;
					case '{': {
						unsigned int length = [[invocation methodSignature] methodReturnLength];
						void *buffer = (void *)malloc(length);
						[invocation getReturnValue:buffer];
						NSValue *value = [[[NSValue alloc] initWithBytes:buffer objCType:type] autorelease];
						[properties setObject:value forKey:key];
						break;
					}
				}
			}
		}
	} while ((clazz = class_getSuperclass(clazz)) != nil);
    return properties;
}

- (UIQuery *)touch {
	[[UIQueryExpectation withQuery:self] exist:@"before you can touch it"];
	
	for (UIView *view in [self targetViews]) {
		UITouch *touch = [[UITouch alloc] initInView:view];
		UIEvent *eventDown = [[NSClassFromString(@"UITouchesEvent") alloc] initWithTouch:touch];
		NSSet *touches = [[NSMutableSet alloc] initWithObjects:&touch count:1];
		
		[touch.view touchesBegan:touches withEvent:eventDown];
		
		UIEvent *eventUp = [[NSClassFromString(@"UITouchesEvent") alloc] initWithTouch:touch];
		[touch setPhase:UITouchPhaseEnded];
		
		[touch.view touchesEnded:touches withEvent:eventDown];
		
		[eventDown release];
		[eventUp release];
		[touches release];
		[touch release];
		[self wait:.5];
	}
	return [UIQuery withViews:views className:className];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@", [views description]];
}

-(void)logRange:(NSString *)prefix range:(NSRange)range {
	NSLog(@"%@ location = %d, length = %d", prefix, range.location, range.length);
}

-(void)dealloc {
	self.views = nil;
	self.className = nil;
	self.redoer = nil;
	[super dealloc];
}

@end

//
//  TouchSynthesis.m
//  SelfTesting
//
//  Created by Matt Gallagher on 23/11/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

@interface UITouch () {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    // ivars declarations removed in 6.0
    NSTimeInterval  _timestamp;
    UITouchPhase    _phase;
    UITouchPhase    _savedPhase;
    NSUInteger      _tapCount;
    
    UIWindow        *_window;
    UIView          *_view;
    UIView          *_gestureView;
    UIView          *_warpedIntoView;
    NSMutableArray  *_gestureRecognizers;
    NSMutableArray  *_forwardingRecord;
    
    CGPoint         _locationInWindow;
    CGPoint         _previousLocationInWindow;
    UInt8           _pathIndex;
    UInt8           _pathIdentity;
    float           _pathMajorRadius;
    struct {
        unsigned int _firstTouchForView:1;
        unsigned int _isTap:1;
        unsigned int _isDelayed:1;
        unsigned int _sentTouchesEnded:1;
        unsigned int _abandonForwardingRecord:1;
    } _touchFlags;
#endif
}
@end

@implementation UITouch (Synthesize)

//
// initInView:phase:
//
// Creats a UITouch, centered on the specified view, in the view's window.
// Sets the phase as specified.
//
- (id)initInView:(UIView *)view
{
	self = [super init];
	if (self != nil)
	{
		CGRect frameInWindow;
		if ([view isKindOfClass:[UIWindow class]])
		{
			frameInWindow = view.frame;
		}
		else
		{
			frameInWindow =
			[view.window convertRect:view.frame fromView:view.superview];
		}
		
		_tapCount = 1;
		_locationInWindow =
		CGPointMake(
					frameInWindow.origin.x + 0.5 * frameInWindow.size.width,
					frameInWindow.origin.y + 0.5 * frameInWindow.size.height);
		_previousLocationInWindow = _locationInWindow;
		
		UIView *target = [view.window hitTest:_locationInWindow withEvent:nil];
		
		_window = [view.window retain];
		_view = [target retain];
		_phase = UITouchPhaseBegan;
		_touchFlags._firstTouchForView = 1;
		_touchFlags._isTap = 1;
		_timestamp = [NSDate timeIntervalSinceReferenceDate];
	}
	return self;
}

//
// setPhase:
//
// Setter to allow access to the _phase member.
//
- (void)setPhase:(UITouchPhase)phase
{
	_phase = phase;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

//
// setPhase:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
	_previousLocationInWindow = _locationInWindow;
	_locationInWindow = location;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

@end

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface GSEventProxy : NSObject
{
@public
	unsigned int flags;
	unsigned int type;
	unsigned int ignored1;
	float x1;
	float y1;
	float x2;
	float y2;
	unsigned int ignored2[10];
	unsigned int ignored3[7];
	float sizeX;
	float sizeY;
	float x3;
	float y3;
	unsigned int ignored4[3];
}
@end
@implementation GSEventProxy
@end

//
// PublicEvent
//
// A dummy class used to gain access to UIEvent's private member variables.
// If UIEvent changes at all, this will break.
//
@interface PublicEvent : NSObject
{
@public
    GSEventProxy           *_event;
    NSTimeInterval          _timestamp;
    NSMutableSet           *_touches;
    CFMutableDictionaryRef  _keyedTouches;
}
@end

@implementation PublicEvent
@end

@interface UIEvent (Creation)

- (id)_initWithEvent:(GSEventProxy *)fp8 touches:(id)fp12;

@end

//
// UIEvent (Synthesize)
//
// A category to allow creation of a touch event.
//
@implementation UIEvent (Synthesize)

- (id)initWithTouch:(UITouch *)touch
{
	CGPoint location = [touch locationInView:touch.window];
	GSEventProxy *gsEventProxy = [[GSEventProxy alloc] init];
	gsEventProxy->x1 = location.x;
	gsEventProxy->y1 = location.y;
	gsEventProxy->x2 = location.x;
	gsEventProxy->y2 = location.y;
	gsEventProxy->x3 = location.x;
	gsEventProxy->y3 = location.y;
	gsEventProxy->sizeX = 1.0;
	gsEventProxy->sizeY = 1.0;
	gsEventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
	gsEventProxy->type = 3001;	
	
	//
	// On SDK versions 3.0 and greater, we need to reallocate as a
	// UITouchesEvent.
	//
	Class touchesEventClass = objc_getClass("UITouchesEvent");
	if (touchesEventClass && ![[self class] isEqual:touchesEventClass])
	{
		[self release];
		self = [touchesEventClass alloc];
	}
	
	self = [self _initWithEvent:gsEventProxy touches:[NSSet setWithObject:touch]];
	if (self != nil)
	{
	}
	return self;
}

@end


