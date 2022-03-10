//
//  LaunchController.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa

class LaunchController: NSViewController, NSWindowDelegate {
    
    var loginSheetWinController: NSWindowController?
    var installerWinController: NSWindowController?
    var patchWinController: NSWindowController?
    var newsTable: FrontierTableView!
    var topicsTable: FrontierTableView!
    var otp: OTP? = nil
    
    @IBOutlet private var loginButton: NSButton!
    @IBOutlet private var userField: NSTextField!
    @IBOutlet private var passwdField: NSTextField!
    @IBOutlet weak var otpField: NSTextField!
    @IBOutlet weak var otpCheck: NSButton!
    @IBOutlet private var scrollView: AnimatingScrollView!
    @IBOutlet private var newsView: NSScrollView!
    @IBOutlet private var topicsView: NSScrollView!
    
    override func loadView() {
        super.loadView()
        setupOTP()
        ACT.observe()
        print(Steam.ticket?.0)
        NotificationCenter.default.addObserver(self,selector: #selector(installDone(_:)),name: .installDone, object: nil)
        if #available(macOS 11.0, *) {
            newsTable = FrontierTableView(icon: NSImage(systemSymbolName: "newspaper", accessibilityDescription: nil)!)
            topicsTable = FrontierTableView(icon: NSImage(systemSymbolName: "newspaper.fill", accessibilityDescription: nil)!)
        }
        else {
            newsTable = FrontierTableView(icon: NSImage(size: NSSize(width: 20, height: 20)))
            topicsTable = FrontierTableView(icon: NSImage(size: NSSize(width: 20, height: 20)))
        }
        newsView.documentView = newsTable.tableView
        topicsView.documentView = topicsTable.tableView
        DispatchQueue.global(qos: .userInitiated).async {
            FFXIVSettings.checkBoot { patches in
                if let patches = patches {
                    self.startPatch(patches)
                }
                DispatchQueue.main.async {
                    self.loginButton.isEnabled = true
                }
            }
        }
        DispatchQueue.global(qos: .userInteractive).async {
            if let frontier = Frontier.info {
                self.populateNews(frontier)
            }
        }
    }
    
    @objc func installDone(_ notif: Notification) {
        checkBoot()
    }
    
    func checkBoot() {
        FFXIVSettings.checkBoot { patches in
            if let patches = patches {
                self.startPatch(patches)
            }
            DispatchQueue.main.async {
                self.loginButton.isEnabled = true
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        update()
        loginSheetWinController = storyboard?.instantiateController(withIdentifier: "LoginSheet") as? NSWindowController
        installerWinController = storyboard?.instantiateController(withIdentifier: "InstallerWindow") as? NSWindowController
        patchWinController = storyboard?.instantiateController(withIdentifier: "PatchSheet") as? NSWindowController
        view.window?.delegate = self
        view.window?.isMovableByWindowBackground = true
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
    
    private func populateNews(_ info: Frontier.Info) {
        DispatchQueue.main.async {
            self.topicsTable.add(items: info.topics)
            self.newsTable.add(items: info.pinned + info.news)
            self.scrollView.banners = info.banner
        }
    }
    
    private func update() {
        userField.stringValue = FFXIVSettings.credentials?.username ?? ""
        passwdField.stringValue = FFXIVSettings.credentials?.password ?? ""
    }
    
    @IBAction func doLogin(_ sender: Any) {
        doLogin()
    }
    
    func doLogin() {
        let queue = OperationQueue()
        let op = LoginOperation()
        view.window?.beginSheet(loginSheetWinController!.window!)
        FFXIVSettings.credentials = FFXIVLoginCredentials(username: userField.stringValue, password: passwdField.stringValue, oneTimePassword: otpField.stringValue)
        op.completionBlock = {
            switch op.loginResult {
            case .success(let sid)?:
                DispatchQueue.main.async {
                    self.startGame(sid: sid)
                }
            case .incorrectCredentials:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    self.otpField.stringValue = ""
                }
            case .clientUpdate(let patches):
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.startPatch(patches)
                    }
                }
            case .noInstall:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                    self.view.window?.beginSheet(self.installerWinController!.window!)
                }
            default:
                DispatchQueue.main.async {
                    self.loginSheetWinController?.window?.close()
                }
            }
        }
        queue.addOperation(op)
    }
    
    func startPatch(_ patches: [Patch]) {
        DispatchQueue.main.async {
            self.view.window?.beginSheet(self.patchWinController!.window!)
            let patchController = self.patchWinController!.contentViewController! as! PatchController
            patchController.install(patches)
        }
    }
    
    func startGame(sid: String) {
        let queue = OperationQueue()
        let op = StartGameOperation(sid: sid)
        queue.addOperation(op)
    }

}

