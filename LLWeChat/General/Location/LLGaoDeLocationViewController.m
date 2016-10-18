//
//  LLLocationViewController.m
//  LLWeChat
//
//  Created by GYJZH on 8/20/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LLGaoDeLocationViewController.h"
#import "LLUtils.h"
#import "LLConfig.h"
#import "LLColors.h"
#import "UIKit+LLExt.h"
#import "GDConfig.h"
#import "LLLocationTableViewCell.h"
#import "LLSearchBar.h"
#import "LLLocationManager.h"
#import "LLSearchViewController.h"
#import "LLLocationSearchResultController.h"
#import "LLSearchControllerDelegate.h"

#define DEFAULT_SEARCH_AREA_SPAN_METER 1000

#define MAP_VIEW_SPAN_METER_PER_POINT 1.2

#define TABLE_VIEW_HEIGHT_MIN_FACTOR 0.416
#define TABLE_VIEW_HEIGHT_MAX_FACTOR 0.7

#define Style_ReGeocodeSearch 0
#define Style_POISearch 1
#define Style_AllSearch 2
#define Style_POIMoreSearch 3

//只有当一次移动距离超过下面宏定义的距离后，才加载附近地点，单位米
#define MOVE_DISTANCE_RESPONCE_THREASHOLD 50

#define LOCATION_QUEUE_LABEL "location_queue_label"


@interface LLGaoDeLocationViewController () <MAMapViewDelegate, AMapSearchDelegate,AMapLocationManagerDelegate, LLSearchControllerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) MAMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray<AMapPOI *> *allMapPOIs;
@property (nonatomic) UIButton *locationBtn;
@property (nonatomic) UIImageView *pinchView;

@property (nonatomic) AMapReGeocode *curCenterReGeocode;
@property (nonatomic) AMapSearchAPI *search;
@property (nonatomic) AMapPOIAroundSearchRequest *request;
@property (nonatomic) AMapReGeocodeSearchRequest *regeo;

@property (nonatomic) LLSearchBar *searchBar;

@end

@implementation LLGaoDeLocationViewController {
    BOOL isBigStyle;
    UIView *tableIndicationMaskView;
    UIActivityIndicatorView *indicator;
    
    BOOL hasInitRegion;
    BOOL needRefreshNearbyPOI;
    NSInteger curSelectedTableRow;
    NSTimer *timer;
    CLLocation *lastRegionCLLocation;
    UIView *footView;
    UIActivityIndicatorView *footerIndicator;

    NSInteger curPage;

    LLLocationSearchResultController *resultController;
    CGFloat origionMapViewMinY;
    BOOL navigationBarTranslucent;

}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"位置";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(send:)];
    [self.navigationItem.rightBarButtonItem setTintColor:kLLTextColor_green];
