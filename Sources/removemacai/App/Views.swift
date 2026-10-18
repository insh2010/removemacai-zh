import AppKit
import SwiftUI

struct ContentView: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    @Bindable var model = model
    NavigationSplitView {
      Sidebar()
        .navigationSplitViewColumnWidth(min: 210, ideal: 230)
    } detail: {
      DetailView(page: model.page ?? .overview)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          if model.pendingCount > 0 { PendingBar() }
        }
    }
    .sheet(isPresented: $model.showingWelcome) { WelcomeSheet() }
    .sheet(isPresented: $model.reviewing) { ReviewSheet() }
    .sheet(isPresented: Binding(get: { model.run != nil }, set: { if !$0 { model.dismissRun() } })) {
      RunSheet()
    }
  }
}

struct DetailView: View {
  let page: Page

  var body: some View {
    switch page {
    case .overview: OverviewView()
    case .intelligence: IntelligenceView()
    case .group(let group): TweakGroupView(group: group)
    case .background: BackgroundView()
    case .storage: StorageView()
    case .changes: ChangesView()
    }
  }
}

// MARK: - Sidebar

struct Sidebar: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    @Bindable var model = model
    List(selection: $model.page) {
      row(.overview)
      Section("关闭") {
        row(.intelligence, badge: model.aiPending ? Text("1") : nil)
        ForEach([TweakGroup.privacy, .annoyances, .apps], id: \.self) { group in
          row(.group(group), badge: count(group))
        }
        row(.background)
      }
      Section("自定义") {
        ForEach([TweakGroup.finder, .windows, .typing], id: \.self) { group in
          row(.group(group), badge: count(group))
        }
      }
      Section("清理") {
        row(.storage)
        row(.changes)
      }
    }
    .listStyle(.sidebar)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      Button { model.openWelcome() } label: {
        Label("RemoveMacAI 工作原理", systemImage: "questionmark.circle")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 18)
      .padding(.vertical, 12)
    }
  }

  func row(_ page: Page, badge: Text? = nil) -> some View {
    Label(page.title, systemImage: page.symbol)
      .badge(badge)
      .tag(page)
  }

  func count(_ group: TweakGroup) -> Text? {
    let c = model.switchedOn(in: group)
    return c.on > 0 ? Text("\(c.on) / \(c.total)") : nil
  }
}

// MARK: - Bottom bar and review

struct PendingBar: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "circle.fill").font(.system(size: 7)).foregroundStyle(.tint)
      VStack(alignment: .leading, spacing: 1) {
        Text(model.pendingCount == 1 ? "1 项更改就绪" : "\(model.pendingCount) 项更改就绪")
          .font(.callout.weight(.medium))
        Text("尚未更改任何内容。你会先看到完整列表。")
          .font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      Button("放弃") { model.discard() }
      Button("Review and Apply…") { model.reviewing = true }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(.bar)
    .overlay(alignment: .top) { Divider() }
  }
}

struct ReviewSheet: View {
  @Environment(AppModel.self) private var model
  @State private var plan: Plan?
  @State private var showCommands = false

