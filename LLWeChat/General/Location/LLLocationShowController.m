//
//  LLLocationShowController.m
//  LLWeChat
//
//  Created by GYJZH on 8/27/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLLocationShowController.h"
#import "LLActionSheet.h"
#import "LLColors.h"
#import "LLUtils.h"
#import "LLLocationManager.h"
#import <MAMapKit/MAMapKit.h>

#define BOTTOM_BAR_HEIGHT 90

@interface LLLocationShowController () <MAMapViewDelegate, CLLocationManagerDelegate, AMapSearchDelegate>

@property (nonatomic) MAMapView *mapView;
@property (nonatomic) UILabel *topLabel;
@property (nonatomic) UILabel *bottomLabel;
@property (nonatomic) UIButton *locationBtn;
@property (nonatomic) MAAnnotationView *userLocationAnnotationView;

@property (nonatomic) AMapSearchAPI *search;

@end

@implementation LLLocationShowController {
    BOOL isBackToUserLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"";
    
    CGRect frame = SCREEN_FRAME;
    frame.size.height = SCREEN_HEIGHT - BOTTOM_BAR_HEIGHT;
    _mapView = [[MAMapView alloc] initWithFrame:frame];
    _mapView.delegate = self;
    _mapView.mapType = MAMapTypeStandard;
    _mapView.language = MAMapLanguageZhCN;
    
    _mapView.zoomEnabled = YES;
    _mapView.minZoomLevel = 4;
    _mapView.maxZoomLevel = 18;
    
    _mapView.scrollEnabled = YES;
    _mapView.showsCompass = NO;
    
    _mapView.logoCenter = CGPointMake(SCREEN_WIDTH - 3 - _mapView.logoSize.width/2, CGRectGetHeight(self.mapView.frame) - 3 - _mapView.logoSize.height/2);
    
    _mapView.showsScale = YES;
    _mapView.scaleOrigin = CGPointMake(12, CGRectGetHeight(_mapView.frame) - 25);
    
    [self.view addSubview:_mapView];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setBackgroundImage:[UIImage imageNamed:@"barbuttonicon_back_cube"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [leftButton sizeToFit];
    frame = leftButton.frame;
    frame.origin.x = 14;
    frame.origin.y = 27;
    leftButton.frame = frame;
    [self.view addSubview:leftButton];
    
    self.navigationItem.hidesBackButton = YES;
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setBackgroundImage:[UIImage imageNamed:@"barbuttonicon_more_cube"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(more:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton sizeToFit];
    //  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    frame = rightButton.frame;
    frame.origin.x = SCREEN_WIDTH - 14 - CGRectGetWidth(frame);
    frame.origin.y = 27;
    rightButton.frame = frame;
    [self.view addSubview:rightButton];
    
    _locationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_locationBtn setBackgroundImage:[UIImage imageNamed:@"location_my"] forState:UIControlStateNormal];
    [_locationBtn setBackgroundImage:[UIImage imageNamed:@"location_my_HL"] forState:UIControlStateHighlighted];
    [_locationBtn sizeToFit];
    frame = _locationBtn.frame;
    frame.origin.x = SCREEN_WIDTH - 13 - CGRectGetWidth(frame);
    frame.origin.y = CGRectGetMaxY(_mapView.frame) - 18 - 50;
    _locationBtn.frame = frame;
    [self.view addSubview:_locationBtn];
    [_locationBtn addTarget:self action:@selector(backToUserLocation:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIView *locationView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - BOTTOM_BAR_HEIGHT, SCREEN_WIDTH, BOTTOM_BAR_HEIGHT)];
    locationView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:locationView];
    
    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareBtn setBackgroundImage:[UIImage imageNamed:@"locationSharing_navigate_icon_new"] forState:UIControlStateNormal];
    [shareBtn setBackgroundImage:[UIImage imageNamed:@"locationSharing_navigate_icon_HL_new"] forState:UIControlStateHighlighted];
    [shareBtn addTarget:self  action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    [shareBtn sizeToFit];
    frame = shareBtn.frame;
    frame.origin.x = SCREEN_WIDTH - 13 - CGRectGetWidth(frame);
    frame.origin.y = (CGRectGetHeight(locationView.frame) - CGRectGetHeight(frame))/2;
    shareBtn.frame = frame;
    [locationView addSubview:shareBtn];
    
    _topLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 25, CGRectGetMinX(shareBtn.frame) -13 - 29 , 25)];
    _topLabel.font = [UIFont systemFontOfSize:20];
    _topLabel.textColor = [UIColor blackColor];
    _topLabel.textAlignment = NSTextAlignmentLeft;
    [locationView addSubview:_topLabel];
    
    _bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_topLabel.frame), 54, CGRectGetWidth(_topLabel.frame), 20)];
    _bottomLabel.font = [UIFont systemFontOfSize:12];
    _bottomLabel.textColor = kLLTextColor_lightGray_system;
    _bottomLabel.textAlignment = NSTextAlignmentLeft;
    [locationView addSubview:_bottomLabel];
    
    isBackToUserLocation = NO;
    [self checkAuthorization];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    _topLabel.text = self.model.locationName;
    _bottomLabel.text = self.model.address;
   
    [self.mapView setZoomLevel:self.model.zoomLevel animated:NO];
    [self.mapView setCenterCoordinate:self.model.coordinate2D animated:NO];

    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = self.model.coordinate2D;
    [self.mapView addAnnotation:pointAnnotation];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self endUpdatingLocation];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - 按钮回调

