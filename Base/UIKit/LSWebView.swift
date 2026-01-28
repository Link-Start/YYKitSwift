//
//  LSWebView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的 WebView - 支持进度、注入脚本、Cookie 管理等
//

#if canImport(UIKit)
import WebKit

// MARK: - LSWebView

/// 增强的 WebView
@MainActor
public class LSWebView: WKWebView {

    // MARK: - 类型定义

    /// 加载进度回调
    public typealias ProgressHandler = (Double) -> Void

    /// 导航回调
    public typealias NavigationHandler = (LSWebViewNavigationAction) -> Void

    /// 导录决策回调
    public typealias NavigationDecisionHandler = (LSWebViewNavigationAction) -> WKNavigationActionPolicy

    /// URL 变化回调
    public typealias URLChangeHandler = (URL?) -> Void

    /// 标题变化回调
    public typealias TitleChangeHandler = (String?) -> Void

    /// 错误回调
    public typealias ErrorHandler = (Error) -> Void

    // MARK: - 属性

    /// 加载进度
    public private(set) var loadingProgress: Double = 0 {
        didSet {
            onProgressChanged?(loadingProgress)
        }
    }

    /// 是否正在加载
    public private(set) var isLoading: Bool = false {
        didSet {
            onLoadingStateChanged?(isLoading)
        }
    }

    /// 当前 URL
    public private(set) var currentURL: URL? {
        didSet {
            onURLChanged?(currentURL)
        }
    }

    /// 当前标题
    public private(set) var currentTitle: String? {
        didSet {
            onTitleChanged?(currentTitle)
        }
    }

    /// 是否可以后退
    public var canGoBack: Bool {
        return canGoBack
    }

    /// 是否可以前进
    public var canGoForward: Bool {
        return canGoForward
    }

    /// 加载进度回调
    public var onProgressChanged: ProgressHandler?

    /// 加载状态变化回调
    public var onLoadingStateChanged: ((Bool) -> Void)?

    /// URL 变化回调
    public var onURLChanged: URLChangeHandler?

    /// 标题变化回调
    public var onTitleChanged: TitleChangeHandler?

    /// 导航开始回调
    public var onNavigationStart: NavigationHandler?

    /// 导航完成回调
    public var onNavigationComplete: NavigationHandler?

    /// 导航失败回调
    public var onNavigationFailed: ErrorHandler?

    /// 导录决策回调
    public var onNavigationDecision: NavigationDecisionHandler?

    /// 是否显示加载指示器
    public var showsProgress: Bool = false {
        didSet {
            progressView.isHidden = !showsProgress
        }
    }

    /// 进度条颜色
    public var progressColor: UIColor = .systemBlue {
        didSet {
            progressView.progressTintColor = progressColor
        }
    }

    // MARK: - 私有属性

    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = .clear
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    // MARK: - 初始化

    public override init(frame: CGRect, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        super.init(frame: frame, configuration: configuration)

        setupWebView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    public convenience init(url: URL) {
        let config = WKWebViewConfiguration()
        self.init(frame: .zero, configuration: config)
        loadURL(url)
    }

    public convenience init(htmlString: String, baseURL: URL? = nil) {
        let config = WKWebViewConfiguration()
        self.init(frame: .zero, configuration: config)
        loadHTMLString(htmlString, baseURL: baseURL)
    }

    // MARK: - 设置

    private func setupWebView() {
        navigationDelegate = self
        uiDelegate = self

        addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // KVO 监听加载进度
        addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        addObserver(self, forKeyPath: "title", options: .new, context: nil)
        addObserver(self, forKeyPath: "URL", options: .new, context: nil)

        if #available(iOS 14.0, *) {
            allowsBackForwardNavigationGestures = true
        }
    }

    // MARK: - KVO

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            loadingProgress = estimatedProgress
            progressView.setProgress(loadingProgress, animated: true)