  var changeCount: Int {
    guard let plan else { return 0 }
    return plan.apply.count + plan.revert.count + (model.aiPending ? 1 : 0)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 10) {
        Text(changeCount == 1 ? "查看 1 项更改" : "查看 \(changeCount) 项更改").font(.title2.weight(.bold))
        if let plan {
          HStack(spacing: 8) {
            if !plan.models.isEmpty, let bytes = model.modelBytes(plan.models), bytes > 0 {
              chip("释放约 \(Term.size(bytes))", color: .green)
            }
            chip("随时可撤销", color: .accentColor)
            if plan.profile.map({ !$0.isEmpty }) ?? false {
              chip("需要输入一次密码", color: .secondary)
            }
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 22)
      .padding(.bottom, 14)
      Divider()
      if let plan {
        List {
          if model.aiPending || !plan.models.isEmpty {
            Section("Apple Intelligence") {
              if model.aiPending, let kept = model.targetAI {
                Label(
                  kept.isEmpty ? "关闭所有功能" : "Turn off everything except \(kept.count) kept feature\(kept.count == 1 ? "" : "s")",
                  systemImage: "apple.intelligence")
              } else if model.aiPending {
                Label("重新开启 Apple Intelligence。macOS 会在功能需要时重新下载模型。", systemImage: "arrow.uturn.backward")
              }
              if !plan.models.isEmpty {
                let bytes = model.modelBytes(plan.models)
                Label {
                  HStack {
                    Text(bytes.map { $0 > 0 ? "删除模型，约 \(Term.size($0))" : "请 macOS 完成移除残留模型文件" } ?? "删除模型")
                    Spacer()
                    Text("macOS 可再次下载").font(.caption).foregroundStyle(.secondary)
                  }
                } icon: {
                  Image(systemName: "trash")
                }
              }
            }
          }
          if !plan.apply.isEmpty {
            Section("开启或关闭") {
              ForEach(plan.apply) { t in ChangeRow(tweak: t, adding: true, showCommands: showCommands) }
            }
          }
          if !plan.revert.isEmpty {
            Section("还原") {
              ForEach(plan.revert) { t in ChangeRow(tweak: t, adding: false, showCommands: showCommands) }
            }
          }
          if let profile = plan.profile {
            Section("点击应用后会发生什么") {
              if profile.isEmpty {
                step(1, "你的设置会更改。只需几秒。")
                step(2, "系统设置会打开，以便你移除 RemoveMacAI 描述文件。我们会指示位置。")
              } else {
                step(1, "无需描述文件的设置会立即更改。")
                step(2, "系统设置会打开，你安装 RemoveMacAI 描述文件。我们会指示位置。")
                if !plan.models.isEmpty { step(3, "模型被删除，你会看到摘要。") }
              }
            }
          }
        }
        .listStyle(.inset)
      } else {
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      Divider()
      HStack {
        Toggle("显示具体设置", isOn: $showCommands)
          .toggleStyle(.checkbox)
          .help("显示每项更改背后的命令或描述文件键")
        Spacer()
        Button("取消", role: .cancel) { model.reviewing = false }
          .keyboardShortcut(.cancelAction)
        Button(changeCount == 1 ? "应用更改" : "应用 \(changeCount) 项更改") { model.apply() }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
          .disabled(plan?.isEmpty ?? true)
      }
      .controlSize(.large)
      .padding(16)
    }
    .frame(width: 640, height: 600)
    .task {
      let wanted = model.wanted
      let ai = model.targetAI
      let snapshot = model.snapshot
      plan = await Task.detached { Plan.make(wanted: wanted, ai: ai, snapshot: snapshot) }.value
    }
  }

  func chip(_ text: String, color: Color) -> some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .foregroundStyle(color == .secondary ? Color.secondary : color)
      .padding(.horizontal, 9).padding(.vertical, 4)
      .background(Capsule().fill(color.opacity(0.13)))
  }

  func step(_ n: Int, _ text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      StepBadge(number: n)
      Text(text).fixedSize(horizontal: false, vertical: true)
    }
  }
}

struct ChangeRow: View {
  let tweak: Tweak
  let adding: Bool
  var showCommands = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Image(systemName: adding ? "plus.circle.fill" : "arrow.uturn.backward.circle.fill")
          .foregroundStyle(adding ? Color.accentColor : .orange)
        Text(tweak.title)
        if tweak.inProfile {
          Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
            .help("由 RemoveMacAI 描述文件保持")
        }
        Spacer()
      }
      if showCommands {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(tweak.changes.indices, id: \.self) { i in
            Text(tweak.changes[i].command)
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }
        }
        .padding(.leading, 26)
      }
    }
    .padding(.vertical, 2)
  }
}

// MARK: - Running

struct RunSheet: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    Group {
      switch model.run {
      case .working(let text)?:
        VStack(spacing: 16) {
          ProgressView().controlSize(.large)
          Text(text).font(.headline)
          Text("只需几秒。").foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 420)
      case .approveProfile(let remove)?:
        ApproveProfileView(remove: remove)
      case .finished(let problems, let freed)?:
        FinishedView(problems: problems, freed: freed)
      case nil:
        EmptyView()
      }
    }
    .interactiveDismissDisabled()
  }
}

