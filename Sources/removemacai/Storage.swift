import AppKit
import Foundation

/// Space RemoveMacAI can give back. Files go to the Trash, so nothing is
/// gone until the Trash is emptied.
struct StorageItem: Identifiable {
  enum Kind {
    /// Files and folders moved to the Trash.
    case files
    /// Unavailable simulators, deleted by simctl.
    case simulators
    /// Time Machine local snapshots, deleted by tmutil.
    case snapshots
  }

  let id: String
  let title: String
  let detail: String
  var caveat: String? = nil
  var kind: Kind = .files
  /// What it would remove right now.
  var paths: [String] = []
  var bytes: Int64 = 0
  var count: Int = 0

  /// Simulators and snapshots are deleted by their own tools, not moved to the Trash.
  var permanent: Bool { kind != .files }
}

enum Storage {
  static let home = FileManager.default.homeDirectoryForCurrentUser.path

  /// Optional Apple apps that come with some Macs and reinstall free from the App Store.
  static let appleApps: [(id: String, app: String, extra: [String])] = [
    ("garageband", "GarageBand", [
      "/Library/Application Support/GarageBand", "/Library/Application Support/Logic",
      "/Library/Audio/Apple Loops/Apple",
    ]),
    ("imovie", "iMovie", []),
    ("keynote", "Keynote", []),
    ("numbers", "Numbers", []),
    ("pages", "Pages", []),
  ]

  /// Caches macOS keeps under names without the com.apple. prefix.
  static let appleCaches: Set<String> = [
    "amsdatamigratortool", "animoji", "apple", "askpermissiond", "cloudkit", "colorsync", "crashreporter",
    "energykit", "familycircle", "familycircled", "gamekit", "geoservices", "icloudmailagent", "jetpackcache",
    "maps", "metal", "passkit", "protectedcloudstorage", "screentimeagent", "siritts", "speechsynthesis",
    "storeassetd", "storedownloadd",
  ]

  static func isAppleCache(_ path: String) -> Bool {
    let name = (path as NSString).lastPathComponent.lowercased()
    return name.hasPrefix("com.apple.") || appleCaches.contains(name)
  }

  /// Apps that share GarageBand's sound library, by bundle identifier.
  static let soundLibraryApps = ["com.apple.logic10": "Logic Pro", "com.apple.mainstage3": "MainStage"]

  /// The sound library apps installed anywhere Launch Services knows of,
  /// including an external disk.
  static func soundLibraryUsers(_ apps: [String: String] = soundLibraryApps) -> [String] {
    apps.filter { !NSWorkspace.shared.urlsForApplications(withBundleIdentifier: $0.key).isEmpty }
      .map(\.value).sorted()
  }

  /// Finds what can go and how big it is. Slow on big caches; call it off the main thread.
  static func scan() -> [StorageItem] {
    var items: [StorageItem] = []

    let wallpaper = home + "/Library/Application Support/com.apple.wallpaper"
    let aerialsInUse = plistText(wallpaper + "/Store/Index.plist").contains("aerial")
    items.append(files(
      id: "aerials", title: "航拍壁纸视频",
      detail: "动态航拍壁纸和屏保的视频。选择时 macOS 会重新下载。",
      caveat: aerialsInUse ? "你正在使用航拍壁纸或屏保，macOS 会重新下载。" : nil,
      paths: children(wallpaper + "/aerials/videos")
        + children("/Library/Application Support/com.apple.idleassetsd/Customer")))

    items.append(files(
      id: "installers", title: "macOS 安装器",
      detail: "升级后留在应用程序文件夹中的旧“安装 macOS”应用。",
      paths: children("/Applications").filter {
        let name = ($0 as NSString).lastPathComponent
        return name.hasPrefix("Install macOS") && name.hasSuffix(".app")
      }))

    items.append(files(
      id: "ios-firmware", title: "iPhone 和 iPad 更新文件",
      detail: "访达为 iPhone 和 iPad 下载的软件更新文件。需要时会重新下载。",
      paths: children(home + "/Library/iTunes/iPhone Software Updates")
        + children(home + "/Library/iTunes/iPad Software Updates")))

    let xcode = home + "/Library/Developer/Xcode"
    items.append(files(
      id: "derived-data", title: "Xcode 构建数据",
      detail: "Xcode 的 DerivedData 文件夹。下次构建时 Xcode 会重新生成。",
      paths: children(xcode + "/DerivedData")))
    items.append(files(
      id: "device-support", title: "Xcode 设备支持",
      detail: "Xcode 从你连接过的每台 iPhone、iPad 和 Watch 复制的调试符号。下次连接时会再次复制。",
      paths: ["iOS", "watchOS", "tvOS", "visionOS"].flatMap { children(xcode + "/\($0) DeviceSupport") }))

    var simulators = StorageItem(
      id: "simulators", title: "不可用的模拟器",
      detail: "对应已不再安装的运行环境的模拟器，无法运行。",
      caveat: "立即删除，不会移到废纸篓。", kind: .simulators)
    let unavailable = unavailableSimulators()
    simulators.paths = unavailable
    simulators.count = unavailable.count
    simulators.bytes = unavailable.reduce(0) { $0 + size($1) }
    items.append(simulators)

    items.append(files(
      id: "caches", title: "应用缓存",
      detail: "应用为加快加载保留的文件。应用会重新生成，因此之后的首次启动可能变慢。",
      caveat: "请先退出你的应用。RemoveMacAI 已知的 macOS 缓存不会被触碰。",
      paths: children(home + "/Library/Caches").filter { !isAppleCache($0) }))

    let sharing = soundLibraryUsers()
    for app in appleApps {
      let path = "/Applications/\(app.app).app"
      guard FileManager.default.fileExists(atPath: path) else { continue }
      let keepExtra = !app.extra.isEmpty && !sharing.isEmpty
      items.append(files(
        id: app.id, title: app.app,
        detail: "Apple 的可选应用之一。可从 App Store 免费重新安装。",
        caveat: keepExtra ? "Its sound library stays, because \(sharing.joined(separator: " and ")) uses it too." : nil,
        paths: [path] + (keepExtra ? [] : app.extra.filter { FileManager.default.fileExists(atPath: $0) })))
    }

    var snapshots = StorageItem(
      id: "snapshots", title: "Time Machine 本地快照",
      detail: "Time Machine 在两次备份之间保留在本磁盘上的每小时副本。macOS 将其计为系统数据。",
      caveat: "立即删除，不会移到废纸篓。备份磁盘上的备份不受影响。",
      kind: .snapshots)
    snapshots.paths = localSnapshotDates()
    snapshots.count = snapshots.paths.count
    items.append(snapshots)

    return items.filter { $0.kind == .files ? $0.bytes > 0 : !$0.paths.isEmpty }
  }

