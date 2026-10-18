import Foundation

/// A sidebar section of the catalog.
enum TweakGroup: String, CaseIterable, Identifiable {
  case privacy, annoyances, apps, finder, windows, typing

  var id: String { rawValue }

  var title: String {
    switch self {
    case .privacy: return "隐私"
    case .annoyances: return "烦扰项"
    case .apps: return "Apple 应用"
    case .finder: return "访达"
    case .windows: return "程序坞与窗口"
    case .typing: return "输入"
    }
  }

  var symbol: String {
    switch self {
    case .privacy: return "hand.raised"
    case .annoyances: return "bell.slash"
    case .apps: return "square.grid.2x2"
    case .finder: return "folder"
    case .windows: return "dock.rectangle"
    case .typing: return "keyboard"
    }
  }

  var summary: String {
    switch self {
    case .privacy: return "阻止你的 Mac 向 Apple 发送分析、搜索和录音数据。"
    case .annoyances: return "关掉那些没人想要的弹窗、小组件和意外打扰。"
    case .apps: return "静默你不用的 Apple 应用。macOS 不允许删除它们。"
    case .finder: return "显示访达隐藏的内容，并阻止它留下的杂乱文件。"
    case .windows: return "更快的程序坞，去掉多余的图标和动画。"
    case .typing: return "阻止 macOS 改写你的输入。"
    }
  }
}

/// A named starting selection.
enum Preset: String, CaseIterable, Identifiable {
  case recommended, privacy

  var id: String { rawValue }

  var title: String {
    switch self {
    case .recommended: return "推荐设置"
    case .privacy: return "最大隐私"
    }
  }

  var summary: String {
    switch self {
    case .recommended: return "关闭 Apple Intelligence，无分析、无广告，弹窗更少。你依赖的功能不会停止工作。"
    case .privacy: return "包含推荐设置的全部内容，另加关闭 Game Center 和 Safari 搜索建议。"
    }
  }
}

/// One setting a tweak changes.
enum Change: Equatable {
  /// A restriction key the profile sets to false.
  case restriction(String)
  /// A preference the profile forces, so it can't be changed back by hand.
  case forced(String, String, PlistValue)
  /// A preference written for the current user.
  case pref(String, String, PlistValue, currentHost: Bool = false)
  /// A launchd agent in the user's session, disabled and unloaded.
  case service(String)
  /// Music's application job, whose label changes when macOS replaces its files.
  case musicLaunches
  /// Dock icons removed by bundle identifier.
  case dockRemove([String])
  /// ~/Library shown in Finder.
  case showLibrary

  var inProfile: Bool {
    switch self {
    case .restriction, .forced: return true
    default: return false
    }
  }

  /// The journal key; two tweaks never change the same thing.
  var key: String {
    switch self {
    case .restriction(let k): return "restriction:\(k)"
    case .forced(let d, let k, _): return "forced:\(d):\(k)"
    case .pref(let d, let k, _, let host): return "pref:\(d):\(k)" + (host ? ":currentHost" : "")
    case .service(let l): return "service:\(l)"
    case .musicLaunches: return "application:com.apple.Music"
    case .dockRemove(let ids): return "dock:" + ids.joined(separator: ",")
    case .showLibrary: return "library"
    }
  }

  /// The equivalent command, shown before anything changes.
  var command: String {
    switch self {
    case .restriction(let k): return "profile: com.apple.applicationaccess \(k) = false"
    case .forced(let d, let k, let v): return "profile: \(d) \(k) = \(v) (locked)"
    case .pref(let d, let k, let v, let host):
      let type: String
      switch v {
      case .bool: type = "-bool"
      case .int: type = "-int"
      case .double: type = "-float"
      case .string: type = "-string"
      }
      let value: String
      if case .string(let s) = v { value = "\"\(s)\"" } else { value = v.description }
      return "defaults\(host ? " -currentHost" : "") write \(d) \"\(k)\" \(type) \(value)"
    case .service(let l): return "launchctl disable gui/$UID/\(l) && launchctl bootout gui/$UID/\(l)"
    case .musicLaunches:
      guard let label = try? MusicLaunch.label() else { return "could not identify Music's application launch entry" }
      return Change.service(label).command
    case .dockRemove(let ids): return "remove from the Dock: " + ids.joined(separator: ", ")
    case .showLibrary: return "chflags nohidden ~/Library"
    }
  }
}

struct Tweak: Identifiable {
  let id: String
  let group: TweakGroup
  let title: String
  let detail: String
  var caveat: String? = nil
  let changes: [Change]
  /// Processes that read the setting only at launch.
  var restart: [String] = []
  var presets: Set<Preset> = []
  /// The first macOS version (major, minor) that has the setting.
  var since: (Int, Int) = (14, 0)

