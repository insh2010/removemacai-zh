import SwiftUI

/// The first-run introduction: what the app does and doesn't do, how the
/// profile step works, and where to start. Shown once, and again from
/// Help > How RemoveMacAI Works or the Overview.
struct WelcomeSheet: View {
  @Environment(AppModel.self) private var model
  @Environment(\.openURL) private var openURL
  @State private var start: Start = .recommended

  enum Start: CaseIterable, Identifiable {
    case recommended, privacy, own
    var id: Self { self }
  }

  var body: some View {
    @Bindable var model = model
    VStack(spacing: 0) {
      Group {
        switch model.welcomePage {
        case 0: intro
        case 1: howItWorks
        default: chooseStart
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: model.welcomePage == 1 ? .top : .center)
      .padding(.horizontal, 36)
      .padding(.top, 30)
      footer
    }
    .frame(width: 680, height: 600)
    .animation(.easeOut(duration: 0.2), value: model.welcomePage)
  }

  var intro: some View {
    VStack(spacing: 22) {
      VStack(spacing: 10) {
        Image(nsImage: NSApp.applicationIconImage)
          .resizable().frame(width: 72, height: 72)
          .accessibilityHidden(true)
        Text("把 Apple Intelligence 从你的 Mac 上移除")
          .font(.title.weight(.bold))
          .multilineTextAlignment(.center)
        Text("RemoveMacAI 会关闭你不用的 Apple Intelligence 功能、删除其下载的模型，并清理 macOS 添加的其他内容。免费且开源。")
          .font(.body).foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 500)
          .fixedSize(horizontal: false, vertical: true)
      }
      Grid(horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
          PromiseCard(promise: Promises.all[0])
          PromiseCard(promise: Promises.all[1])
        }
        GridRow {
          PromiseCard(promise: Promises.all[2])
          PromiseCard(promise: Promises.all[3])
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  var howItWorks: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 6) {
        Text("工作原理").font(.title.weight(.bold))
        Text("三步，可随时停下。").foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      HStack(alignment: .top, spacing: 12) {
        stepCard(1, "选择", "选择预设或逐项关闭。每项都有说明。")
        stepCard(2, "查看", "你会看到完整列表和可回收空间。此时尚未更改任何内容。")
        stepCard(3, "批准", "macOS 会要求你在系统设置中安装描述文件。只有你能完成该操作。", highlight: true)
      }
      .fixedSize(horizontal: false, vertical: true)
      HStack(alignment: .top, spacing: 20) {
        SettingsGuide()
          .frame(width: 340)
        VStack(alignment: .leading, spacing: 10) {
          Text("为什么 macOS 要求安装描述文件？").font(.headline)
          Text("macOS 只允许通过配置描述文件保持这些设置锁定，学校和企业也用同样的方式管理 Mac。安装前你可以查看其中内容。")
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          Text("随时可在 系统设置 › 通用 › 设备管理 中移除，或用 RemoveMacAI 的撤销功能。")
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          Button("观看演示") { openURL(URL(string: "https://github.com/omlahore/RemoveMacAI#readme")!) }
            .buttonStyle(.link)
        }
        .font(.callout)
      }
    }
  }

  var chooseStart: some View {
    VStack(spacing: 14) {
      VStack(spacing: 6) {
        Text("你想从哪里开始？").font(.title.weight(.bold))
        Text("之后可随时更改。查看前不会更改任何内容。").foregroundStyle(.secondary)
      }
      .padding(.bottom, 6)
      ForEach(Start.allCases) { option in
        Button { start = option } label: { startRow(option) }
          .buttonStyle(.plain)
          .accessibilityAddTraits(start == option ? .isSelected : [])
      }
    }
  }

  func startRow(_ option: Start) -> some View {
    let selected = start == option
    return HStack(alignment: .top, spacing: 14) {
      Image(systemName: selected ? "largecircle.fill.circle" : "circle")
        .font(.title3)
        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(title(option)).font(.headline)
          if option == .recommended {
            Text("多数人适用").font(.caption.weight(.semibold)).foregroundStyle(.green)
              .padding(.horizontal, 7).padding(.vertical, 2)
              .background(Capsule().fill(Color.green.opacity(0.15)))
          }
        }
        Text(summary(option)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        Text(detail(option)).font(.caption).foregroundStyle(.tertiary)
      }
      Spacer(minLength: 0)
    }
    .padding(16)
    .contentShape(Rectangle())
    .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.07)))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.accentColor : .clear, lineWidth: 2))
  }

  func title(_ option: Start) -> String {
    switch option {
    case .recommended: return Preset.recommended.title
    case .privacy: return Preset.privacy.title
    case .own: return "我自己选择"
    }
  }

  func summary(_ option: Start) -> String {
    switch option {
    case .recommended: return Preset.recommended.summary
    case .privacy: return Preset.privacy.summary
    case .own: return "不预选任何项，从侧边栏自行挑选。"
    }
  }

  func detail(_ option: Start) -> String {
    let models = model.modelTotal > 0 ? " 和 \(Term.size(model.modelTotal)) 的模型" : ""
    switch option {
    case .recommended: return "\(Tweaks.preset(.recommended).count) 项设置\(models)"
    case .privacy: return "\(Tweaks.preset(.privacy).count) 项设置\(models)"
    case .own: return "没有为你预选任何项"
    }
  }

  func stepCard(_ n: Int, _ title: String, _ text: String, highlight: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      StepBadge(number: n)
      Text(title).font(.headline)
      Text(text).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 12).fill(highlight ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.07)))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(highlight ? Color.accentColor.opacity(0.5) : .clear))
  }

  var footer: some View {
    HStack {
      if model.welcomePage == 0 {
        Button("跳过") { finish(nil) }
          .keyboardShortcut(.cancelAction)
      } else {
        Button("返回") { model.welcomePage -= 1 }
      }
      Spacer()
      HStack(spacing: 7) {
        ForEach(0..<3) { i in
          Circle().fill(i == model.welcomePage ? Color.accentColor : Color.secondary.opacity(0.3)).frame(width: 8, height: 8)
        }
      }
      .accessibilityElement()
      .accessibilityLabel("第 \(model.welcomePage + 1) 步，共 3 步")
      Spacer()
      if model.welcomePage < 2 {
        Button("继续") { model.welcomePage += 1 }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      } else {
        Button(start == .own ? "开始选择" : "查看更改") { finish(start) }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
    }
    .controlSize(.large)
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
  }

  func finish(_ choice: Start?) {
    model.closeWelcome()
    let preset: Preset?
    switch choice {
    case .recommended?: preset = .recommended
    case .privacy?: preset = .privacy
    case .own?: model.page = .intelligence; preset = nil
    case nil: preset = nil
    }
    guard let preset else { return }
    model.choose(preset)
    // A second sheet can't open while this one is still closing.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.reviewing = true }
  }
}
