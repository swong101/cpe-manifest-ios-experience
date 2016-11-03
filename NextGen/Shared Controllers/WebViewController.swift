//
//  WebViewController.swift
//

import UIKit
import WebKit
import MBProgressHUD

class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    private struct Constants {
        static let ScriptMessageHandlerName = "microHTMLMessageHandler"
        static let ScriptMessageAppVisible = "AppVisible"
        static let ScriptMessageAppShutdown = "AppShutdown"
        
        static let HeaderButtonWidth: CGFloat = (DeviceType.IS_IPAD ? 125 : 100)
        static let HeaderButtonHeight: CGFloat = (DeviceType.IS_IPAD ? 90 : 50)
        static let HeaderIconPadding: CGFloat = (DeviceType.IS_IPAD ? 30 : 15)
    }
    
    private var webView: WKWebView!
    private var url: URL!
    private var hud: MBProgressHUD?
    var shouldDisplayFullScreen = false
    
    // MARK: Initialization
    convenience init(title: String?, url: URL) {
        self.init()
        
        var webViewUrl = url
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true), let deviceIdentifier = DeviceType.identifier {
            let deviceModelParam = "iphoneModel=" + deviceIdentifier
            if let query = components.query {
                components.query = query + "&" + deviceModelParam
            } else {
                components.query = deviceModelParam
            }
            
            if let newUrl = components.url {
                webViewUrl = newUrl
            }
        }
        
        self.title = title
        self.url = webViewUrl
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        self.navigationController?.isNavigationBarHidden = shouldDisplayFullScreen
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.userContentController.add(self, name: Constants.ScriptMessageHandlerName)
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 9.0, *) {
            configuration.requiresUserActionForMediaPlayback = false
        } else {
            configuration.mediaPlaybackRequiresUserAction = false
        }
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        self.view.addSubview(webView)
        
        // Disable caching for now
        if #available(iOS 9.0, *) {
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = Date(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        } else {
            var libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first!
            libraryPath += "/Cookies"
            
            do {
                try FileManager.default.removeItem(atPath: libraryPath)
            } catch {
                print("error")
            }
            
            URLCache.shared.removeAllCachedResponses()
        }
        
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        
        hud = MBProgressHUD.showAdded(to: webView, animated: true)
    }

    // MARK: Actions
    func close() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constants.ScriptMessageHandlerName)
        webView.navigationDelegate = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hud?.hide(true)
    }
    
    // MARK: WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Constants.ScriptMessageHandlerName, let messageBody = message.body as? String {
            if messageBody == Constants.ScriptMessageAppVisible {
                
            } else if messageBody == Constants.ScriptMessageAppShutdown {
                close()
            }
        }
    }

}
