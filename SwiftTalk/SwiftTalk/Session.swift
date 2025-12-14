//
//  Account.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import SwiftUI
import Observation
import KeychainItem
import AuthenticationServices
import Combine

class Session: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {

    @KeychainItem(account: "sessionId") private var sessionId
    @KeychainItem(account: "csrf") private var csrf
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                fatalError()
            }
        return windowScene.windows.first ?? ASPresentationAnchor(windowScene: windowScene)
    }
    
    @Published
    var credentials: (sessionId: String, csrf: String)?
    
    func startAuthSession() {
        authSession = ASWebAuthenticationSession(
            url: URL(string: authUrl)!,
            callback: .customScheme(authScheme)) { callback, error in
                if let error {
                    self.authError = .authenticationError(error)
                    return
                }
                guard let callback else {
                    self.authError = .unknownError
                    return
                }
                guard let components = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                      let sessionId = components[query: "session_id"],
                      let csrf = components[query: "csrf"] else {
                    self.authError = .parsingError
                    return
                }
                self.credentials = (sessionId, csrf)
            }
        authSession?.presentationContextProvider = self
        authSession?.start()
    }
    
    private override init() {
        super.init()
        self.load()
    }
    
    private func load() {
        if let sessionId, let csrf {
            self.credentials = (sessionId, csrf)
        } else {
            self.credentials = nil
        }
        cancellable = $credentials
            .sink { [unowned self] in
                self.sessionId = $0?.sessionId
                self.csrf = $0?.csrf
            }
    }
    
    private var authSession: ASWebAuthenticationSession?
    private var cancellable: AnyCancellable?
    
    @Published
    private(set) var authError: AuthenticationError?
    
    static let shared = Session()
}

enum AuthenticationError: Error {
    case unknownError
    case authenticationError(Error)
    case parsingError
}

extension URLComponents {
    subscript(query name: String) -> String? {
        queryItems?.first(where: { $0.name == name })?.value
    }
}

private let authUrl = "https://talk.objc.io/users/auth/github?origin=/authorize_app"
private let authScheme = "swifttalk"
