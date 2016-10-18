//
//  MKMapView+ZoomLevel.h
//  LLWeChat
//
//  Created by GYJZH on 8/21/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;
- (CGFloat)getZoomLevel;

@end