            if loadingProgress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.progressView.isHidden = true
                }
            } else if showsProgress {
                progressView.isHidden = false
            }
        } else if keyPath == "title" {
            currentTitle = title
        } else if keyPath == "URL" {
            currentURL = url
        }
    }

    // MARK: - 公共方法

    /// 加载 URL
    public func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        load(request)
    }

    /// 加载 HTML 字符串
    public func loadHTMLString(_ html: String, baseURL: URL? = nil) {
        loadHTMLString(html, baseURL: baseURL)
    }

    /// 重新加载
    public func ls_reload() {
        reload()
    }

    /// 停止加载
    public func ls_stopLoading() {
        stopLoading()
    }

    /// 后退
    public func ls_goBack() {
        goBack()
    }

    /// 前进
    public func ls_goForward() {
        goForward()
    }

    /// 注入 JavaScript
    @discardableResult
    public func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        if #available(iOS 14.0, *) {
            evaluateJavaScript(script) { result, error in
                completion?(result, error)
            }
        } else {
            // Fallback for iOS 13
            if let completion = completion {
                evaluateJavaScript(script, completionHandler: completion)
            } else {
                evaluateJavaScript(script)
            }
        }
    }

    /// 调用 JavaScript 函数
    public func callJavaScriptFunction(_ functionName: String, arguments: [Any] = [], completion: ((Any?, Error?) -> Void)? = nil) {
        let argumentsString = arguments.map { argument in
            if let string = argument as? String {
                return "\"\(string)\""
            } else if let number = argument as? NSNumber {
                return number.stringValue
            } else if let bool = argument as? Bool {
                return bool ? "true" : "false"
            } else {
                return "\(argument)"
            }
        }.joined(separator: ", ")

        let script = "\(functionName)(\(argumentsString))"
        evaluateJavaScript(script, completion: completion)
    }

    /// 获取页面标题
    public func ls_getTitle(completion: @escaping (String?) -> Void) {
        evaluateJavaScript("document.title") { result, _ in
            completion(result as? String)
        }
    }

    /// 获取页面 URL
    public func ls_getURL(completion: @escaping (URL?) -> Void) {
        evaluateJavaScript("window.location.href") { result, _ in
            if let urlString = result as? String, let url = URL(string: urlString) {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }

    /// 滚动到顶部
    public func ls_scrollToTop(animated: Bool = true) {
        let scrollView = subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
        let contentOffset
        if let tempContentoffset = scrollView?.contentOffset {
            contentOffset = tempContentoffset
        } else {
            contentOffset = .zero
        }

        if animated {
            scrollView?.setContentOffset(.zero, animated: true)
        } else {
            scrollView?.contentOffset = .zero
        }
    }

    /// 清除缓存
    public static func ls_clearCache() {
        if #available(iOS 14.0, *) {
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: nil)
                }
            }
        }
    }

    deinit {
        removeObserver(self, forKeyPath: "estimatedProgress")
        removeObserver(self, forKeyPath: "title")
        removeObserver(self, forKeyPath: "URL")
    }
}

// MARK: - WKNavigationDelegate