  var inProfile: Bool { changes.contains { $0.inProfile } }

  var supported: Bool {
    let os = ProcessInfo.processInfo.operatingSystemVersion
    return (os.majorVersion, os.minorVersion) >= since
  }
}

enum Tweaks {
  static let all: [Tweak] = [
    // MARK: Privacy
    Tweak(
      id: "analytics", group: .privacy, title: "关闭 Mac 分析",
      detail: "阻止你的 Mac 向 Apple 和应用开发者发送诊断与使用数据。",
      changes: [.restriction("allowDiagnosticSubmission")], presets: [.recommended, .privacy]),
    Tweak(
      id: "personalized-ads", group: .privacy, title: "关闭个性化广告",
      detail: "阻止 Apple 利用你在其应用中的行为，在 App Store、新闻和股票中投放定向广告。",
      changes: [.restriction("allowApplePersonalizedAdvertising")], presets: [.recommended, .privacy]),
    Tweak(
      id: "improve-siri", group: .privacy, title: "关闭 Siri 与听写改进",
      detail: "阻止 Apple 存储和审查你的 Siri 与听写请求录音。",
      changes: [.forced("com.apple.assistant.support", "Siri Data Sharing Opt-In Status", .int(2))],
      presets: [.recommended, .privacy]),
    Tweak(
      id: "improve-search", group: .privacy, title: "关闭搜索改进",
      detail: "阻止 Apple 保留你的聚焦搜索、Safari 和查询搜索记录以改进搜索。",
      changes: [.forced("com.apple.assistant.support", "Search Queries Data Sharing Status", .int(2))],
      presets: [.recommended, .privacy]),
    Tweak(
      id: "spotlight-web", group: .privacy, title: "关闭聚焦搜索的互联网结果",
      detail: "让聚焦搜索仅在本机进行，而不是发送给 Apple 获取网页建议。",
      changes: [.restriction("allowSpotlightInternetResults")], presets: [.recommended, .privacy]),
    Tweak(
      id: "lookup-suggestions", group: .privacy, title: "关闭查询建议",
      detail: "阻止查询将你选中的文字发送给 Apple 获取网页结果。",
      changes: [.forced("com.apple.lookup.shared", "LookupSuggestionsDisabled", .bool(true))],
      presets: [.recommended, .privacy]),
    Tweak(
      id: "safari-suggestions", group: .privacy, title: "关闭 Safari 搜索建议",
      detail: "阻止 Safari 将地址栏输入发送给你的搜索引擎和 Apple。",
      caveat: "地址栏不再在你输入时提供搜索建议。",
      changes: [
        .forced("com.apple.Safari", "UniversalSearchEnabled", .bool(false)),
        .forced("com.apple.Safari", "SuppressSearchSuggestions", .bool(true)),
      ], presets: [.privacy]),
    Tweak(
      id: "game-center", group: .privacy, title: "关闭 Game Center",
      detail: "关闭 Game Center，包括登录提示、好友请求和通知。",
      caveat: "依赖 Game Center 保存进度或在线联机的游戏将失去这些功能。",
      changes: [.restriction("allowGameCenter")], presets: [.privacy]),

    // MARK: Annoyances
    Tweak(
      id: "click-to-desktop", group: .annoyances, title: "停止点击壁纸时隐藏窗口",
      detail: "阻止误点壁纸时所有窗口滑开隐藏。",
      changes: [.pref("com.apple.WindowManager", "EnableStandardClickToShowDesktop", .bool(false))],
      presets: [.recommended]),
    Tweak(
      id: "desktop-widgets", group: .annoyances, title: "隐藏桌面小组件",
      detail: "隐藏桌面上的小组件，包括台前调度中的。",
      changes: [
        .pref("com.apple.WindowManager", "StandardHideWidgets", .bool(true)),
        .pref("com.apple.WindowManager", "StageManagerHideWidgets", .bool(true)),
      ]),
    Tweak(
      id: "media-keys", group: .annoyances, title: "关闭播放、暂停和跳转键",
      detail: "关闭媒体键背后的服务，使播放键无法打开音乐。",
      caveat: "这些按键在所有应用中都会失效，包括 VLC 和 Spotify。若想保留按键、仅阻止音乐打开，请改用“阻止音乐启动”。",
      changes: [.service("com.apple.rcd")]),
    Tweak(
      id: "music-launches", group: .annoyances, title: "阻止音乐启动，包括来自 AirPods 的",
      detail: "禁用音乐的应用启动入口，AirPods 按压不再打开它。不会安装后台辅助程序或配置描述文件。",
      caveat: "同时关闭音乐并阻止手动启动。macOS 更新替换音乐文件后请重新应用。",
      changes: [.musicLaunches]),
    Tweak(
      id: "iphone-mirroring", group: .annoyances, title: "关闭 iPhone 镜像",
      detail: "关闭 iPhone 镜像，应用及其提示都会消失。",
      changes: [.restriction("allowiPhoneMirroring")], since: (15, 0)),

    // MARK: Apple apps
    Tweak(
      id: "music-classic", group: .apps, title: "关闭音乐应用中的 Apple Music",
      detail: "将音乐应用变回只播放你自己资料库的普通播放器，不再有商店和订阅提示。",
      caveat: "Apple Music 订阅者将失去流媒体播放。",
      changes: [.restriction("allowMusicService")]),
    Tweak(
      id: "book-store", group: .apps, title: "关闭书店",
      detail: "从图书应用中移除商店，保留你自己的图书。",
      changes: [.restriction("allowBookstore")], since: (15, 0)),
    Tweak(
      id: "dock-apple-apps", group: .apps, title: "从程序坞移除不用的 Apple 应用",
      detail: "从程序坞移除新闻、电视、音乐、播客、图书、无边记、地图和股票。应用本身保持安装。",
      changes: [.dockRemove([
        "com.apple.news", "com.apple.TV", "com.apple.Music", "com.apple.podcasts", "com.apple.iBooksX",
        "com.apple.freeform", "com.apple.Maps", "com.apple.stocks",
      ])], restart: ["Dock"]),

    // MARK: Finder
    Tweak(
      id: "file-extensions", group: .finder, title: "显示文件扩展名",
      detail: "显示每个文件的完整名称，更容易识别伪装成文档的文件。",
      changes: [.pref(Prefs.global, "AppleShowAllExtensions", .bool(true))], restart: ["访达"],
      presets: [.recommended, .privacy]),
    Tweak(
      id: "hidden-files", group: .finder, title: "显示隐藏文件",
      detail: "显示 macOS 隐藏的文件，如 .gitignore 和 .zshrc。也可按 Command-Shift-句号切换。",
      changes: [.pref("com.apple.finder", "AppleShowAllFiles", .bool(true))], restart: ["访达"]),
    Tweak(
      id: "path-bar", group: .finder, title: "显示路径栏",
      detail: "在每个访达窗口底部显示当前文件夹的位置。",
      changes: [.pref("com.apple.finder", "ShowPathbar", .bool(true))], restart: ["访达"],
      presets: [.recommended]),
    Tweak(
      id: "status-bar", group: .finder, title: "显示状态栏",
      detail: "在访达窗口底部显示项目数量和可用空间。",
      changes: [.pref("com.apple.finder", "ShowStatusBar", .bool(true))], restart: ["访达"]),
    Tweak(
      id: "folders-first", group: .finder, title: "文件夹排在文件上方",
      detail: "按名称排序时文件夹排在文件上方。",
      changes: [.pref("com.apple.finder", "_FXSortFoldersFirst", .bool(true))], restart: ["访达"],
      presets: [.recommended]),
    Tweak(
      id: "search-this-folder", group: .finder, title: "搜索当前文件夹",
      detail: "让访达只搜索你所在的文件夹，而不是整个 Mac。",
      changes: [.pref("com.apple.finder", "FXDefaultSearchScope", .string("SCcf"))], restart: ["访达"]),
    Tweak(
      id: "extension-warning", group: .finder, title: "跳过更改扩展名警告",
      detail: "阻止访达在你每次更改文件扩展名时要求确认。",
      changes: [.pref("com.apple.finder", "FXEnableExtensionChangeWarning", .bool(false))], restart: ["访达"]),
    Tweak(
      id: "path-in-title", group: .finder, title: "在标题栏显示完整路径",
      detail: "在访达窗口顶部显示完整文件夹路径。",
      changes: [.pref("com.apple.finder", "_FXShowPosixPathInTitle", .bool(true))], restart: ["访达"]),
    Tweak(
      id: "network-ds-store", group: .finder, title: "停止在网络驱动器上生成 .DS_Store",
      detail: "阻止访达在其他电脑的共享文件夹中留下 .DS_Store 文件。",
      changes: [.pref("com.apple.desktopservices", "DSDontWriteNetworkStores", .bool(true))],
      presets: [.recommended]),
    Tweak(
      id: "trash-30-days", group: .finder, title: "30 天后自动清空废纸篓",
      detail: "删除在废纸篓中超过 30 天的项目，避免磁盘被占满。",
      changes: [.pref("com.apple.finder", "FXRemoveOldTrashItems", .bool(true))], restart: ["访达"]),
    Tweak(
      id: "save-locally", group: .finder, title: "新文稿保存在此 Mac",
      detail: "让存储对话框默认存储到你的 Mac 而非 iCloud 云盘。",
      changes: [.pref(Prefs.global, "NSDocumentSaveNewDocumentsToCloud", .bool(false))]),
    Tweak(
      id: "expanded-save", group: .finder, title: "展开存储对话框",
      detail: "以完整文件夹浏览器打开存储对话框，而非精简版。",
      changes: [.pref(Prefs.global, "NSNavPanelExpandedStateForSaveMode", .bool(true))]),
    Tweak(
      id: "show-library", group: .finder, title: "显示“资源库”文件夹",
      detail: "显示个人文件夹中隐藏的“资源库”文件夹。",
      changes: [.showLibrary]),

    // MARK: Dock and windows
    Tweak(
      id: "dock-recents", group: .windows, title: "在程序坞隐藏最近使用的应用",
      detail: "阻止程序坞添加你最近打开的应用。",
      changes: [.pref("com.apple.dock", "show-recents", .bool(false))], restart: ["Dock"],
      presets: [.recommended]),
    Tweak(
      id: "dock-delay", group: .windows, title: "移除程序坞自动隐藏延迟",
      detail: "隐藏的程序坞立即显示，而非等待半秒。",
      changes: [.pref("com.apple.dock", "autohide-delay", .double(0))], restart: ["Dock"]),
    Tweak(
      id: "dock-bounce", group: .windows, title: "停止程序坞图标跳动",
      detail: "阻止应用打开时程序坞图标跳动。",
      changes: [.pref("com.apple.dock", "launchanim", .bool(false))], restart: ["Dock"]),
    Tweak(
      id: "minimize-to-app", group: .windows, title: "最小化窗口到应用图标",
      detail: "将最小化的窗口收进应用图标，而不是堆满程序坞。",
      changes: [.pref("com.apple.dock", "minimize-to-application", .bool(true))], restart: ["Dock"]),
    Tweak(
      id: "window-animations", group: .windows, title: "关闭窗口打开动画",
      detail: "新窗口立即打开，而非缩放动画。",
      changes: [.pref(Prefs.global, "NSAutomaticWindowAnimationsEnabled", .bool(false))]),
    Tweak(
      id: "tile-margins", group: .windows, title: "移除平铺窗口之间的间隙",
      detail: "移除你平铺到屏幕两侧的窗口周围的边距。",
      changes: [.pref("com.apple.WindowManager", "EnableTiledWindowMargins", .bool(false))], since: (15, 0)),
    Tweak(
      id: "screenshot-shadow", group: .windows, title: "移除窗口截图阴影",
      detail: "截取窗口截图时去掉周围的大片投影。",
      changes: [.pref("com.apple.screencapture", "disable-shadow", .bool(true))], restart: ["SystemUIServer"]),

    // MARK: Typing
    Tweak(
      id: "autocorrect", group: .typing, title: "关闭自动纠正",
      detail: "阻止 macOS 在你输入时自动纠正词语。",
      changes: [.pref(Prefs.global, "NSAutomaticSpellingCorrectionEnabled", .bool(false))]),
    Tweak(
      id: "smart-punctuation", group: .typing, title: "关闭智能引号和破折号",
      detail: "保留你输入的直引号和双连字符，代码和终端需要它们。",
      changes: [
        .pref(Prefs.global, "NSAutomaticQuoteSubstitutionEnabled", .bool(false)),
        .pref(Prefs.global, "NSAutomaticDashSubstitutionEnabled", .bool(false)),
      ]),
    Tweak(
      id: "double-space-period", group: .typing, title: "关闭双击空格输入句号",
      detail: "阻止两个空格变成句号。",
      changes: [.pref(Prefs.global, "NSAutomaticPeriodSubstitutionEnabled", .bool(false))]),
    Tweak(
      id: "auto-capitalize", group: .typing, title: "关闭自动大写",
      detail: "阻止 macOS 将每个句子的首字母大写。",
      changes: [.pref(Prefs.global, "NSAutomaticCapitalizationEnabled", .bool(false))]),
    Tweak(
      id: "key-repeat", group: .typing, title: "长按重复按键而非显示声调菜单",
      detail: "长按时重复按键，而不是打开声调菜单。",
      caveat: "请改用 Option 快捷键或字符检视器输入声调。",
      changes: [.pref(Prefs.global, "ApplePressAndHoldEnabled", .bool(false))]),
  ]

  static func tweak(_ id: String) -> Tweak? { all.first { $0.id == id } }

  /// Maximum privacy builds on Recommended.
  static func preset(_ preset: Preset) -> [Tweak] {
    let names: Set<Preset> = preset == .privacy ? [.recommended, .privacy] : [preset]
    return all.filter { !$0.presets.isDisjoint(with: names) && $0.supported }
  }
}