//    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _searchBar = [LLSearchBar defaultSearchBar];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"搜索地点";
    [self.view addSubview:_searchBar];
    
    
    CGRect frame = SCREEN_FRAME;
    frame.origin.y = CGRectGetMaxY(_searchBar.frame);
    frame.size.height = ceil(SCREEN_HEIGHT * (1 - TABLE_VIEW_HEIGHT_MIN_FACTOR) - frame.origin.y);
    _mapView = [[MAMapView alloc] initWithFrame:frame];
    _mapView.delegate = self;
    _mapView.mapType = MAMapTypeStandard;
    _mapView.language = MAMapLanguageZhCN;
    
    _mapView.zoomEnabled = YES;
    _mapView.minZoomLevel = 4;
    _mapView.maxZoomLevel = 19;
    
    _mapView.scrollEnabled = YES;
    _mapView.showsCompass = NO;
    
    _mapView.logoCenter = CGPointMake(SCREEN_WIDTH - 3 - _mapView.logoSize.width/2, CGRectGetHeight(self.mapView.frame) - 3 - _mapView.logoSize.height/2);
    
    _mapView.showsScale = YES;
    _mapView.scaleOrigin = CGPointMake(12, CGRectGetHeight(_mapView.frame) - 25);
    
    [self.view addSubview:_mapView];
    origionMapViewMinY = CGRectGetMinY(_mapView.frame);
    
    
    _locationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_locationBtn setBackgroundImage:[UIImage imageNamed:@"location_my"] forState:UIControlStateNormal];
    [_locationBtn setBackgroundImage:[UIImage imageNamed:@"location_my_HL"] forState:UIControlStateHighlighted];
    frame = CGRectMake(0, 0, 50, 50);
    frame.origin.x = SCREEN_WIDTH - 8 - 50;
    frame.origin.y = CGRectGetMaxY(_mapView.frame) - 18 - 50;
    _locationBtn.frame = frame;
    [self.view addSubview:_locationBtn];
    [_locationBtn addTarget:self action:@selector(backToUserLocation:) forControlEvents:UIControlEventTouchUpInside];
    
    _pinchView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"located_pin"]];
    _pinchView.frame = CGRectMake(0, 0, 18, 38);
    _pinchView.layer.anchorPoint = CGPointMake(0.5, 0.96);
    _pinchView.center = _mapView.center;
    [self.view addSubview:_pinchView];
    
    
    frame = SCREEN_FRAME;
    frame.size.height = floor(SCREEN_HEIGHT * TABLE_VIEW_HEIGHT_MIN_FACTOR);
    frame.origin.y = SCREEN_HEIGHT - frame.size.height;
    _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _tableView.backgroundColor = kLLBackgroundColor_slightGray;
    _tableView.separatorColor = kLLBackgroundColor_lightGray;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 51;
    [self.view addSubview:_tableView];
    isBigStyle = NO;
    
    tableIndicationMaskView = [[UIView alloc] initWithFrame:SCREEN_FRAME];
    tableIndicationMaskView.backgroundColor = [UIColor whiteColor];
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake(SCREEN_WIDTH/2, 25);
    [tableIndicationMaskView addSubview:indicator];
    
    footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, _tableView.rowHeight)];
    footView.backgroundColor = _tableView.backgroundColor;
    footerIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    footerIndicator.center = CGPointMake(SCREEN_WIDTH/2, 25);
    footerIndicator.hidden = YES;
    [footView addSubview:footerIndicator];
    CALayer *line = [LLUtils lineWithLength:SCREEN_WIDTH atPoint:CGPointZero];
    line.backgroundColor = _tableView.separatorColor.CGColor;
    [footView.layer addSublayer:line];

    _tableView.tableFooterView = footView;
    
    needRefreshNearbyPOI = NO;
    hasInitRegion = NO;
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    [self checkAuthorization];
    
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    navigationBarTranslucent = self.navigationController.navigationBar.translucent;
    self.navigationController.navigationBar.translucent = YES;
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)cancel:(UIBarButtonItem *)item {
    [self willDismissSelf];
    [self.delegate didCancelLocationViewController:self];
}

- (void)send:(UIBarButtonItem *)item {
    [self willDismissSelf];
    
    self.mapView.userTrackingMode = MAUserTrackingModeNone;
    self.mapView.showsUserLocation = NO;
    UIImage *snapshot = [[LLLocationManager sharedManager] takeCenterSnapshotFromMapView:self.mapView];
    
    NSString *address;
    NSString *name;
    
    if (!_curCenterReGeocode) {
        address = LOCATION_UNKNOWE_ADDRESS;
        name = LOCATION_UNKNOWE_NAME;
    }else {
        MAMapPoint point1 = MAMapPointForCoordinate(self.mapView.centerCoordinate);
        CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(_regeo.location.latitude, _regeo.location.longitude);
        MAMapPoint point2 = MAMapPointForCoordinate(coordinate2D);
        CLLocationDistance distance = MAMetersBetweenMapPoints(point1,point2);
        
        if (distance > 100) {
            address = LOCATION_UNKNOWE_ADDRESS;
            name = LOCATION_UNKNOWE_NAME;
        }else{
            address = _curCenterReGeocode.formattedAddress;
            if (address.length == 0) {
                address = LOCATION_EMPTY_ADDRESS;
                name = LOCATION_EMPTY_ADDRESS;
            }else {
                if (_curCenterReGeocode.addressComponent.neighborhood.length > 0)
                    name = _curCenterReGeocode.addressComponent.neighborhood;
                else if (_curCenterReGeocode.addressComponent.building.length > 0) {
                    name = _curCenterReGeocode.addressComponent.building;
                }else {
                    name = [address substringFromIndex:_curCenterReGeocode.addressComponent.province.length];
                }
            }
  
        }
    }
    
    [self.delegate didFinishWithLocationLatitude:self.mapView.centerCoordinate.latitude
                                       longitude:self.mapView.centerCoordinate.longitude
                                            name:name
                                         address:address
                                       zoomLevel:self.mapView.zoomLevel
                                        snapshot:snapshot];
}

