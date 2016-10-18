//
//  LLMovieRenderer.h
//  LLWeChat
//
//  Created by GYJZH on 13/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMotion/CoreMotion.h>


@interface LLMovieRenderer : NSObject

- (void)prepareWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)retainedBufferCountHint;
- (void)reset;

@property(nonatomic, readonly) CMFormatDescriptionRef __attribute__((NSObject)) outputFormatDescription; // non-NULL once the renderer has been prepared

@end
