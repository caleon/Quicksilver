//
// QSTask.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 6/29/05. Adapted by Florian Heckl on 20/08/10.
//

#import "QSTask.h"
#import "QSTaskController.h"
#import "QSTaskView.h"

@interface QSTask (PRIVATE)

-(id)initWithIdentifier:(NSString *)newIdentifier;

@end

static NSMutableDictionary *tasksDictionary = nil;

@implementation QSTask

+ (void) load {
	tasksDictionary = [[NSMutableDictionary alloc] init];
}

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"indeterminateProgress"] || [key isEqualToString:@"animateProgress"]) {
        keyPaths = [keyPaths setByAddingObject:@"progress"];
    }
    return keyPaths;
}

+ (QSTask *)taskWithIdentifier:(NSString *)identifier {
	QSTask *task = [tasksDictionary objectForKey:identifier];
	if (!task)
		task = [[[QSTask alloc] initWithIdentifier:identifier] autorelease];
	return [[task retain] autorelease];
}

+ (QSTask *)findTaskWithIdentifier:(NSString *)identifier {
	QSTask *task = [tasksDictionary objectForKey:identifier];
	return task;
}
//- (NSScriptObjectSpecifier *)objectSpecifier
// {
////	NSIndexSpecifier *specifier = [[NSIndexSpecifier alloc]
////	 initWithContainerClassDescription:
////		(NSScriptClassDescription *)[myContainer classDescription]
////					 containerSpecifier: [myContainer objectSpecifier]
////									key: @"foobazi"];
////	[specifier setIndex: [myContainer indexOfObjectInFoobazi: self]];
////	return [specifier autorelease];
//	NSLog(@"specifier");
//	return nil;
//}

- (NSString *)nameAndStatus {
	//NSLog(@"stat %@", [self name]);
	return [self name];
}
- (NSImage *)icon {
	if (!icon && delegate && [delegate respondsToSelector:@selector(iconForTask:)])
		[self setIcon:[delegate iconForTask:self]];
	if (!icon) return [NSImage imageNamed:@"NSApplicationIcon"];
	return icon;
}
- (NSString *)description {
	return [NSString stringWithFormat:@"[%@:%@:%@ %lu] ", identifier, name, status, (unsigned long)[self retainCount]];
}
- (id)init {
	return [self initWithIdentifier:nil];
}
- (id)initWithIdentifier:(NSString *)newIdentifier {
	self = [super initWithNibName:@"QSTaskEntry" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		[self setIdentifier:newIdentifier];
	}
	return self;
}

- (void)dealloc {
    // !!! Andre Berg 20091007: doesn't seem that there are many QSTasks with a name or status. 
    // So the logging statements do not make much sense really if we get "(null)" for all parameters
    // I will disable them for now since they don't provide useful info
    
    [identifier release], identifier = nil;

	[self setName:nil];
	[self setStatus:nil];
	[self setResult:nil];
	[self setCancelTarget:nil];
	[self setSubtasks:nil];
	[super dealloc];
}

- (void)cancel:(id)sender {
	if (cancelTarget) {
		NSLog(@"Cancel Task: %@", self);
		[cancelTarget performSelector:cancelAction withObject:sender];
	}
}

- (BOOL)isRunning {
	return running;
}
- (void)startTask:(id)sender {
	
#ifdef DEBUG
    if (VERBOSE) NSLog(@"Start Task: %@", self);
#endif
	
	if (!running) {
		running = YES;
		[QSTasks taskStarted:self];
		//[QSTasks performSelectorOnMainThread:@selector(taskStarted:) withObject:self waitUntilDone:NO];
	}
}
- (void)stopTask:(id)sender {
	if (running) {
		
#ifdef DEBUG
		if (VERBOSE) NSLog(@"End Task: %@ %lu", [self identifier], (unsigned long)[self retainCount]);
#endif
		
		running = NO;
		[QSTasks taskStopped:self];
	}
	if (identifier != nil) {
		[tasksDictionary removeObjectForKey:identifier];
	}
}


// Bindings

- (BOOL)animateProgress {
	return progress<0;
}

- (BOOL)indeterminateProgress {
	return progress<0;
}
- (BOOL)canBeCancelled {
	return cancelAction != nil;
}



#pragma mark -
#pragma mark Accessors
// Accessors



- (NSString *)identifier {
	return identifier;
}
- (void)setIdentifier:(NSString *)value {
	if (identifier != value) {
		NSString *oldIdentifier = [identifier copy];
		[identifier release];
		identifier = [value copy];
		if (tasksDictionary) {
			if (value) {
				[tasksDictionary setObject:self forKey:value];
			}
			if (oldIdentifier) {
				[tasksDictionary removeObjectForKey:oldIdentifier];
			} 
		}
		[oldIdentifier release];
	}
}

- (NSString *)name {
	if (!name) return [self identifier];
	return name;
}

- (void)setName:(NSString *)value {
    runOnMainQueueSync(^{
        if (name != value) {
            [name release];
            name = [value copy];
        }
    });
}

- (NSString *)status {
	return status;
}

- (void)setStatus:(NSString *)value {
    runOnMainQueueSync(^{
        if (status != value) {
            [status release];
            status = [value copy];
        }
    });
}

- (CGFloat) progress {
	return progress;
}
- (void)setProgress:(CGFloat)value {
    runOnMainQueueSync(^{
        if (progress != value) {
            progress = value;
        }
    });
}

- (QSObject *)result {
	return result;
}
- (void)setResult:(QSObject *)value {
	if (result != value) {
		[result release];
		result = [value copy];
	}
}

- (SEL) cancelAction {
	return cancelAction;
}

- (void)setCancelAction:(SEL)value {
    runOnMainQueueSync(^{
        cancelAction = value;
    });
}

- (id)cancelTarget {
	return cancelTarget;
}
- (void)setCancelTarget:(id)value {
	if (cancelTarget != value) {
		[cancelTarget release];
		cancelTarget = [value retain];
	}
}

- (BOOL)showProgress {
	return showProgress;
}

- (void)setShowProgress:(BOOL)value {
	if (showProgress != value) {
		showProgress = value;
	}
}

- (NSArray *)subtasks {
	return nil;
	return subtasks;
}

- (void)setSubtasks:(NSArray *)value {
	if (subtasks != value) {
		[subtasks release];
		subtasks = [value copy];
	}
}

- (void)setIcon:(NSImage *)newIcon {
    runOnMainQueueSync(^{
        if (icon != newIcon) {
            [icon release];
            icon = [newIcon retain];
        }
    });
}


- (id)delegate { return delegate;  }
- (void)setDelegate:(id)newDelegate {
	if (delegate != newDelegate) {
		[delegate release];
		delegate = [newDelegate retain];
	}
}

@end