//即将销毁，在这里做些清理工作
- (void)willDismissSelf {
    resultController = nil;
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
            case kCLAuthorizationStatusNotDetermined:
                [_locationManager requestWhenInUseAuthorization];
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
    
    WEAK_SELF;
    [LLUtils showMessageAlertWithTitle:nil message:noServiceTitle actionTitle:@"确定" actionHandler:^{
        [weakSelf cancel:nil];
    }];

}


#pragma mark - 更新地图

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.translucent = navigationBarTranslucent;
    [self endUpdatingLocation];
}

- (void)startUpdatingLocation {
    _mapView.distanceFilter = 10;
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    
    _request = [[AMapPOIAroundSearchRequest alloc] init];
    _request.types = (NSString *)allPOISearchTypes;
    _request.sortrule            = 1;
    _request.requireExtension    = YES;
    _request.requireSubPOIs = NO;
    _request.radius = 10000;
    _request.page = 1;
    _request.offset = 20;
    
    _regeo = [[AMapReGeocodeSearchRequest alloc] init];
    _regeo.radius = 3000;
    _regeo.requireExtension = NO;
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;

}

- (void)endUpdatingLocation {
    [self stopSearchAnimation];
    self.mapView.userTrackingMode = MAUserTrackingModeNone;
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = nil;
    
    self.search.delegate = nil;

}


- (void)backToUserLocation:(UIButton *)button {
    needRefreshNearbyPOI = YES;
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate  animated:YES];
}


#pragma mark - 搜索

//搜索发生错误时调用
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    NSLog(@"%s: searchRequest = %@, errInfo= %@", __func__, [request class], error);
}

//搜索成功回调
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    curPage = request.page;
    if (curPage == 1) {
        self.allMapPOIs = [response.pois mutableCopy];
        [self reloadTableView:Style_POISearch];
    }else {
        [self.allMapPOIs addObjectsFromArray:response.pois];
        [self reloadTableView:Style_POIMoreSearch];
    }
}

//实现逆地理编码的回调函数
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    _curCenterReGeocode = response.regeocode;
    [self reloadTableView:Style_ReGeocodeSearch];
}


//获取地图中心附近的POI
- (void)fetchPOIAroundCenterCoordinate {
    [self changeFrameToBeBigger:NO];
    [self startSearchAnimation];
    [self.tableView setContentOffset:CGPointZero animated:NO];

    CLLocationCoordinate2D coordinate2D = self.mapView.centerCoordinate;
    AMapGeoPoint *point = [AMapGeoPoint locationWithLatitude:coordinate2D.latitude     longitude:coordinate2D.longitude];
   
    curPage = 1;
    _request.location = point;
    _request.page = curPage;
    
    _regeo.location = point;
    _curCenterReGeocode = nil;
    
    [self.search cancelAllRequests];
    
    [self.search AMapReGoecodeSearch:_regeo];
    [self.search AMapPOIAroundSearch:_request];
}

//UITableView上拉刷新时，获取更多数据
- (void)fetchMorePOIData {
    if (curPage == _request.page) {
        _request.page = _request.page + 1;
        [self.search AMapPOIAroundSearch:_request];
    }
    
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSLog(@"regionDidChange animated:%@", animated? @"YES":@"NO");
    
    CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:self.mapView.center toCoordinateFromView:self.mapView];