  static func files(id: String, title: String, detail: String, caveat: String? = nil, paths: [String]) -> StorageItem {
    // Folders macOS won't let us read measure 0; they can't be moved either, so leave them out.
    let sized = paths.map { ($0, size($0)) }.filter { $0.1 > 0 }
    var item = StorageItem(id: id, title: title, detail: detail, caveat: caveat, paths: sized.map(\.0))
    item.count = sized.count
    item.bytes = sized.reduce(0) { $0 + $1.1 }
    return item
  }

  static func plistText(_ path: String) -> String {
    guard let data = FileManager.default.contents(atPath: path),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
    else { return "" }
    return "\(plist)".lowercased()
  }

  static func children(_ folder: String) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? [])
      .filter { $0 != ".DS_Store" }
      .map { folder + "/" + $0 }
  }

  /// Allocated bytes of a file or folder.
  static func size(_ path: String) -> Int64 {
    let url = URL(fileURLWithPath: path)
    let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
    guard let top = try? url.resourceValues(forKeys: Set(keys)) else { return 0 }
    if top.isSymbolicLink == true { return 0 }
    if top.isDirectory != true { return Int64(top.totalFileAllocatedSize ?? 0) }
    var total: Int64 = 0
    let walker = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: [], errorHandler: { _, _ in true })
    while let file = walker?.nextObject() as? URL {
      total += Int64((try? file.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
    }
    return total
  }

  static func unavailableSimulators() -> [String] {
    guard FileManager.default.fileExists(atPath: "/usr/bin/xcrun"),
      Shell.run("/usr/bin/xcode-select", ["-p"]).ok
    else { return [] }
    let result = Shell.run("/usr/bin/xcrun", ["simctl", "list", "devices", "unavailable", "-j"])
    guard result.ok, let data = result.output.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let runtimes = json["devices"] as? [String: [[String: Any]]]
    else { return [] }
    return runtimes.values.flatMap { $0 }.compactMap { $0["dataPath"] as? String }
      .map { ($0 as NSString).deletingLastPathComponent }
  }

  /// Dates of Time Machine's own local snapshots. macOS update snapshots are not included.
  static func localSnapshotDates() -> [String] {
    let out = Shell.run("/usr/bin/tmutil", ["listlocalsnapshotdates", "/"]).output
    return out.split(separator: "\n").map(String.init).filter { $0.first?.isNumber == true }
  }

  /// Removes the items: files to the Trash, simulators and snapshots by their
  /// own tools. Things only an administrator can move share one prompt.
  struct CleanResult {
    var problems: [String] = []
    /// Items macOS protects, which nobody can move without turning protections off.
    var protected = 0
    var protectedBytes: Int64 = 0
  }

  static func clean(_ items: [StorageItem]) -> CleanResult {
    var result = CleanResult()
    var adminCommands: [String] = []
    let trash = home + "/.Trash"
    for item in items {
      switch item.kind {
      case .files:
        for path in item.paths {
          do {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
          } catch {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            // Only things another user owns need an administrator. Something
            // the user owns but can't move is protected by macOS, and an
            // administrator can't move it either.
            let owner = (try? FileManager.default.attributesOfItem(atPath: path)[.ownerAccountID] as? NSNumber)?.uint32Value
            guard let owner, owner != getuid() else {
              result.protected += 1
              result.protectedBytes += size(path)
              continue
            }
            let name = (path as NSString).lastPathComponent
            let target = trash + "/" + uniqueName(name, in: trash)
            adminCommands.append("/bin/mv -f \(Shell.quote(path)) \(Shell.quote(target))")
          }
        }
      case .simulators:
        let run = Shell.run("/usr/bin/xcrun", ["simctl", "delete", "unavailable"])
        if !run.ok { result.problems.append("模拟器：\(run.output.trimmed)") }
      case .snapshots:
        for date in item.paths { adminCommands.append("/usr/bin/tmutil deletelocalsnapshots \(Shell.quote(date))") }
      }
    }
    if !adminCommands.isEmpty {
      let run = Shell.admin(adminCommands, prompt: "RemoveMacAI 需要你的密码来移动只有管理员能更改的项目。")
      if !run.ok { result.problems.append(Shell.adminError(run)) }
    }
    return result
  }

  static func uniqueName(_ name: String, in folder: String) -> String {
    var candidate = name
    var n = 2
    while FileManager.default.fileExists(atPath: folder + "/" + candidate) {
      let ext = (name as NSString).pathExtension
      let base = (name as NSString).deletingPathExtension
      candidate = ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)"
      n += 1
    }
    return candidate
  }
}
