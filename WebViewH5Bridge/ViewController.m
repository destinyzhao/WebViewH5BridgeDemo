//
//  ViewController.m
//  WebViewH5Bridge
//
//  Created by Alex on 2017/1/16.
//  Copyright © 2017年 Alex. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "WebViewJavascriptBridge.h"
#import "WKWebViewJavascriptBridge.h"

@interface ViewController ()<UIWebViewDelegate,WKNavigationDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) JSContext *context;
@property (strong, nonatomic) WKWebView *wkWebView;
@property (strong, nonatomic) WebViewJavascriptBridge* bridge;
@property (strong, nonatomic) WKWebViewJavascriptBridge* wkbridge;

@end

@implementation ViewController

- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
        //_webView.delegate = self;
        [self.view addSubview:_webView];
    }
    return _webView;
}

- (WKWebView *)wkWebView
{
    if (!_wkWebView) {
        _wkWebView = [[WKWebView alloc]initWithFrame:self.view.bounds];
        _wkWebView.navigationDelegate =  self;
    }
    return _wkWebView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadWebViewBridge];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadWebView
{
    NSString *urlStr = @"http://192.168.1.252:84/ExampleApp.html";
    NSURL *url = [NSURL URLWithString:urlStr];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark -
#pragma mark - UIWebView使用
- (void)loadWebViewBridge
{
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
    [_bridge setWebViewDelegate:self];
    
    // JavaScript调用Objective-C
    // OC注册一个方法：
    [self.bridge registerHandler:@"getProductDetail" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        // responseCallback 给JS回复
        responseCallback(@"Response from testObjcCallback");
        
        [self getUserInfos];
    }];
   
    NSString *urlStr = @"http://192.168.1.252:84/test.html";
    NSURL *url = [NSURL URLWithString:urlStr];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)getUserInfos
{
    // JavaScript调用方法
    [self.bridge callHandler:@"getUserInfos" data:@"OC get Message" responseCallback:^(id responseData) {
        NSLog(@"ObjC received response: %@", responseData);
    }];
}

#pragma mark -
#pragma mark - WKWebView 使用
- (void)loadWKWebViewBridge
{
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    
    [WKWebViewJavascriptBridge enableLogging];
    
    _wkbridge = [WKWebViewJavascriptBridge bridgeForWebView:webView];
    [_wkbridge setWebViewDelegate:self];
    
    // JavaScript调用Objective-C
    [self.wkbridge registerHandler:@"getProductDetail" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        // responseCallback 给JS回复
        responseCallback(@"Response from testObjcCallback");
        
        [self getUserInfosWk];
    }];
    
    NSString *urlStr = @"http://192.168.1.252:84/test.html";
    NSURL *url = [NSURL URLWithString:urlStr];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)getUserInfosWk
{
    // Objective-C调用JavaScript
    [self.wkbridge callHandler:@"getUserInfos" data:@"OC get Message" responseCallback:^(id responseData) {
        NSLog(@"ObjC received response: %@", responseData);
    }];
}


#pragma mark -
#pragma mark - 页面加载完成
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self registerJSHander];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self registerJSHander];
}

#pragma mark -
#pragma mark - 注册JS
- (void)registerJSHander
{
    __weak __typeof(&*self)weakSelf = self;
    _context = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    //定义好JS要调用的方法, share就是调用的share方法名
    _context[@"test2"] = ^() {
        
        NSArray *args = [JSContext currentArguments];
        for (id object in args) {
            NSLog(@"------>%@",object);
        }
        
        [weakSelf jsFunction:@""];
    };
}

#pragma mark -
#pragma mark - JS调用OC方法
- (void)jsFunction:(NSString *)str
{
    NSLog(@"js调用,参数%@",str);
    
    [self ocToJsPassValue];
    
}

#pragma mark -
#pragma mark - OC向JS传参
- (void)ocToJsPassValue {
    //如果需要传递参数 给 JS，则初始化参数
    NSString *str2 = @"已接受到消息 ";
     //传参数
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"test2result('%@');", str2]];
}


@end