//    pointAnnotation.coordinate = coordinate2D;
//    [mapView addAnnotation:pointAnnotation];
    
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];
    if (!lastRegionCLLocation) {
        lastRegionCLLocation = self.mapView.userLocation.location;
    }
    CLLocationDistance distance = [lastRegionCLLocation distanceFromLocation:location];
    
    if (distance >= MOVE_DISTANCE_RESPONCE_THREASHOLD) {
        lastRegionCLLocation = location;
        if (!animated || needRefreshNearbyPOI) {
            needRefreshNearbyPOI = NO;
            [self fetchPOIAroundCenterCoordinate];
        }
        

        CGFloat _y = self.pinchView.bottom_LL;
        [UIView animateKeyframesWithDuration:0.75 delay:0
                                     options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced |
         UIViewKeyframeAnimationOptionOverrideInheritedDuration
                                  animations:^{
                                      [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
                                          self.pinchView.bottom_LL = _y;
                                      }];
                                      [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                                          self.pinchView.bottom_LL = _y - 12;
                                      }];
                                      [UIView addKeyframeWithRelativeStartTime:1 relativeDuration:0 animations:^{
                                          self.pinchView.bottom_LL = _y;
                                      }];
                                  }
                                  completion:nil];
        
    }

    CGPoint point = [self.mapView convertCoordinate:mapView.userLocation.location.coordinate toPointToView:self.view];
    CGFloat _d = CGPointDistanceBetween(point, self.mapView.center);
    [self setLocationButtonStyle:_d <= 6];

}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    if (!updatingLocation)return;
    if (userLocation.location.horizontalAccuracy < 0 || userLocation.location.horizontalAccuracy > 500)
        return;
    
    if (!hasInitRegion) {
        hasInitRegion = YES;
        CLLocationDistance span = SCREEN_WIDTH * MAP_VIEW_SPAN_METER_PER_POINT;
        MACoordinateRegion theRegion = MACoordinateRegionMakeWithDistance(userLocation.location.coordinate, span, span);
        [_mapView setRegion:theRegion];
    }
    
    NSLog(@"当前用户位置: %f %f", userLocation.location.coordinate.longitude, userLocation.location.coordinate.latitude);

}

- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}


#pragma mark - 辅助

- (void)reloadTableView:(NSInteger)styleFinished {
    curSelectedTableRow = 0;
    BOOL isFinished = NO;
    CGFloat rowHeight = [self.tableView rowHeight];
    
    if (styleFinished == Style_AllSearch) {
        isFinished = YES;
        
    }else if (styleFinished == Style_ReGeocodeSearch) {
        if (tableIndicationMaskView.height_LL == rowHeight) {
            isFinished = YES;
        }else {
            tableIndicationMaskView.top_LL = rowHeight;
        }
        
    }else if (styleFinished == Style_POISearch) {
        if (tableIndicationMaskView.top_LL == rowHeight) {
            isFinished = YES;
        }else {
            tableIndicationMaskView.height_LL = rowHeight;
        }
    }else if (styleFinished == Style_POIMoreSearch) {
        isFinished = YES;
        [footerIndicator stopAnimating];
        footerIndicator.hidden = YES;
    }
    
    if (isFinished) {
        [self stopSearchAnimation];
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
    }

    [self.tableView reloadData];
    
}


- (void)setLocationButtonStyle:(BOOL)isLocationMe {
    NSString *backgroundImageString =  isLocationMe ? @"location_my_current": @"location_my";
    [_locationBtn setBackgroundImage:[UIImage imageNamed:backgroundImageString] forState:UIControlStateNormal];
}

- (void)startSearchAnimation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.tableView addSubview:tableIndicationMaskView];
    tableIndicationMaskView.frame = SCREEN_FRAME;
    [indicator startAnimating];
    
    if (timer) {
        [timer invalidate];
    }
    timer = [NSTimer timerWithTimeInterval:7 target:self selector:@selector(timerHandler:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)stopSearchAnimation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [indicator stopAnimating];
    [tableIndicationMaskView removeFromSuperview];
}

- (void)timerHandler:(NSTimer *)timer {
    if (indicator.isAnimating && indicator.hidden == NO) {
        [self reloadTableView:Style_AllSearch];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.tableView)return;
    
    if (!isBigStyle && scrollView.contentOffset.y > 10) {
        [self changeFrameToBeBigger:YES];
    }else if (isBigStyle && scrollView.contentOffset.y < -10) {
        [self changeFrameToBeBigger:NO];
    }
    //开始加载新的数据
    if ((footerIndicator.hidden == YES) && (footView.hidden == YES) && (scrollView.contentOffset.y + scrollView.frame.size.height + 2 >= scrollView.contentSize.height)) {
        footerIndicator.hidden = NO;
        [footerIndicator startAnimating];
        [self fetchMorePOIData];
    }
}

