//
//  RSTimerUtils.m
//  ReturnUtils
//
//  Created by Davide Di Stefano on 25/03/13.
//  Copyright (c) 2013 ReturnService. All rights reserved.
//

#import "RSTimer.h"
#include <mach/mach_time.h>

@interface RSTimer()
{
    uint64_t absoluteTimeFromLastResume;
    NSTimeInterval elapsedTime;
    NSTimer * timeStepTimer;
    BOOL isPaused;
}

@end

@implementation RSTimer

- (id)init
{
    self = [super init];
    if (self) {
        elapsedTime = 0;
        absoluteTimeFromLastResume = 0;
        self.delegate = nil;
        isPaused = YES;
    }
    return self;
}

-(id) initWithDelegate:(id<RSTimerDelegate>) delegate;
{
    self = [super init];
    if (self) {
        elapsedTime = 0;
        absoluteTimeFromLastResume = 0;
        self.delegate = delegate;
        isPaused = YES;
    }
    return self;
}

-(void) startTimer;
{
    isPaused = NO;
    absoluteTimeFromLastResume = [RSTimer getMachAbsoluteTime];
    if ([self.delegate respondsToSelector:@selector(timeStepForCallingEventForTimer:)])
    {
        NSTimeInterval timeStep = [self.delegate timeStepForCallingEventForTimer:self];
        timeStepTimer = [NSTimer timerWithTimeInterval:timeStep target:self selector:@selector(onTimeStep:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timeStepTimer forMode:NSDefaultRunLoopMode];
    }
}

-(void) pauseTimer;
{
    elapsedTime = self.elapsedTime;
    isPaused = YES;    
    [timeStepTimer invalidate];
    timeStepTimer = nil;
}

-(void) stopTimer;
{
    [timeStepTimer invalidate];
    elapsedTime = absoluteTimeFromLastResume = 0;
}

-(NSTimeInterval) elapsedTime
{
    if (isPaused)
        return elapsedTime;
    uint64_t nowTime = [RSTimer getMachAbsoluteTime];
    uint64_t timeDifference = [RSTimer nanoSecondsBetweenStartMachAbsoluteTime:absoluteTimeFromLastResume endMachAbsoluteTime:nowTime];
    uint64_t totalTimeElapsed = timeDifference + elapsedTime;
    NSTimeInterval currElapsedTime = ((double)totalTimeElapsed / 1000000);
    currElapsedTime /= 1000.0f;
    return elapsedTime + currElapsedTime;
}

-(void) onTimeStep:(NSTimer *) timer
{
    if ([self.delegate respondsToSelector:@selector(timer:timeStepForElapsedTime:)])
    {
        [self.delegate timer:self timeStepForElapsedTime:self.elapsedTime];
    }
}

// returns up-time returned from the function mach_absolute_time. This value is dependent from the clock and can't be used directly  to show time
+(uint64_t) getMachAbsoluteTime;
{
    return mach_absolute_time();
}

// returns the difference in nanoseconds bewtween 2 machAbsoluteTimes
+(uint64_t) nanoSecondsBetweenStartMachAbsoluteTime:(uint64_t) startTime endMachAbsoluteTime:(uint64_t) endTime;
{
    static mach_timebase_info_data_t sTimebaseInfo;
    
    uint64_t elapsed;
    uint64_t elapsedNano;
    
    // Calculate the duration.    
    elapsed = endTime - startTime;
    
    // Convert to nanoseconds.
    
    // If this is the first time we've run, get the timebase.
    // We can use denom == 0 to indicate that sTimebaseInfo is
    // uninitialised because it makes no sense to have a zero
    // denominator is a fraction.
    if (sTimebaseInfo.denom == 0)
    {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    
    // Do the maths. We hope that the multiplication doesn't
    // overflow; the price you pay for working in fixed point.
    elapsedNano = elapsed * sTimebaseInfo.numer / sTimebaseInfo.denom;
    
    return elapsedNano;
}

@end
