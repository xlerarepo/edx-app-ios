//
//  WKWebViewExtension.swift
//  edX
//
//  Created by MuhammadUmer on 31/01/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

extension WKWebView {
    private var languageCookieName: String {
        return "prod-edx-language-preference"
    }

    private var defaultLanguage: String {
        guard let language = NSLocale.preferredLanguages.first else {
            return "en"
        }
        
        if Bundle.main.preferredLocalizations.contains(language) {
            return language
        } else {
            return "en"
        }
    }
    
    func loadRequest(_ request: URLRequest) {
        if #available(iOS 11.0, *) {
            guard let domain = request.url?.rootDomain,
                let languageCookie = HTTPCookie(properties: [
                .domain: ".\(domain)",
                .path: "/",
                .name: languageCookieName,
                .value: defaultLanguage,
                .expires: NSDate(timeIntervalSinceNow: 3600000)
                ])
                else {
                    load(request)
                    return
            }

            getCookie(with: languageCookieName) { [weak self]  cookie in
                if cookie == nil {
                    self?.configuration.websiteDataStore.httpCookieStore.setCookie(languageCookie) {
                        self?.load(request)
                    }
                } else {
                    self?.load(request)
                }
            }
        } else {
            var cookiedRequest = request
            cookiedRequest.addValue("\(languageCookieName)=\(defaultLanguage))", forHTTPHeaderField: "Cookie")
            load(cookiedRequest)
        }
    }
}

@available(iOS 11.0, *)
extension WKWebView {
    private var httpCookieStore: WKHTTPCookieStore  { return WKWebsiteDataStore.default().httpCookieStore }
    
    func getCookie(with name: String, completion: @escaping (HTTPCookie?)-> ()) {
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if cookie.name.contains(name) {
                    completion(cookie)
                }
            }
        }
        completion(nil)
    }
}

extension URL {
    var rootDomain: String? {
        guard let hostName = self.host else { return nil }
        let components = hostName.components(separatedBy: ".")
        if components.count > 2 {
            return components.suffix(2).joined(separator: ".")
        } else {
            return hostName
        }
    }
}