//
//  QZObserver.h
//  QZObserver
//
//  Created by Mark Schultz on 1/23/14.
//  Copyright (c) 2014 QZero Labs, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QZObserver : NSObject
 
- (void)addObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath;
- (void)removeObserver:(NSObject *)observer forObject:(NSObject *)object forKeyPath:(NSString *)keyPath context:(void *)context;

@end
