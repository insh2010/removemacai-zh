import SwiftUI

/// Small pieces that explain things: help popovers, numbered steps, the
/// safety promises and a drawing of the System Settings profile screen.

struct InfoButton: View {
  let title: String
  let text: String
  @State private var shown = false

  var body: some View {
    Button { shown.toggle() } label: {
      Image(systemName: "info.circle").foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
    .help(title)
    .accessibilityLabel("关于 \(title)")
    .popover(isPresented: $shown, arrowEdge: .bottom) {
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.headline)
        Text(text).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      }
      .padding(14)
      .frame(width: 300, alignment: .leading)
    }
  }
}

enum Explain {
  static let profile = (
    "配置描述文件",
    "macOS 只允许通过配置描述文件保持这些设置锁定，学校和企业也用同样的方式管理 Mac。RemoveMacAI 会展示其内容，由你在系统设置中自行安装。随时可在此移除，或使用撤销功能。"
  )
  static let models = (
    "Apple Intelligence 模型",
    "Apple Intelligence 运行所需的文件，无论你是否使用相关功能，macOS 都会下载。删除它们可释放空间。若重新开启某项功能，macOS 会再次下载所需内容。"
  )
  static let locked = (
    "由描述文件保持关闭",
    "此设置由 RemoveMacAI 描述文件保持关闭，因此 macOS 更新或误点无法将其重新开启。撤销会移除描述文件并归还开关。"
  )
}

struct StepBadge: View {
  let number: Int
  var done = false
  var active = true

  var body: some View {
    ZStack {
      Circle().fill(done ? Color.green : (active ? Color.accentColor : Color.secondary.opacity(0.25)))
      if done {
        Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.white)
      } else {
        Text("\(number)").font(.caption.weight(.bold).monospacedDigit())
          .foregroundStyle(active ? Color.white : Color.secondary)
      }
    }
    .frame(width: 22, height: 22)
    .accessibilityHidden(true)
  }
}

struct Promise: Identifiable {
  let id = UUID()
  let symbol: String
  let title: String
  let detail: String
  var tint: Color = .accentColor
}

enum Promises {
  static let all: [Promise] = [
    Promise(symbol: "eye", title: "每一项更改都先经你确认", detail: "只有你查看列表并点击应用后才会执行。"),
    Promise(symbol: "arrow.uturn.backward", title: "一切皆可撤销", detail: "撤销会恢复每个设置。已删除的模型在功能需要时重新下载。"),
    Promise(symbol: "checkmark.shield", title: "你的 Mac 保持受保护", detail: "系统完整性保护保持开启。/System 内部不会被改动。", tint: .green),
    Promise(symbol: "wifi.slash", title: "数据不会离开你的 Mac", detail: "无账户、无分析、无网络请求。代码在 GitHub 公开。", tint: .green),
  ]
}

struct PromiseCard: View {
  let promise: Promise

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: promise.symbol)
        .font(.title2)
        .foregroundStyle(promise.tint)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 3) {
        Text(promise.title).font(.headline)
        Text(promise.detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    .accessibilityElement(children: .combine)
  }
}

struct SafetyCard: View {
  @Environment(\.openURL) private var openURL
  var showWelcome: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("设计即安全", systemImage: "checkmark.shield.fill")
        .font(.headline)
        .foregroundStyle(.green)
      Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
        GridRow {
          check("每项更改执行前都会经过你确认")
          check("撤销可还原所有更改")
        }
        GridRow {
          check("系统完整性保护保持开启")
          check("无网络请求、无分析数据")
        }
      }
      HStack(spacing: 18) {
        Button("在 GitHub 阅读代码") { openURL(URL(string: "https://github.com/omlahore/RemoveMacAI")!) }
        Button("RemoveMacAI 工作原理") { showWelcome() }
      }
      .buttonStyle(.link)
      .font(.callout)
    }
  }

  func check(_ text: String) -> some View {
    Label {
      Text(text).foregroundStyle(.primary)
    } icon: {
      Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.green)
    }
    .font(.callout)
  }
}

/// A drawing of System Settings at General > Device Management, with the
/// RemoveMacAI profile and its Install button marked. Drawn, not a
/// screenshot, so it stays sharp and follows light and dark mode.
struct SettingsGuide: View {
  var remove = false
  @State private var pulse = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 6) {
        Circle().fill(Color(red: 1, green: 0.37, blue: 0.34)).frame(width: 10, height: 10)
        Circle().fill(Color(red: 1, green: 0.74, blue: 0.18)).frame(width: 10, height: 10)
        Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25)).frame(width: 10, height: 10)
        Text("系统设置").font(.caption).foregroundStyle(.secondary).padding(.leading, 6)
        Spacer()
      }
      .padding(.horizontal, 10)
      .frame(height: 28)
      .background(.quaternary.opacity(0.6))
      HStack(alignment: .top, spacing: 0) {
        VStack(alignment: .leading, spacing: 7) {
          ForEach(["Wi-Fi", "Bluetooth", "网络"], id: \.self) { Text($0) }
          Text("通用")
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor))
          ForEach(["外观", "隐私与安全性"], id: \.self) { Text($0) }
        }
        .font(.caption)
        .padding(10)
        .frame(width: 120, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.quaternary.opacity(0.35))
        VStack(alignment: .leading, spacing: 9) {
          Text("通用 › 设备管理").font(.caption).foregroundStyle(.secondary)
          Text(remove ? "描述文件" : "已下载").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
          HStack(spacing: 8) {
            Image(systemName: "checkmark.shield")
            VStack(alignment: .leading, spacing: 1) {
              Text("RemoveMacAI").font(.caption.weight(.semibold))
              Text(remove ? "选择后点击 −" : "双击查看").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
          }
          .padding(8)
          .background(RoundedRectangle(cornerRadius: 7).fill(.background))
          .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.accentColor, lineWidth: pulse ? 3 : 1.5))
          VStack(alignment: .leading, spacing: 8) {
            Text(remove ? "移除“RemoveMacAI”？" : "“RemoveMacAI”想要安装").font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 6) {
              Spacer()
              Text("取消").font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).stroke(.tertiary))
              Text(remove ? "删除" : "安装…").font(.caption2.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.accentColor.opacity(0.5), lineWidth: pulse ? 4 : 0).padding(-3))
            }
          }
          .padding(8)
          .background(RoundedRectangle(cornerRadius: 7).fill(.background))
          Spacer(minLength: 0)
        }
        .padding(10)
      }
      .frame(height: 200)
    }
    .background(RoundedRectangle(cornerRadius: 10).fill(.background.secondary))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      remove
        ? "System Settings, General, Device Management. Select the RemoveMacAI profile and click the minus button to remove it."
        : "System Settings, General, Device Management. Double-click the RemoveMacAI profile under Downloaded, then click Install.")
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
    }
  }
}