struct ApproveProfileView: View {
  @Environment(AppModel.self) private var model
  let remove: Bool
  @State private var showContents = false
  @State private var showTrouble = false

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 6) {
        Text(remove ? "在系统设置中移除描述文件" : "系统设置中的最后一步")
          .font(.title2.weight(.bold))
        Text(remove
          ? "macOS 需要你亲自移除 RemoveMacAI 描述文件。系统设置已打开。"
          : "macOS 需要你亲自安装 RemoveMacAI 描述文件。系统设置已打开。")
          .foregroundStyle(.secondary)
      }
      HStack(alignment: .top, spacing: 22) {
        SettingsGuide(remove: remove)
          .frame(width: 360)
        VStack(alignment: .leading, spacing: 14) {
          if remove {
            stepRow(1, "选择 RemoveMacAI", "它在 通用 › 设备管理 下。", active: true)
            stepRow(2, "点击减号按钮，然后点移除", "如 macOS 要求，请输入密码。", active: false)
          } else {
            stepRow(0, "无需描述文件的设置已完成", nil, active: false, done: true)
            stepRow(2, "在“已下载”下双击 RemoveMacAI", "它在 通用 › 设备管理 中。", active: true)
            stepRow(3, "点击安装，然后输入密码", "macOS 可能提示描述文件未签名。对非公司出品的免费应用来说这很正常。", active: false)
          }
          HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(remove ? "等待你移除它…" : "等待你安装它…").foregroundStyle(.secondary)
          }
          .padding(.top, 2)
        }
      }
      if !remove {
        DisclosureGroup("这个描述文件里有什么？", isExpanded: $showContents) {
          VStack(alignment: .leading, spacing: 8) {
            Text("它关闭你选择的 Apple Intelligence 功能、将模型下载指向你 Mac 上的一个封闭地址使 macOS 无法再次获取，并锁定带锁标记的设置。仅此而已。")
              .fixedSize(horizontal: false, vertical: true)
            Button("显示描述文件") { NSWorkspace.shared.activateFileViewerSelecting([Profile.file]) }
              .buttonStyle(.link)
          }
          .font(.callout)
          .foregroundStyle(.secondary)
          .padding(.top, 6)
        }
      }
      DisclosureGroup("出问题了", isExpanded: $showTrouble) {
        Text("If System Settings says the profile couldn't be \(remove ? "removed" : "installed"), click Cancel here. Your Mac stays as it was, and you can report it on GitHub with Help › Report a Problem.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 6)
      }
      HStack {
        Button("取消") { model.cancel() }
        Spacer()
        Button("打开系统设置") { Commands.openProfileSettings() }
          .buttonStyle(.borderedProminent)
      }
      .controlSize(.large)
    }
    .padding(26)
    .frame(width: 760)
    .fixedSize(horizontal: false, vertical: true)
  }

  func stepRow(_ n: Int, _ title: String, _ detail: String?, active: Bool, done: Bool = false) -> some View {
    HStack(alignment: .top, spacing: 10) {
      StepBadge(number: n, done: done, active: active)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.callout.weight(done ? .regular : .semibold))
          .foregroundStyle(done ? .secondary : .primary)
          .fixedSize(horizontal: false, vertical: true)
        if let detail {
          Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

struct FinishedView: View {
  @Environment(AppModel.self) private var model
  let problems: [String]
  let freed: Int64?

  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle().fill((problems.isEmpty ? Color.green : Color.orange).opacity(0.15)).frame(width: 64, height: 64)
        Image(systemName: problems.isEmpty ? "checkmark" : "exclamationmark.triangle.fill")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(problems.isEmpty ? Color.green : Color.orange)
      }
      .accessibilityHidden(true)
      Text(problems.isEmpty ? "全部完成" : "完成，但有一些问题").font(.title2.weight(.bold))
      if let freed, freed > 0 {
        Text("已删除 \(Term.size(freed)) 的 Apple Intelligence 模型。macOS 按自己的计划清理文件，因此存储设置可能暂时显示旧大小。")
          .multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 420)
          .fixedSize(horizontal: false, vertical: true)
      }
      if !problems.isEmpty {
        ScrollView {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(problems, id: \.self) { Text("• " + $0).textSelection(.enabled) }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 440, maxHeight: 160)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.5)))
      }
      if problems.isEmpty {
        VStack(spacing: 6) {
          Text("RemoveMacAI 是我利用业余时间独立开发的。如果对你有用，可以在 GitHub 上赞助我。")
            .multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 420)
            .fixedSize(horizontal: false, vertical: true)
          Link("在 GitHub 上赞助", destination: URL(string: "https://github.com/sponsors/omlahore")!)
        }
      }
      Text("改变主意了？侧边栏的撤销可还原所有更改。")
        .font(.callout).foregroundStyle(.secondary)
      HStack(spacing: 10) {
        Button("查看更改内容") {
          model.dismissRun()
          model.page = .changes
        }
        Button("完成") { model.dismissRun() }
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
      .controlSize(.large)
      .padding(.top, 4)
    }
    .padding(32)
    .frame(width: 520)
  }
}
