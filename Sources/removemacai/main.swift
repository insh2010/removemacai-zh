import Foundation

let usage = """
  RemoveMacAI \(version)
  精简 macOS：关闭 Apple Intelligence、删除其模型，并关闭分析、广告等。每项更改都可撤销。

  Apple Intelligence
    removemacai                 显示当前状态，然后关闭它（先询问）
    removemacai status          显示当前状态和模型占用空间
    removemacai off [选项]       直接关闭，不显示概览
        --keep a,b              保留这些功能（名称见：removemacai features）
        --dry-run               显示将更改的内容，不实际更改
        --yes                   不询问
    removemacai on              重新开启 Apple Intelligence，保留其他调整项
    removemacai features        列出功能名称

  精简
    removemacai tweaks [--json]           列出每个调整项及其应用状态
    removemacai apply <名称> [选项]        应用调整项
        --preset recommended|privacy      应用预设，包括关闭 Apple Intelligence
        --dry-run, --yes
    removemacai undo <名称>              撤销调整项
    removemacai background [off|on <标签>]
                                          其他应用的后台项目
    removemacai clean [<名称>]            显示可回收空间，将部分移到废纸篓
    removemacai export <file.mobileconfig> [--preset p] [<名称>] [--keep a,b] [--no-ai]
                                          为 MDM 写入描述文件

    removemacai revert          撤销 RemoveMacAI 的所有更改
    removemacai app             打开 RemoveMacAI 应用

  """

var args = Array(CommandLine.arguments.dropFirst())
func flag(_ name: String) -> Bool {
  guard let i = args.firstIndex(of: name) else { return false }
  args.remove(at: i)
  return true
}
func option(_ name: String) -> String? {
  guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
  let value = args[i + 1]
  args.removeSubrange(i...(i + 1))
  return value
}
func presetOption() -> Preset? {
  guard let name = option("--preset") else { return nil }
  guard let preset = Preset(rawValue: name) else {
    Term.fail("没有名为 “\(name)” 的预设。请使用 recommended 或 privacy")
  }
  return preset
}

// Opened from Finder: the app. With arguments, or from a bare binary: the CLI.
if args.isEmpty && Bundle.main.bundleURL.pathExtension == "app" || args.first == "app" {
  guard ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 else {
    Term.fail("RemoveMacAI 需要 macOS 26 或更高版本")
  }
  Shell.inApp = true
  RemoveMacAIApp.main()
  exit(0)
}

guard args.first == "selftest" || ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 else {
  Term.fail("RemoveMacAI 需要 macOS 26 或更高版本")
}

switch args.first {
case "status":
  Commands.status()
case "off", nil:
  if !args.isEmpty { args.removeFirst() }
  let keep = Set((option("--keep") ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
  let dryRun = flag("--dry-run")
  let yes = flag("--yes") || flag("-y")
  if let extra = args.first { Term.fail("未知选项 \(extra)") }
  exit(Commands.off(keep: keep, dryRun: dryRun, yes: yes) ? 0 : 1)
case "revert":
  Commands.revert()
case "on":
  Commands.on()
case "features":
  Commands.features()
case "tweaks":
  args.removeFirst()
  TweakCommands.list(json: flag("--json"))
case "apply", "undo":
  let command = args.removeFirst()
  let preset = presetOption()
  let dryRun = flag("--dry-run")
  let yes = flag("--yes") || flag("-y")
  if let bad = args.first(where: { $0.hasPrefix("-") }) { Term.fail("unknown option \(bad)") }
  let ok = command == "apply"
    ? TweakCommands.apply(ids: args, preset: preset, dryRun: dryRun, yes: yes)
    : TweakCommands.undo(ids: args, dryRun: dryRun, yes: yes)
  exit(ok ? 0 : 1)
case "background":
  args.removeFirst()
  let yes = flag("--yes") || flag("-y")
  exit(TweakCommands.background(args, yes: yes) ? 0 : 1)
case "clean":
  args.removeFirst()
  let dryRun = flag("--dry-run")
  let yes = flag("--yes") || flag("-y")
  exit(TweakCommands.clean(ids: args, dryRun: dryRun, yes: yes) ? 0 : 1)
case "export":
  args.removeFirst()
  let preset = presetOption()
  let keep = Set((option("--keep") ?? "").split(separator: ",").map { String($0).trimmed }.filter { !$0.isEmpty })
  let noAI = flag("--no-ai")
  guard let path = args.first else { Term.fail("请指定要写入的文件，例如：removemacai export RemoveMacAI.mobileconfig") }
  TweakCommands.export(path: path, ids: Array(args.dropFirst()), preset: preset, keepAI: keep, noAI: noAI)
case "selftest":
  exit(selfTest() ? 0 : 1)
case "--version", "-v", "version":
  print(version)
case "help", "--help", "-h":
  print(usage, terminator: "")
default:
  print(usage, terminator: "")
  exit(1)
}