- (void)changeFrameToBeBigger:(BOOL)bigger {
    if (isBigStyle == bigger)return;
    self.view.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.25
                          delay:(bigger? 0 : 0.1)
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame= self.tableView.frame;
                         frame.size.height = floor(SCREEN_HEIGHT *
                                                   (bigger ? TABLE_VIEW_HEIGHT_MAX_FACTOR : TABLE_VIEW_HEIGHT_MIN_FACTOR));
                         frame.origin.y = SCREEN_HEIGHT - frame.size.height;
                         self.tableView.frame = frame;
                         
                         frame = self.mapView.frame;
                         frame.size.height = SCREEN_HEIGHT - CGRectGetHeight(self.tableView.frame) - CGRectGetMaxY(self.searchBar.frame);
                         self.mapView.frame = frame;
                         
                         frame = self.locationBtn.frame;
                         frame.origin.y = CGRectGetMaxY(_mapView.frame) - 18 - 50;
                         self.locationBtn.frame = frame;
                         
                         _pinchView.center = _mapView.center;
                         
                     }
                     completion:^(BOOL finished) {
                         self.view.userInteractionEnabled = YES;
                         isBigStyle = bigger;
                     }];
    [self.mapView setCenterCoordinate:self.mapView.centerCoordinate animated:YES];
    
}



#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    footView.hidden = self.allMapPOIs.count == 0;
    
    return self.allMapPOIs.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID1 = @"ID1";
    static NSString *ID2 = @"ID2";
    
    BOOL isHeadRow = indexPath.row == 0;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:isHeadRow? ID1 : ID2];
    if (!cell) {
        if (indexPath.row == 0) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID1];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
        }else {
            cell = [[LLLocationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID2];
        }
         cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AlbumCheckmark"]];

    }
    
    if (isHeadRow) {
        if (_curCenterReGeocode.formattedAddress.length == 0 && curSelectedTableRow == 0)
            cell.hidden = YES;
        else {
            cell.hidden = NO;
            cell.textLabel.text = _curCenterReGeocode.formattedAddress;
        }
    }else {
        AMapPOI *model = self.allMapPOIs[indexPath.row - 1];
        ((LLLocationTableViewCell *)cell).poiModel = model;
        cell.textLabel.text = model.name;
        cell.detailTextLabel.text = [self getAddressFromAMapPOI:model];
    }
    
    cell.accessoryView.hidden = indexPath.row == curSelectedTableRow ? NO : YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.textLabel.text.length == 0)
        return;
    
    if (indexPath.row == 0) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
    }else {
        LLLocationTableViewCell *locationCell = (LLLocationTableViewCell *)cell;
        AMapGeoPoint *point = locationCell.poiModel.location;
        CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        [self.mapView setCenterCoordinate:coordinate2D animated:YES];
    }
    
    UITableViewCell *selectcell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:curSelectedTableRow inSection:0]];
    if (selectcell) {
        selectcell.accessoryView.hidden = YES;
    }
    
    cell.accessoryView.hidden = NO;
    curSelectedTableRow = indexPath.row;
    
}

- (NSString *)getAddressFromAMapPOI:(AMapPOI *)poi {
    NSString *address;
    if ([poi.city isEqualToString:poi.province]) {
        address = [NSString stringWithFormat:@"%@%@", poi.city, poi.address];
    }else {
        address = [NSString stringWithFormat:@"%@%@%@", poi.province, poi.city, poi.address];
    }
    
    return address;
}

#pragma mark - 地图搜索

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    LLSearchViewController *vc = [LLSearchViewController sharedInstance];
    vc.delegate = self;
    if (!resultController) {
        resultController = [[LLLocationSearchResultController alloc] init];
        resultController.gaodeViewController = self;
    }
    vc.searchResultController = resultController;
    resultController.searchViewController = vc;
    [vc showInViewController:self fromSearchBar:self.searchBar];
    
    return NO;
}

- (void)didRowWithModelSelected:(AMapPOI *)poiModel {
    AMapGeoPoint *point = poiModel.location;
    CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(point.latitude, point.longitude);
    needRefreshNearbyPOI = YES;
    [self.mapView setCenterCoordinate:coordinate2D animated:YES];
    
    [[LLSearchViewController sharedInstance] dismissSearchController];
}

- (void)adjustPositionForSearch {
    CGFloat _y = CGRectGetMinY(self.view.frame);
    
    [UIView animateWithDuration:0.25 animations:^{
        if (_y < 0) {
            self.view.top_LL = 0;
        }else {
            self.view.top_LL = 64 - origionMapViewMinY;
        }
       
    }];

}

- (void)willDismissSearchController:(LLSearchViewController *)searchController {
    [self adjustPositionForSearch];
}

- (void)willPresentSearchController:(LLSearchViewController *)searchController {
    [self adjustPositionForSearch];
}

@end