- (void)back:(UIButton *)btn {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)more:(UIButton *)btn {
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:nil];
    LLActionSheetAction *action1 = [LLActionSheetAction actionWithTitle:@"发送给朋友"
                                                                handler:^(LLActionSheetAction *action) {
                                                                    
                                                                }];
    
    LLActionSheetAction *action2 = [LLActionSheetAction actionWithTitle:@"收藏"
                                                                handler:^(LLActionSheetAction *action) {
                                                                    
                                                                }] ;
    
    [actionSheet addActions:@[action1, action2]];
    
    [actionSheet showInWindow:self.view.window];
}

- (void)share:(UIButton *)btn {
    WEAK_SELF;
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:nil];
    LLActionSheetAction *action1 = [LLActionSheetAction actionWithTitle:@"显示路线"
                                                                handler:^(LLActionSheetAction *action) {
                                [weakSelf searchRoutePlanningDrive];
                                                                }];
    
    LLActionSheetAction *action2 = [LLActionSheetAction actionWithTitle:@"街景"
                                                                handler:^(LLActionSheetAction *action) {
                                                                    
                                                                }] ;
    
    LLActionSheetAction *action3 = [LLActionSheetAction actionWithTitle:@"腾讯地图"
                                                                handler:^(LLActionSheetAction *action) {
                                                                    
                                                                }];
    
    LLActionSheetAction *action4 = [LLActionSheetAction actionWithTitle:@"高德地图"
                                                                handler:^(LLActionSheetAction *action) {
                                        [[LLLocationManager sharedManager] navigationUsingGaodeMapFromLocation:weakSelf.mapView.userLocation.location.coordinate toLocation:weakSelf.model.coordinate2D destinationName:weakSelf.model.address];
                                                                }];
    
    LLActionSheetAction *action5 = [LLActionSheetAction actionWithTitle:@"苹果地图"
                                                                handler:^(LLActionSheetAction *action) {
            [[LLLocationManager sharedManager] navigationFromCurrentLocationToLocationUsingAppleMap:weakSelf.model.coordinate2D destinationName:weakSelf.model.address];
                                                                }];

    
    [actionSheet addActions:@[action1, action2, LL_ActionSheetSeperator, action3, action4, action5]];
    
    [actionSheet showInWindow:self.view.window];
}


#pragma mark - 权限管理

- (void)checkAuthorization {
    if (![CLLocationManager locationServicesEnabled]) {
        [self promptNoAuthorizationAlert];
    }else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        switch (status) {
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                [self promptNoAuthorizationAlert];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self startUpdatingLocation];
                break;
            case kCLAuthorizationStatusNotDetermined: {
                CLLocationManager *locationManager = [[CLLocationManager alloc] init];
                locationManager.delegate = self;
                [locationManager requestWhenInUseAuthorization];
            }
                break;
        }
    }
    
}

- (void)locationManager:(CLLocationManager *)locationManager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [self promptNoAuthorizationAlert];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startUpdatingLocation];
        case kCLAuthorizationStatusNotDetermined:
            [locationManager requestWhenInUseAuthorization];
            break;
    }
}


- (void)promptNoAuthorizationAlert {
    NSString *noServiceTitle = @"  无法获取你的位置信息。\n请到手机系统的[设置]->[隐私]->[定位服务]中打开定位服务,并允许微信使用定位服务。";
    [LLUtils showMessageAlertWithTitle:nil message:noServiceTitle];
    
}

- (void)setLocationButtonStyle:(BOOL)isLocationMe {
    NSString *backgroundImageString =  isLocationMe ? @"location_my_current": @"location_my";
    [_locationBtn setBackgroundImage:[UIImage imageNamed:backgroundImageString] forState:UIControlStateNormal];
}

#pragma mark - 更新地图
- (void)startUpdatingLocation {
    _mapView.distanceFilter = 10;
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MAUserTrackingModeFollowWithHeading;
    MAUserLocationRepresentation *representation = [[MAUserLocationRepresentation alloc] init];
    representation.showsHeadingIndicator = YES;
    [_mapView updateUserLocationRepresentation:representation];
    
    if (_search)
        _search.delegate = self;
    
}

- (void)endUpdatingLocation {
    self.mapView.userTrackingMode = MAUserTrackingModeNone;
    self.mapView.showsUserLocation = NO;
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.mapView.delegate = nil;

    if (_search)
        _search.delegate = nil;
}

