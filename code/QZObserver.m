//
//  QZObserver.m
//  QZObserver
//
//  Created by Mark Schultz on 1/23/14.
//  Copyright (c) 2014 QZero Labs, LLC. All rights reserved.
//

#import "QZObserver.h"

@interface QZObserverMetadata : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, assign) void *context;

@end

@implementation QZObserverMetadata

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[QZObserverMetadata class]])
    {
        QZObserverMetadata *metadata = object;
        if (metadata.observer == self.observer)
        {
            if (metadata.context == self.context)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

@end




@interface QZObserver()

@property (nonatomic, strong) NSMapTable *observedObjects;

@end

@implementation QZObserver

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.observedObjects = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}



#pragma mark - Observer handling
- (void)addObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    if (!object)
    {
        return;
    }
    
    @synchronized (self.observedObjects)
    {
        NSMutableDictionary *dictionary = [self.observedObjects objectForKey:object];
        if (!dictionary)
        {
            dictionary = [NSMutableDictionary dictionary];
            [self.observedObjects setObject:dictionary forKey:object];
        }
        
        NSMutableSet *set = [dictionary objectForKey:keyPath];
        if (!set)
        {
            set = [NSMutableSet set];
            [dictionary setObject:set forKey:keyPath];
        }
        
        __block BOOL found = NO;
        [set enumerateObjectsUsingBlock:^(QZObserverMetadata *metadata, BOOL *stop) {
            if (metadata.observer == observer && metadata.context == context)
            {
                found = YES;
                *stop = YES;
                return;
            }
        }];
        
        if (!found)
        {
            QZObserverMetadata *metadata = [QZObserverMetadata new];
            metadata.observer = observer;
            metadata.context = context;
            [set addObject:metadata];
            
            [object addObserver:self forKeyPath:keyPath options:options context:context];
        }
    }
}


- (void)removeObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath
{
    @synchronized (self.observedObjects)
    {
        NSMutableDictionary *dictionary = [self.observedObjects objectForKey:object];
        if (dictionary)
        {
            NSMutableSet *set = [dictionary objectForKey:keyPath];
            if (set)
            {
                NSMutableSet *setCopy = [set mutableCopy];
                [setCopy enumerateObjectsUsingBlock:^(QZObserverMetadata *metadata, BOOL *stop) {
                    if (metadata.observer == observer)
                    {
                        [set removeObject:metadata];
                        [object removeObserver:self forKeyPath:keyPath];
                    }
                }];
                
                if (set.count == 0)
                {
                    [dictionary removeObjectForKey:keyPath];
                }
            }
        }
        
        if (dictionary.count == 0)
        {
            [self.observedObjects removeObjectForKey:object];
        }
    }
}


- (void)removeObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath context:(void *)context
{
    @synchronized (self.observedObjects)
    {
        NSMutableDictionary *dictionary = [self.observedObjects objectForKey:object];
        if (dictionary)
        {
            NSMutableSet *set = [dictionary objectForKey:keyPath];
            if (set)
            {
                NSMutableSet *setCopy = [set mutableCopy];
                [setCopy enumerateObjectsUsingBlock:^(QZObserverMetadata *metadata, BOOL *stop) {
                    if (metadata.observer == observer && metadata.context == context)
                    {
                        [set removeObject:metadata];
                        [object removeObserver:self forKeyPath:keyPath context:context];
                        *stop = YES;
                        return;
                    }
                }];
                
                if (set.count == 0)
                {
                    [dictionary removeObjectForKey:keyPath];
                }
            }
        }
        
        if (dictionary.count == 0)
        {
            [self.observedObjects removeObjectForKey:object];
        }
    }
}



#pragma mark - KVO observerance
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    __block BOOL found = NO;
    NSMutableDictionary *dictionary = [self.observedObjects objectForKey:object];
    if (dictionary)
    {
        NSMutableSet *set = [dictionary objectForKey:keyPath];
        @synchronized (set)
        {
            if (set && set.count > 0)
            {
                [set enumerateObjectsUsingBlock:^(QZObserverMetadata *metadata, BOOL *stop) {
                    if (metadata.context == context)
                    {
                        [metadata.observer observeValueForKeyPath:keyPath ofObject:object change:change context:context];
                    }
                }];
            }
            else
            {
                [dictionary removeObjectForKey:keyPath];
            }
        }
    }
    
    @synchronized (dictionary)
    {
        if (dictionary.count == 0)
        {
            [self.observedObjects removeObjectForKey:object];
        }
    }
    
    if (!found)
    {
        [object removeObserver:self forKeyPath:keyPath context:context];
    }
}

@end