extension LSWebView: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        progressView.isHidden = !showsProgress

        let action = LSWebViewNavigationAction(url: currentURL)
        onNavigationStart?(action)
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // 导航提交
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        progressView.isHidden = true

        let action = LSWebViewNavigationAction(url: currentURL)
        onNavigationComplete?(action)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        progressView.isHidden = true

        onNavigationFailed?(error)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let action = LSWebViewNavigationAction(
            url: navigationAction.request.url,
            navigationType: navigationAction.navigationType
        )

        if let onDecision = onNavigationDecision {
            let policy = onDecision(action)
            decisionHandler(policy)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - WKUIDelegate

extension LSWebView: WKUIDelegate {

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    public func webViewDidClose(_ webView: WKWebView) {
        // WebView 关闭
    }
}

// MARK: - LSWebViewNavigationAction

/// WebView 导录动作
public struct LSWebViewNavigationAction {
    public let url: URL?
    public let navigationType: WKNavigationAction.NavigationType?

    public init(url: URL?, navigationType: WKNavigationAction.NavigationType? = nil) {
        self.url = url
        self.navigationType = navigationType
    }
}

// MARK: - LSWebViewController

/// WebView 视图控制器
public class LSWebViewController: UIViewController {

    // MARK: - 属性

    /// WebView
    public private(set) lazy var webView: LSWebView = {
        let config = WKWebViewConfiguration()
        let wv = LSWebView(frame: .zero, configuration: config)
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    /// 工具栏
    public var showsToolbar: Bool = true {
        didSet {
            toolbar.isHidden = !showsToolbar
            updateToolbarConstraints()
        }
    }

    /// 工具栏颜色
    public var toolbarColor: UIColor = .systemBackground {
        didSet {
            toolbar.backgroundColor = toolbarColor
        }
    }

    /// 是否显示进度
    public var showsProgress: Bool = true {
        didSet {
            webView.showsProgress = showsProgress
        }
    }

    // MARK: - UI 组件

    private let toolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("完成", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupWebViewController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebViewController()
    }

    public convenience init(url: URL) {
        self.init()
        webView.loadURL(url)
    }

    public convenience init(htmlString: String, baseURL: URL? = nil) {
        self.init()
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }

    // MARK: - 设置

    private func setupWebViewController() {
        view.backgroundColor = .systemBackground

        view.addSubview(webView)
        view.addSubview(toolbar)

        toolbar.addSubview(backButton)
        toolbar.addSubview(forwardButton)
        toolbar.addSubview(reloadButton)
        toolbar.addSubview(actionButton)
        toolbar.addSubview(doneButton)

        setupConstraints()
        setupActions()
        setupWebViewObservers()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            forwardButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            reloadButton.leadingAnchor.constraint(equalTo: forwardButton.trailingAnchor, constant: 8),
            reloadButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            actionButton.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -8),
            actionButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            doneButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -8),
            doneButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }

    private func updateToolbarConstraints() {
        if showsToolbar {
            toolbar.isHidden = false
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
        } else {
            toolbar.isHidden = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
    }

    private func setupActions() {
        backButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.webView.ls_goBack()
        }

        forwardButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.webView.ls_goForward()
        }

        reloadButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.webView.ls_reload()
        }

        actionButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.showActionSheet()
        }

        doneButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func setupWebViewObservers() {
        webView.onLoadingStateChanged = { [weak self] isLoading in
            self?.updateNavigationButtons()
        }

        webView.onURLChanged = { [weak self] _ in
            self?.updateNavigationButtons()
        }
    }

    // MARK: - 更新方法

    private func updateNavigationButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward

        if webView.isLoading {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            reloadButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)

            reloadButton.ls_removeAllActions()
            reloadButton.ls_addAction(for: .touchUpInside) { [weak self] in
                self?.webView.ls_stopLoading()
            }
        } else {
            reloadButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)

            reloadButton.ls_removeAllActions()
            reloadButton.ls_addAction(for: .touchUpInside) { [weak self] in
                self?.webView.ls_reload()
            }
        }
    }

    // MARK: - 动作表单

    private func showActionSheet() {
        guard let url = webView.currentURL else { return }

        let actions = [
            LSActionController.Action.default("在 Safari 中打开") { [weak self] in
                self?.openInSafari(url)
            },
            LSActionController.Action.default("复制链接") { [weak self] in
                UIPasteboard.general.url = url
                self?.showToast("链接已复制")
            },
            LSActionController.Action.default("分享") { [weak self] in
                self?.shareURL(url)
            }
        ]

        let actionSheet = LSActionSheetController.actionSheet(actions: actions)
        present(actionSheet, animated: true)
    }

    private func openInSafari(_ url: URL) {
        UIApplication.shared.open(url)
    }

    private func shareURL(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    private func showToast(_ message: String) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.hide(animated: true, afterDelay: 1.5)
    }
}

// MARK: - UIViewController Extension (WebView)

public extension UIViewController {

    /// 显示 WebView
    func ls_showWebView(
        url: URL,
        showsToolbar: Bool = true,
        animated: Bool = true
    ) -> LSWebViewController {
        let webViewController = LSWebViewController(url: url)
        webViewController.showsToolbar = showsToolbar

        if navigationController == nil {
            present(webViewController, animated: animated)
        } else {
            navigationController?.pushViewController(webViewController, animated: animated)
        }

        return webViewController
    }

    /// 显示 HTML 内容
    func ls_showHTML(
        html: String,
        baseURL: URL? = nil,
        showsToolbar: Bool = false,
        animated: Bool = true
    ) -> LSWebViewController {
        let webViewController = LSWebViewController(htmlString: html, baseURL: baseURL)
        webViewController.showsToolbar = showsToolbar

        if navigationController == nil {
            present(webViewController, animated: animated)
        } else {
            navigationController?.pushViewController(webViewController, animated: animated)
        }

        return webViewController
    }
}

// MARK: - String Extension (HTML)

public extension String {

    /// 转义 HTML
    var ls_escapedHTML: String {
        var escaped = self
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&#39;")
        return escaped
    }

    /// 基础 HTML 模板
    func ls_htmlTemplate(title: String? = nil, style: String? = nil) -> String {
        let htmlTitle
        if let tempHtmltitle = title {
            htmlTitle = tempHtmltitle
        } else {
            htmlTitle = "网页"
        }
        let css
        if let tempCss = style {
            css = tempCss
        } else {
            css = ""
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(htmlTitle.ls_escapedHTML)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    margin: 0;
                    padding: 16px;
                    line-height: 1.6;
                    color: #333;
                }
                \(css)
            </style>
        </head>
        <body>
            \(self)
        </body>
        </html>
        """
    }
}

#endif