- (void)backToUserLocation:(UIButton *)button {
    isBackToUserLocation = YES;
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate  animated:YES];
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (animated && isBackToUserLocation) {
        isBackToUserLocation = NO;
        [self setLocationButtonStyle:YES];
    }else {
        [self setLocationButtonStyle:NO];
    }
}


- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {

    MAAnnotationView *annotationView;
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        annotationView = [[MAAnnotationView alloc] init];
        annotationView.annotation = annotation;
        annotationView.image = [UIImage imageNamed:@"located_pin"];
        annotationView.enabled = NO;
        annotationView.draggable = NO;
        annotationView.bounds = CGRectMake(0, 0, 18, 38);
        annotationView.layer.anchorPoint = CGPointMake(0.5, 0.96);
        
    }else if ([annotation isKindOfClass:[MAUserLocation class]]) {
//        annotationView = [[MAAnnotationView alloc] init];
//        annotationView.annotation = annotation;
//        annotationView.image = [UIImage imageNamed:@"located_pin"];
//        annotationView.enabled = NO;
//        annotationView.draggable = NO;
//        annotationView.bounds = CGRectMake(0, 0, 18, 38);
//        annotationView.layer.anchorPoint = CGPointMake(0.5, 0.96);
    }
    
    
    return annotationView;
}

- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views{
    for (MAAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[MAUserLocation class]]){
            MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
            pre.fillColor = kLLBackgroundColor_slightBlue;
            pre.image = [UIImage imageNamed:@"locationSharing_Icon_MySelf"];
            pre.lineWidth = 0;
            pre.showsAccuracyRing = YES;
            pre.showsHeadingIndicator = YES;
            
            UIImage *indicator = [UIImage imageNamed:@"locationSharing_Icon_Myself_Heading"];
            UIImageView *headingView = [[UIImageView alloc] initWithImage:indicator];
            [headingView sizeToFit];
            CGRect frame = headingView.frame;
            frame.origin.x = 1;
            frame.origin.y = -8;
            headingView.frame = frame;
            
            [view addSubview:headingView];
            [self.mapView updateUserLocationRepresentation:pre];
            
            view.canShowCallout = NO;
            self.userLocationAnnotationView = view;
            
            break;
        }
    }
   
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (!updatingLocation && self.userLocationAnnotationView != nil)
    {
        [UIView animateWithDuration:0.1 animations:^{
            
            double degree = userLocation.heading.trueHeading;
            self.userLocationAnnotationView.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.f );
            
        }];
    }
    
}

#pragma mark - 路径规划

/* 驾车路径规划搜索. */
- (void)searchRoutePlanningDrive {
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    
    navi.requireExtension = YES;
    navi.strategy = 5;
    /* 出发点. */
    CLLocationCoordinate2D fromCoordinate = self.mapView.userLocation.location.coordinate;
    navi.origin = [AMapGeoPoint locationWithLatitude:fromCoordinate.latitude
                                           longitude:fromCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.model.coordinate2D.latitude
                                                longitude:self.model.coordinate2D.longitude];
    
    if (!_search) {
        self.search = [[AMapSearchAPI alloc] init];
        self.search.delegate = self;
    }
    [self.search AMapDrivingRouteSearch:navi];
}

//- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
//    NSLog(@"%s: searchRequest = %@, errInfo= %@", __func__, [request class], error);
//}
//
///* 路径规划搜索回调. */
//- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
//{
//    if (response.route == nil)
//    {
//        return;
//    }
//    
//    self.route = response.route;
//    [self updateTotal];
//    self.currentCourse = 0;
//    
//    [self updateCourseUI];
//    [self updateDetailUI];
//    
//    if (response.count > 0)
//    {
//        [self presentCurrentCourse];
//    }
//}
//
//- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
//{
//    if ([overlay isKindOfClass:[LineDashPolyline class]])
//    {
//        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
//        polylineRenderer.lineWidth   = 8;
//        polylineRenderer.lineDashPattern = @[@10, @15];
//        polylineRenderer.strokeColor = [UIColor redColor];
//        
//        return polylineRenderer;
//    }
//    if ([overlay isKindOfClass:[MANaviPolyline class]])
//    {
//        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
//        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
//        
//        polylineRenderer.lineWidth = 8;
//        
//        if (naviPolyline.type == MANaviAnnotationTypeWalking)
//        {
//            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
//        }
//        else if (naviPolyline.type == MANaviAnnotationTypeRailway)
//        {
//            polylineRenderer.strokeColor = self.naviRoute.railwayColor;
//        }
//        else
//        {
//            polylineRenderer.strokeColor = self.naviRoute.routeColor;
//        }
//        
//        return polylineRenderer;
//    }
//    if ([overlay isKindOfClass:[MAMultiPolyline class]])
//    {
//        MAMultiColoredPolylineRenderer * polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:overlay];
//        
//        polylineRenderer.lineWidth = 10;
//        polylineRenderer.strokeColors = [self.naviRoute.multiPolylineColors copy];
//        polylineRenderer.gradient = YES;
//        
//        return polylineRenderer;
//    }
//    
//    return nil;
//}

@end