final class BannerView: NSImageView {
    
    var banner: Frontier.Info.Banner? {
        didSet {
            self.image = NSImage(contentsOf: URL(string: banner!.lsbBanner)!)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if let banner = banner {
            let url = URL(string: banner.link)!
            NSWorkspace.shared.open(url)
        }
    }

}

final class AnimatingScrollView: NSScrollView {
    
    private var width: CGFloat  {
        return self.contentSize.width
    }
    
    private var height: CGFloat  {
        return self.contentSize.height
    }
    
    private let animationDuration = 2.0
    private let stayDuration = 8.0
    private var index = 0
    private var timer = Timer()
    
    var banners: [Frontier.Info.Banner]? {
        didSet {
            let banners = banners!
            self.documentView?.setFrameSize(NSSize(width: width * CGFloat(banners.count), height: height))
            for (i, banner) in banners.enumerated() {
                let bannerView = BannerView()
                bannerView.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: height)
                bannerView.imageScaling = .scaleNone
                bannerView.banner = banner
                self.documentView?.addSubview(bannerView)
            }
            self.startTimer()
        }
    }
    
    
    private func startTimer() {
        self.timer.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: stayDuration, repeats: true, block: { _ in
            self.animate()
            })
    }
    
    // This will override and cancel any running scroll animations
    override public func scroll(_ clipView: NSClipView, to point: NSPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentView.setBoundsOrigin(point)
        CATransaction.commit()
        super.scroll(clipView, to: point)
        index = Int(floor((point.x + width / 2) / width))
        let snap_x = CGFloat(index) * width
        scroll(toPoint: NSPoint(x: snap_x, y: 0), animationDuration: animationDuration)
        self.startTimer()
    }

    private func scroll(toPoint: NSPoint, animationDuration: Double) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = animationDuration
        contentView.animator().setBoundsOrigin(toPoint)
        reflectScrolledClipView(contentView)
        NSAnimationContext.endGrouping()
    }
    
    private func animate() {
        if let banners = banners {
            index = (index + 1) % banners.count
            self.scroll(toPoint: NSPoint(x: Int(width) * index, y: 0), animationDuration: animationDuration)
        }
    }

}

class FrontierTableView: NSObject {
    static let columnText = "text"
    static let columnIcon = "icon"
    
    var items: [Frontier.Info.News] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var icon: NSImage
    var tableView: NSTableView
    
    init(icon: NSImage) {
        self.icon = icon
        tableView = NSTableView(frame: .zero)
        super.init()
        tableView.intercellSpacing = NSSize(width: 0, height: 9)
        tableView.rowSizeStyle = .large
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        let iconCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: FrontierTableView.columnIcon))
        let textCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: FrontierTableView.columnText))
        iconCol.width = 20
        textCol.width = 433
        tableView.addTableColumn(iconCol)
        tableView.addTableColumn(textCol)
        tableView.target = self
        tableView.action = #selector(onItemClicked)
    }
        
    func add(items: [Frontier.Info.News]) {
        self.items += items
    }
    
    @objc private func onItemClicked() {
        if let url = URL(string: items[abs(tableView.clickedRow)].url) {
            NSWorkspace.shared.open(url)
        }
    }
}


extension FrontierTableView: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch (tableColumn?.identifier)!.rawValue {
        case FrontierTableView.columnIcon:
            return NSImageView(image: icon)
        case FrontierTableView.columnText:
            return createCell(name: items[row].title)
        default:
            fatalError("FrontierTableView identifier not found")
        }
    }
    
    private func createCell(name: String) -> NSView {
        let text = NSTextField(string: name)
        text.cell?.usesSingleLineMode = false
        text.cell?.wraps = true
        text.cell?.lineBreakMode = .byWordWrapping
        text.isEditable = false
        text.isBordered = false
        text.drawsBackground = false
        text.preferredMaxLayoutWidth = 433
        return text
    }

    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return createCell(name: items[row].title).intrinsicContentSize.height
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
}

