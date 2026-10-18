#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RemoveMacAI 英→中 本地化脚本 v2：精确替换 + 上下文替换 + usage 整段替换。"""
import re, glob

ROOT = 'Sources/removemacai'

# ---------- 翻译表（key = 源码字符串字面量的"人类可读原文"；value = 中文） ----------
TR = {
    # ===== 页面/导航 =====
    "Overview": "概览",
    "Background Items": "后台项目",
    "Storage": "存储空间",
    "Undo": "撤销",
    "Turn Off": "关闭",
    "Customize": "自定义",
    "Clean Up": "清理",
    "Privacy": "隐私",
    "Annoyances": "烦扰项",
    "Apple Apps": "Apple 应用",
    "Finder": "访达",
    "Dock and Windows": "程序坞与窗口",
    "Typing": "输入",
    "Recommended": "推荐设置",
    "Maximum privacy": "最大隐私",
    "Most people": "多数人适用",
    "I'll choose myself": "我自己选择",
    "Start with nothing selected and pick from the sidebar.": "不预选任何项，从侧边栏自行挑选。",
    "Nothing is selected for you": "没有为你预选任何项",

    # ===== 概览页 =====
    "Settings changed": "已更改的设置",
    "See which ones": "查看明细",
    "Browse settings": "浏览设置",
    "Apps running in the background": "后台运行的应用",
    "None": "无",
    "See what they are": "查看内容",
    "Space you can get back": "可回收的空间",
    "Not checked": "未检查",
    "Old installers and caches": "旧安装器和缓存",
    "Check now": "立即检查",
    "Or start with a preset": "或从预设开始",
    "\(Tweaks.preset(preset).count) settings and Apple Intelligence off": "\(Tweaks.preset(preset).count) 项设置，并关闭 Apple Intelligence",
    "Review…": "查看…",
    "A preset adds to what's already applied and changes nothing until you review it.": "预设只是在查看前累加选择，不会实际更改任何设置。",
    "Apple Intelligence removal builds on [pared](https://github.com/4evy/pared) by 4evy.": "Apple Intelligence 移除功能基于 4evy 的 [pared](https://github.com/4evy/pared) 构建。",
    "Apple Intelligence is off": "Apple Intelligence 已关闭",
    "Apple Intelligence is on": "Apple Intelligence 已开启",
    "\(Term.size(model.modelTotal)) of models out of \(Term.size(disk)) of storage": "模型占用 \(Term.size(model.modelTotal))，共 \(Term.size(disk)) 存储空间",
    "Delete the Leftover Models…": "删除残留模型…",
    "Change What's Kept On": "更改保留项",
    "Turn Off with Recommended Settings…": "按推荐设置关闭…",
    "Choose What to Turn Off": "选择要关闭的功能",
    "You'll see every change first.": "你会先看到每一项更改。",
    "Checking how much space its models take…": "正在检查其模型占用空间…",
    "\(Term.size(model.modelTotal)) of models are still on disk. macOS won't download more.": "仍有 \(Term.size(model.modelTotal)) 模型在磁盘上。macOS 不会继续下载。",
    "Its models are gone and macOS won't download them again.": "模型已删除，macOS 不会再次下载。",
    "Its models take \(Term.size(model.modelTotal)) on this Mac, whether you use them or not.": "无论你用不用，模型都占用了本机 \(Term.size(model.modelTotal)) 空间。",
    "Its features are on. RemoveMacAI can turn off the ones you don't use.": "功能已开启。RemoveMacAI 可以关闭你不用的那些。",

    # ===== Apple Intelligence 页 =====
    "Turn off Apple Intelligence": "关闭 Apple Intelligence",
    "Switches off the features below, deletes their models and stops macOS downloading them again. Turn it back on any time and macOS re-downloads what it needs.": "关闭下列功能、删除其模型并阻止 macOS 再次下载。随时可以重新开启，macOS 会按需重新下载。",
    "macOS asks you to install a configuration profile for this, and Undo puts everything back. This part builds on pared by 4evy, which first mapped Apple's asset service and model sets.": "macOS 会要求你为此安装一个配置描述文件，撤销可还原所有更改。此部分基于 4evy 的 pared 构建，它首次摸清了 Apple 的资产服务与模型集。",
    "Keep anything you use": "保留你使用的功能",
    "Switch on to keep": "开启以保留",
    "A kept feature keeps the models it needs, so less space comes back.": "保留的功能会保留所需模型，因此释放的空间会减少。",
    "Asking Apple's asset service…": "正在询问 Apple 的资产服务…",
    "Apple's asset service didn't answer, so the sizes are unknown.": "Apple 的资产服务未响应，因此大小未知。",
    "Total": "总计",
    "Apple Intelligence is off, but these models are still on disk.": "Apple Intelligence 已关闭，但这些模型仍在磁盘上。",
    "Delete Models": "删除模型",
    "Models on disk": "磁盘上的模型",
    "macOS deletes the files on its own schedule, so Storage settings can count them for a while after removal.": "macOS 会按自己的计划删除文件，因此删除后存储设置可能仍统计它们一段时间。",
    "· Off, kept off by the profile": "· 已关闭，由描述文件保持关闭",
    "· Off": "· 已关闭",
    "· On": "· 已开启",
    "· Checking…": "· 检查中…",

    # ===== 调整项列表 =====
    "Settings with a lock are kept in place by the RemoveMacAI profile, which you install in System Settings.": "带锁的设置由 RemoveMacAI 描述文件保持，该文件在系统设置中安装。",
    "Select All": "全选",
    "Select Recommended": "选择推荐项",
    "Deselect All": "取消全选",
    "Select": "选择",
    "Kept in place by the RemoveMacAI profile": "由 RemoveMacAI 描述文件保持",
    "Managed by another profile on this Mac.": "由本 Mac 上的另一个描述文件管理。",
    "Needs macOS \(tweak.since.0).\(tweak.since.1) or newer.": "需要 macOS \(tweak.since.0).\(tweak.since.1) 或更高版本。",
    "Partly applied. It stays as it is unless you switch it.": "部分应用。除非你切换它，否则保持现状。",
    "Applies on review": "查看时应用",
    "Undoes on review": "查看时撤销",

    # ===== 后台项目 =====
    "No background items from other apps.": "没有来自其他应用的后台项目。",
    "All users": "所有用户",
    "Updaters, helpers and agents other apps installed. They run whether or not their app is open. Switching one off takes effect at once. Updaters are safe to switch off; a helper can be what makes its app work, such as a VPN or Docker.": "其他应用安装的更新器、辅助程序和代理。无论其应用是否打开，它们都在运行。关闭其中一个会立即生效。关闭更新器是安全的；辅助程序可能正是其应用运行所需，例如 VPN 或 Docker。",
    "Items marked All users ask for your password. Apple's own background services are protected by System Integrity Protection, so RemoveMacAI leaves them alone.": "标记为“所有用户”的项目需要你的密码。Apple 自己的后台服务受系统完整性保护，RemoveMacAI 不会动它们。",
    "Reload": "重新加载",
    "Not an updater. Turning it off can stop \(owner) working.": "这不是更新器。关闭它可能导致 \(owner) 无法工作。",
    "RemoveMacAI needs your password to change background items for all users.": "RemoveMacAI 需要你的密码来为所有用户更改后台项目。",

    # ===== 存储空间 =====
    "Find space you can get back": "查找可回收空间",
    "Looks for old installers, aerial videos, Xcode leftovers, app caches and Time Machine snapshots. Nothing moves until you choose.": "查找旧安装器、航拍视频、Xcode 残留、应用缓存和 Time Machine 快照。在你选择之前不会移动任何内容。",
    "Scan": "扫描",
    "Nothing to clean up.": "没有可清理的内容。",
    "Files go to the Trash, so they aren't gone until you empty it. Simulators and snapshots are deleted right away.": "文件会移到废纸篓，清空废纸篓前不会真正删除。模拟器和快照会立即删除。",
    "Scan Again": "重新扫描",
    "Nothing selected": "未选择任何项",
    "Selected: \(Term.size(model.chosenBytes))": "已选择：\(Term.size(model.chosenBytes))",
    "Move to Trash…": "移到废纸篓…",
    "Remove…": "删除…",
    "Move the selected items to the Trash?": "将选中的项目移到废纸篓？",
    "Remove the selected items?": "删除选中的项目？",
    "Move to Trash": "移到废纸篓",
    "Remove": "删除",
    "About \(Term.size(model.chosenBytes)). Items only an administrator can move ask for your password.": "约 \(Term.size(model.chosenBytes))。只有管理员能移动的项目会要求输入密码。",
    " \(permanentChosen.joined(separator: \" and \")) are deleted right away, not moved to the Trash.": " \(permanentChosen.joined(separator: \" and \")) 会立即删除，不会移到废纸篓。",
    "RemoveMacAI needs your password to move items only an administrator can change.": "RemoveMacAI 需要你的密码来移动只有管理员能更改的项目。",

    # ===== 撤销页 =====
    "Profile": "描述文件",
    "RemoveMacAI profile": "RemoveMacAI 描述文件",
    "Installed": "已安装",
    "Apple Intelligence off": "Apple Intelligence 已关闭",
    "Not installed.": "未安装。",
    "Other changes": "其他更改",
    "None.": "无。",
    "Puts every setting back as it was before RemoveMacAI changed it, and removes the profile.": "将每个设置恢复到 RemoveMacAI 更改前的状态，并移除描述文件。",
    "Undo Everything…": "撤销全部…",
    "Undo everything RemoveMacAI changed?": "撤销 RemoveMacAI 的所有更改？",
    "Undo Everything": "撤销全部",
    "macOS asks you to remove the profile in System Settings. Deleted models download again when a feature needs them, and files in the Trash stay there.": "macOS 会要求你在系统设置中移除描述文件。已删除的模型会在功能需要时重新下载，废纸篓中的文件会保留。",
    "Background item: \(item.owner)": "后台项目：\(item.owner)",

    # ===== 欢迎页 =====
    "Take Apple Intelligence off your Mac": "把 Apple Intelligence 从你的 Mac 上移除",
    "RemoveMacAI turns off the Apple Intelligence features you don't use, deletes the models they download, and tidies up other things macOS adds. It's free and open source.": "RemoveMacAI 会关闭你不用的 Apple Intelligence 功能、删除其下载的模型，并清理 macOS 添加的其他内容。免费且开源。",
    "How it works": "工作原理",
    "Three steps, and you can stop at any of them.": "三步，可随时停下。",
    "Choose": "选择",
    "Review": "查看",
    "Approve": "批准",
    "Pick a preset or switch single things off. Each one says what it does.": "选择预设或逐项关闭。每项都有说明。",
    "You see the full list and how much space comes back. Nothing has changed yet.": "你会看到完整列表和可回收空间。此时尚未更改任何内容。",
    "macOS asks you to install a profile in System Settings. Only you can make that click.": "macOS 会要求你在系统设置中安装描述文件。只有你能完成该操作。",
    "Why does macOS ask for a profile?": "为什么 macOS 要求安装描述文件？",
    "macOS only lets these settings stay locked through a configuration profile, the same thing schools and companies use to manage their Macs. You can read what's in it before you install it.": "macOS 只允许通过配置描述文件保持这些设置锁定，学校和企业也用同样的方式管理 Mac。安装前你可以查看其中内容。",
    "Remove it any time in System Settings › General › Device Management, or with Undo in RemoveMacAI.": "随时可在 系统设置 › 通用 › 设备管理 中移除，或用 RemoveMacAI 的撤销功能。",
    "Watch the demo": "观看演示",
    "Where do you want to start?": "你想从哪里开始？",
    "You can change any of this later. Nothing changes until you review it.": "之后可随时更改。查看前不会更改任何内容。",
    "Skip": "跳过",
    "Back": "返回",
    "Continue": "继续",
    "Start Choosing": "开始选择",
    "Show Me the Changes": "查看更改",
    "Step \(model.welcomePage + 1) of 3": "第 \(model.welcomePage + 1) 步，共 3 步",
    " and \(Term.size(model.modelTotal)) of models": " 和 \(Term.size(model.modelTotal)) 的模型",
    "\(Tweaks.preset(.recommended).count) settings\(models)": "\(Tweaks.preset(.recommended).count) 项设置\(models)",
    "\(Tweaks.preset(.privacy).count) settings\(models)": "\(Tweaks.preset(.privacy).count) 项设置\(models)",

    # ===== 承诺卡片 =====
    "You see every change first": "每一项更改都先经你确认",
    "Nothing happens until you review the list and click Apply.": "只有你查看列表并点击应用后才会执行。",
    "Everything can be undone": "一切皆可撤销",
    "Undo puts every setting back. Deleted models download again when a feature needs them.": "撤销会恢复每个设置。已删除的模型在功能需要时重新下载。",
    "Your Mac stays protected": "你的 Mac 保持受保护",
    "System Integrity Protection stays on. Nothing inside /System is touched.": "系统完整性保护保持开启。/System 内部不会被改动。",
    "Nothing leaves your Mac": "数据不会离开你的 Mac",
    "No account, no analytics, no network requests. The code is public on GitHub.": "无账户、无分析、无网络请求。代码在 GitHub 公开。",

    # ===== 安全卡片 =====
    "Safe by design": "设计即安全",
    "You review every change before it happens": "每项更改执行前都会经过你确认",
    "Undo puts everything back": "撤销可还原所有更改",
    "System Integrity Protection stays on": "系统完整性保护保持开启",
    "No network requests, no analytics": "无网络请求、无分析数据",
    "Read the code on GitHub": "在 GitHub 阅读代码",
    "How RemoveMacAI works": "RemoveMacAI 工作原理",
    "How RemoveMacAI Works": "RemoveMacAI 工作原理",

    # ===== 批准描述文件 =====
    "Remove the profile in System Settings": "在系统设置中移除描述文件",
    "One last step in System Settings": "系统设置中的最后一步",
    "macOS needs you to remove the RemoveMacAI profile yourself. System Settings is open.": "macOS 需要你亲自移除 RemoveMacAI 描述文件。系统设置已打开。",
    "macOS needs you to install the RemoveMacAI profile yourself. System Settings is open.": "macOS 需要你亲自安装 RemoveMacAI 描述文件。系统设置已打开。",
    "Select RemoveMacAI": "选择 RemoveMacAI",
    "It's under General › Device Management.": "它在 通用 › 设备管理 下。",
    "Click the minus button, then Remove": "点击减号按钮，然后点移除",
    "Enter your password if macOS asks.": "如 macOS 要求，请输入密码。",
    "Settings that don't need the profile are done": "无需描述文件的设置已完成",
    "Double-click RemoveMacAI under Downloaded": "在“已下载”下双击 RemoveMacAI",
    "It's in General › Device Management.": "它在 通用 › 设备管理 中。",
    "Click Install, then enter your password": "点击安装，然后输入密码",
    "macOS may call the profile unsigned. That's normal for a free app that isn't from a company.": "macOS 可能提示描述文件未签名。对非公司出品的免费应用来说这很正常。",
    "Waiting for you to remove it…": "等待你移除它…",
    "Waiting for you to install it…": "等待你安装它…",
    "What's in this profile?": "这个描述文件里有什么？",
    "It turns off the Apple Intelligence features you chose, points the model downloads at a closed address on your own Mac so macOS can't fetch them again, and holds the settings marked with a lock. Nothing else.": "它关闭你选择的 Apple Intelligence 功能、将模型下载指向你 Mac 上的一个封闭地址使 macOS 无法再次获取，并锁定带锁标记的设置。仅此而已。",
    "Show the Profile File": "显示描述文件",
    "Something went wrong": "出问题了",
    "Cancel": "取消",
    "Show System Settings": "打开系统设置",

    # ===== 完成页 =====
    "All done": "全部完成",
    "Finished, with a few problems": "完成，但有一些问题",
    "Deleted \(Term.size(freed)) of Apple Intelligence models. macOS clears the files on its own schedule, so Storage settings may show the old size for a while.": "已删除 \(Term.size(freed)) 的 Apple Intelligence 模型。macOS 按自己的计划清理文件，因此存储设置可能暂时显示旧大小。",
    "I make RemoveMacAI by myself in my spare time. If it was useful to you, you can sponsor it on GitHub.": "RemoveMacAI 是我利用业余时间独立开发的。如果对你有用，可以在 GitHub 上赞助我。",
    "Sponsor on GitHub": "在 GitHub 上赞助",
    "Changed your mind? Undo in the sidebar puts everything back.": "改变主意了？侧边栏的撤销可还原所有更改。",
    "See What Changed": "查看更改内容",
    "Done": "完成",

    # ===== 查看/应用 =====
    "Review 1 change": "查看 1 项更改",
    "Review \(changeCount) changes": "查看 \(changeCount) 项更改",
    "Frees about \(Term.size(bytes))": "释放约 \(Term.size(bytes))",
    "Undo any time": "随时可撤销",
    "Asks for your password once": "需要输入一次密码",
    "Turn off every feature": "关闭所有功能",
    "Turn Apple Intelligence back on. macOS downloads its models again when a feature needs them.": "重新开启 Apple Intelligence。macOS 会在功能需要时重新下载模型。",
    "Delete the models, about \(Term.size($0))": "删除模型，约 \(Term.size($0))",
    "Ask macOS to finish removing leftover model files": "请 macOS 完成移除残留模型文件",
    "Delete the models": "删除模型",
    "macOS can download them again": "macOS 可再次下载",
    "Turn on or off": "开启或关闭",
    "Put back": "还原",
    "What happens when you click Apply": "点击应用后会发生什么",
    "Your settings change. This takes a few seconds.": "你的设置会更改。只需几秒。",
    "System Settings opens so you can remove the RemoveMacAI profile. We show you where.": "系统设置会打开，以便你移除 RemoveMacAI 描述文件。我们会指示位置。",
    "Settings that don't need the profile change right away.": "无需描述文件的设置会立即更改。",
    "System Settings opens and you install the RemoveMacAI profile. We show you where.": "系统设置会打开，你安装 RemoveMacAI 描述文件。我们会指示位置。",
    "The models are deleted and you get a summary.": "模型被删除，你会看到摘要。",
    "Show exact settings": "显示具体设置",
    "Shows the command or profile key behind each change": "显示每项更改背后的命令或描述文件键",
    "Apply Change": "应用更改",
    "Apply \(changeCount) Changes": "应用 \(changeCount) 项更改",
    "This takes a few seconds.": "只需几秒。",
    "Changing settings": "正在更改设置",
    "Undoing changes": "正在撤销更改",
    "Deleting Apple Intelligence models": "正在删除 Apple Intelligence 模型",
    "1 change ready": "1 项更改就绪",
    "\(model.pendingCount) changes ready": "\(model.pendingCount) 项更改就绪",
    "Nothing has changed yet. You'll see the full list first.": "尚未更改任何内容。你会先看到完整列表。",
    "Discard": "放弃",
    "\(c.on) of \(c.total)": "\(c.on) / \(c.total)",

    # ===== 帮助弹层 =====
    "Configuration profile": "配置描述文件",
    "macOS only lets these settings stay locked through a configuration profile, the same thing schools and companies use to manage Macs. RemoveMacAI shows you what's in it, and you install it yourself in System Settings. Remove it there any time, or with Undo.": "macOS 只允许通过配置描述文件保持这些设置锁定，学校和企业也用同样的方式管理 Mac。RemoveMacAI 会展示其内容，由你在系统设置中自行安装。随时可在此移除，或使用撤销功能。",
    "Apple Intelligence models": "Apple Intelligence 模型",
    "The files Apple Intelligence runs on, downloaded by macOS whether you use the features or not. Deleting them frees the space. If you turn a feature back on, macOS downloads what it needs again.": "Apple Intelligence 运行所需的文件，无论你是否使用相关功能，macOS 都会下载。删除它们可释放空间。若重新开启某项功能，macOS 会再次下载所需内容。",
    "Kept off by the profile": "由描述文件保持关闭",
    "This setting is held off by the RemoveMacAI profile, so a macOS update or a stray click can't turn it back on. Undo removes the profile and gives you the switch back.": "此设置由 RemoveMacAI 描述文件保持关闭，因此 macOS 更新或误点无法将其重新开启。撤销会移除描述文件并归还开关。",
    "About \(title)": "关于 \(title)",

    # ===== 设置指南插画 =====
    "System Settings": "系统设置",
    "General › Device Management": "通用 › 设备管理",
    "Profiles": "描述文件",
    "Downloaded": "已下载",
    "Select, then click −": "选择后点击 −",
    "Double-click to review": "双击查看",
    "Remove “RemoveMacAI”?": "移除“RemoveMacAI”？",
    "“RemoveMacAI” wants to install": "“RemoveMacAI”想要安装",
    "Install…": "安装…",
    "General": "通用",
    "Appearance": "外观",
    "Privacy & Security": "隐私与安全性",
    "Network": "网络",

    # ===== 调整项数据 =====
    "Turn off Mac Analytics": "关闭 Mac 分析",
    "Stops your Mac sending diagnostic and usage data to Apple and to app developers.": "阻止你的 Mac 向 Apple 和应用开发者发送诊断与使用数据。",
    "Turn off personalized ads": "关闭个性化广告",
    "Stops Apple using what you do in its apps to target ads in the App Store, News and Stocks.": "阻止 Apple 利用你在其应用中的行为，在 App Store、新闻和股票中投放定向广告。",
    "Turn off Improve Siri and Dictation": "关闭 Siri 与听写改进",
    "Stops Apple storing and reviewing recordings of your Siri and dictation requests.": "阻止 Apple 存储和审查你的 Siri 与听写请求录音。",
    "Turn off Improve Search": "关闭搜索改进",
    "Stops Apple keeping your Spotlight, Safari and Look Up searches to improve search.": "阻止 Apple 保留你的聚焦搜索、Safari 和查询搜索记录以改进搜索。",
    "Turn off Spotlight internet results": "关闭聚焦搜索的互联网结果",
    "Keeps Spotlight searches on your Mac instead of sending them to Apple for web suggestions.": "让聚焦搜索仅在本机进行，而不是发送给 Apple 获取网页建议。",
    "Turn off Look Up suggestions": "关闭查询建议",
    "Stops Look Up sending the words you select to Apple for web results.": "阻止查询将你选中的文字发送给 Apple 获取网页结果。",
    "Turn off Safari search suggestions": "关闭 Safari 搜索建议",
    "Stops Safari sending what you type in the address bar to your search engine and to Apple.": "阻止 Safari 将地址栏输入发送给你的搜索引擎和 Apple。",
    "The address bar no longer suggests searches as you type.": "地址栏不再在你输入时提供搜索建议。",
    "Turn off Game Center": "关闭 Game Center",
    "Turns Game Center off, with its sign-in prompts, friend requests and notifications.": "关闭 Game Center，包括登录提示、好友请求和通知。",
    "Games that need Game Center to save progress or play online lose that.": "依赖 Game Center 保存进度或在线联机的游戏将失去这些功能。",
    "Stop clicks on the wallpaper hiding windows": "停止点击壁纸时隐藏窗口",
    "Stops every window sliding away when you click the wallpaper by mistake.": "阻止误点壁纸时所有窗口滑开隐藏。",
    "Hide desktop widgets": "隐藏桌面小组件",
    "Hides widgets on the desktop, including in Stage Manager.": "隐藏桌面上的小组件，包括台前调度中的。",
    "Turn off the play, pause and skip keys": "关闭播放、暂停和跳转键",
    "Turns off the service behind the media keys, so the play key can't open Music.": "关闭媒体键背后的服务，使播放键无法打开音乐。",
    "The keys stop working in every app, including VLC and Spotify. To keep them and only stop Music opening, use Block Music launches instead.": "这些按键在所有应用中都会失效，包括 VLC 和 Spotify。若想保留按键、仅阻止音乐打开，请改用“阻止音乐启动”。",
    "Block Music launches, including from AirPods": "阻止音乐启动，包括来自 AirPods 的",
    "Disables Music's application launch entry, so an AirPod press no longer opens it. No background helper or configuration profile is installed.": "禁用音乐的应用启动入口，AirPods 按压不再打开它。不会安装后台辅助程序或配置描述文件。",
    "Closes Music and blocks manual launches too. Reapply after a macOS update replaces Music's files.": "同时关闭音乐并阻止手动启动。macOS 更新替换音乐文件后请重新应用。",
    "Turn off iPhone Mirroring": "关闭 iPhone 镜像",
    "Turns iPhone Mirroring off, so the app and its prompts go away.": "关闭 iPhone 镜像，应用及其提示都会消失。",
    "Turn off Apple Music in the Music app": "关闭音乐应用中的 Apple Music",
    "Turns the Music app back into a plain player for your own library, without the store and subscription prompts.": "将音乐应用变回只播放你自己资料库的普通播放器，不再有商店和订阅提示。",
    "Apple Music subscribers lose streaming.": "Apple Music 订阅者将失去流媒体播放。",
    "Turn off the Book Store": "关闭书店",
    "Removes the store from the Books app and keeps your own books.": "从图书应用中移除商店，保留你自己的图书。",
    "Remove unused Apple apps from the Dock": "从程序坞移除不用的 Apple 应用",
    "Removes News, TV, Music, Podcasts, Books, Freeform, Maps and Stocks from the Dock. The apps stay installed.": "从程序坞移除新闻、电视、音乐、播客、图书、无边记、地图和股票。应用本身保持安装。",
    "Show file extensions": "显示文件扩展名",
    "Shows the full name of every file, so a file pretending to be a document is easier to spot.": "显示每个文件的完整名称，更容易识别伪装成文档的文件。",
    "Show hidden files": "显示隐藏文件",
    "Shows the files macOS hides, such as .gitignore and .zshrc. Press Command-Shift-Period to toggle it too.": "显示 macOS 隐藏的文件，如 .gitignore 和 .zshrc。也可按 Command-Shift-句号切换。",
    "Show the path bar": "显示路径栏",
    "Shows where the current folder is at the bottom of every Finder window.": "在每个访达窗口底部显示当前文件夹的位置。",
    "Show the status bar": "显示状态栏",
    "Shows the number of items and the free space at the bottom of Finder windows.": "在访达窗口底部显示项目数量和可用空间。",
    "Keep folders above files": "文件夹排在文件上方",
    "Keeps folders above files when sorting by name.": "按名称排序时文件夹排在文件上方。",
    "Search the current folder": "搜索当前文件夹",
    "Makes Finder search the folder you're in, not the whole Mac.": "让访达只搜索你所在的文件夹，而不是整个 Mac。",
    "Skip the extension change warning": "跳过更改扩展名警告",
    "Stops Finder asking for confirmation each time you change a file's extension.": "阻止访达在你每次更改文件扩展名时要求确认。",
    "Show the full path in the title bar": "在标题栏显示完整路径",
    "Shows the full folder path at the top of Finder windows.": "在访达窗口顶部显示完整文件夹路径。",
    "Stop .DS_Store files on network drives": "停止在网络驱动器上生成 .DS_Store",
    "Stops Finder leaving .DS_Store files in shared folders on other computers.": "阻止访达在其他电脑的共享文件夹中留下 .DS_Store 文件。",
    "Empty the Trash after 30 days": "30 天后自动清空废纸篓",
    "Deletes items that have been in the Trash for 30 days, so it stops filling the disk.": "删除在废纸篓中超过 30 天的项目，避免磁盘被占满。",
    "Save new documents on this Mac": "新文稿保存在此 Mac",
    "Makes Save dialogs start on your Mac instead of iCloud Drive.": "让存储对话框默认存储到你的 Mac 而非 iCloud 云盘。",
    "Expand Save dialogs": "展开存储对话框",
    "Opens Save dialogs with the full folder browser instead of the small version.": "以完整文件夹浏览器打开存储对话框，而非精简版。",
    "Show the Library folder": "显示“资源库”文件夹",
    "Shows the hidden Library folder in your home folder.": "显示个人文件夹中隐藏的“资源库”文件夹。",
    "Hide recent apps in the Dock": "在程序坞隐藏最近使用的应用",
    "Stops the Dock adding apps you opened recently.": "阻止程序坞添加你最近打开的应用。",
    "Remove the Dock auto-hide delay": "移除程序坞自动隐藏延迟",
    "Shows a hidden Dock straight away instead of after half a second.": "隐藏的程序坞立即显示，而非等待半秒。",
    "Stop Dock icons bouncing": "停止程序坞图标跳动",
    "Stops Dock icons bouncing while apps open.": "阻止应用打开时程序坞图标跳动。",
    "Minimize windows into their app icon": "最小化窗口到应用图标",
    "Keeps minimized windows inside their app's icon instead of filling the Dock.": "将最小化的窗口收进应用图标，而不是堆满程序坞。",
    "Turn off window opening animations": "关闭窗口打开动画",
    "Opens new windows instantly instead of zooming them in.": "新窗口立即打开，而非缩放动画。",
    "Remove gaps between tiled windows": "移除平铺窗口之间的间隙",
    "Removes the margins around windows you tile to the sides of the screen.": "移除你平铺到屏幕两侧的窗口周围的边距。",
    "Remove shadows from window screenshots": "移除窗口截图阴影",
    "Takes window screenshots without the large drop shadow around them.": "截取窗口截图时去掉周围的大片投影。",
    "Turn off autocorrect": "关闭自动纠正",
    "Stops macOS correcting words as you type.": "阻止 macOS 在你输入时自动纠正词语。",
    "Turn off smart quotes and dashes": "关闭智能引号和破折号",
    "Keeps straight quotes and double hyphens as you typed them, which code and terminals need.": "保留你输入的直引号和双连字符，代码和终端需要它们。",
    "Turn off period on double space": "关闭双击空格输入句号",
    "Stops two spaces turning into a period.": "阻止两个空格变成句号。",
    "Turn off automatic capitals": "关闭自动大写",
    "Stops macOS capitalizing the first word of each sentence.": "阻止 macOS 将每个句子的首字母大写。",
    "Repeat held keys instead of showing accents": "长按重复按键而非显示声调菜单",
    "Repeats a key while you hold it, instead of opening the accent menu.": "长按时重复按键，而不是打开声调菜单。",
    "Type accents with Option shortcuts or the Character Viewer instead.": "请改用 Option 快捷键或字符检视器输入声调。",

    # ===== 分组摘要 =====
    "Stop your Mac sending analytics, searches and recordings to Apple.": "阻止你的 Mac 向 Apple 发送分析、搜索和录音数据。",
    "Turn off the pop-ups, widgets and surprises nobody asked for.": "关掉那些没人想要的弹窗、小组件和意外打扰。",
    "Quiet the Apple apps you don't use. macOS won't let anyone delete them.": "静默你不用的 Apple 应用。macOS 不允许删除它们。",
    "Show what Finder hides and stop the clutter it leaves behind.": "显示访达隐藏的内容，并阻止它留下的杂乱文件。",
    "A faster Dock without the extra icons and animations.": "更快的程序坞，去掉多余的图标和动画。",
    "Stop macOS rewriting what you type.": "阻止 macOS 改写你的输入。",

    # ===== 预设摘要 =====
    "Apple Intelligence off, no analytics or ads, fewer pop-ups. Nothing you rely on stops working.": "关闭 Apple Intelligence，无分析、无广告，弹窗更少。你依赖的功能不会停止工作。",
    "Everything in Recommended, plus Game Center and Safari's search suggestions off.": "包含推荐设置的全部内容，另加关闭 Game Center 和 Safari 搜索建议。",

    # ===== 功能标题 =====
    "Siri and Siri AI": "Siri 和 Siri AI",
    "ChatGPT and other AI extensions": "ChatGPT 和其他 AI 扩展",
    "Writing Tools": "写作工具",
    "Genmoji": "Genmoji",
    "Image Playground": "图像游乐场",
    "Mail summaries and smart replies": "邮件摘要和智能回复",
    "Notification summaries": "通知摘要",
    "Messages summaries": "信息摘要",
    "Safari summaries": "Safari 摘要",
    "Notes transcription summaries": "备忘录转写摘要",
    "Inline text predictions": "内联文本预测",
    "Spatial Photos": "空间照片",
    "Photos Clean Up": "照片清理",
    "Xcode predictive code completion": "Xcode 预测式代码补全",

    # ===== 功能说明 =====
    "The voice assistant. Keep it and basic Siri still works without the big models.": "语音助手。保留它，基础 Siri 无需大型模型即可工作。",
    "Lets Siri and Writing Tools hand requests to ChatGPT.": "让 Siri 和写作工具将请求转交 ChatGPT。",
    "Rewrites, proofreads and summarizes text you select.": "改写、校对和摘要你选中的文本。",
    "Makes new emoji from a description.": "根据描述生成新表情符号。",
    "Generates pictures from a prompt.": "根据提示生成图片。",
    "Summarizes emails and suggests replies in Mail.": "在邮件中摘要邮件并建议回复。",
    "Condenses a stack of notifications into one line.": "将一堆通知浓缩成一行。",
    "Summarizes long conversations in Messages.": "在信息中摘要长对话。",
    "Summarizes web pages in Safari.": "在 Safari 中摘要网页。",
    "Summarizes recordings and transcripts in Notes.": "在备忘录中摘要录音和转写。",
    "Suggests the rest of a word or sentence as you type.": "输入时建议词语或句子的剩余部分。",
    "Turns flat photos into 3D spatial scenes.": "将平面照片转为 3D 空间场景。",
    "Removes objects from photos in Photos.": "在照片中移除照片里的物体。",
    "Predicts code as you type in Xcode.": "在 Xcode 中输入时预测代码。",

    # ===== 模型集标题 =====
    "Apple Intelligence foundation models": "Apple Intelligence 基础模型",
    "Image and Genmoji models": "图像与 Genmoji 模型",
    "Spatial Photos models": "空间照片模型",
    "Photos Clean Up models": "照片清理模型",
    "Xcode code completion models": "Xcode 代码补全模型",

    # ===== 存储项目 =====
    "Aerial wallpaper videos": "航拍壁纸视频",
    "Videos for the moving aerial wallpapers and screen savers. macOS downloads one again when you choose it.": "动态航拍壁纸和屏保的视频。选择时 macOS 会重新下载。",
    "You use an aerial wallpaper or screen saver now, so macOS will download it again.": "你正在使用航拍壁纸或屏保，macOS 会重新下载。",
    "macOS installers": "macOS 安装器",
    "Old \"Install macOS\" apps left in Applications after an upgrade.": "升级后留在应用程序文件夹中的旧“安装 macOS”应用。",
    "iPhone and iPad updates": "iPhone 和 iPad 更新文件",
    "Software update files Finder downloaded for iPhones and iPads. They download again when needed.": "访达为 iPhone 和 iPad 下载的软件更新文件。需要时会重新下载。",
    "Xcode build data": "Xcode 构建数据",
    "Xcode's DerivedData folder. Xcode rebuilds it on the next build.": "Xcode 的 DerivedData 文件夹。下次构建时 Xcode 会重新生成。",
    "Xcode device support": "Xcode 设备支持",
    "Debug symbols Xcode copied from each iPhone, iPad and Watch you connected. They copy again on the next connection.": "Xcode 从你连接过的每台 iPhone、iPad 和 Watch 复制的调试符号。下次连接时会再次复制。",
    "Unavailable simulators": "不可用的模拟器",
    "Simulators for runtimes that are no longer installed, so they can't run.": "对应已不再安装的运行环境的模拟器，无法运行。",
    "Deleted right away, not moved to the Trash.": "立即删除，不会移到废纸篓。",
    "App caches": "应用缓存",
    "Files apps keep to load faster. Apps rebuild them, so the first launch afterwards can be slower.": "应用为加快加载保留的文件。应用会重新生成，因此之后的首次启动可能变慢。",
    "Quit your apps first. The macOS caches RemoveMacAI knows about are left alone.": "请先退出你的应用。RemoveMacAI 已知的 macOS 缓存不会被触碰。",
    "One of Apple's optional apps. It reinstalls free from the App Store.": "Apple 的可选应用之一。可从 App Store 免费重新安装。",
    "Its sound library stays, because \(sharing.joined(separator: \" and \")) uses it too.": "其声音库会保留，因为 \(sharing.joined(separator: \" and \")) 也使用它。",
    "Time Machine local snapshots": "Time Machine 本地快照",
    "Hourly copies Time Machine keeps on this disk between backups. macOS counts them as System Data.": "Time Machine 在两次备份之间保留在本磁盘上的每小时副本。macOS 将其计为系统数据。",
    "Deleted right away, not moved to the Trash. Your backups on the backup disk aren't touched.": "立即删除，不会移到废纸篓。备份磁盘上的备份不受影响。",

    # ===== 系统层字符串 =====
    "its asset type is \(type) on this version of macOS, so it was left alone": "此 macOS 版本上其资产类型为 \(type)，因此未作处理",
    "not found on this version of macOS, so it was left alone": "此 macOS 版本上未找到，因此未作处理",
    "no answer in \(Int(timeout)) seconds": "\(Int(timeout)) 秒内无应答",
    "macOS is still using these models, so it wouldn't delete them yet. Restart your Mac, then run RemoveMacAI again to delete them.": "macOS 仍在使用这些模型，暂不能删除。重启 Mac 后再次运行 RemoveMacAI 以删除。",
    "unknown model set \(name)": "未知模型集 \(name)",
    "no model sets selected": "未选择任何模型集",

    # ===== AppModel =====
    "Could not write the profile: \(error)": "无法写入描述文件：\(error)",
    "The profile is still installed. Remove RemoveMacAI in System Settings > General > Device Management.": "描述文件仍已安装。请在 系统设置 > 通用 > 设备管理 中移除 RemoveMacAI。",
    "The profile wasn't approved, so the locked settings and Apple Intelligence didn't change.": "描述文件未获批准，因此锁定设置和 Apple Intelligence 未更改。",
    "Apple's asset service didn't answer, so the models stay for now.": "Apple 的资产服务未响应，模型暂时保留。",
    "\(Catalog.modelSet($0.0)?.title ?? $0.0) stayed: \($0.1)": "\(Catalog.modelSet($0.0)?.title ?? $0.0) 保留：\($0.1)",
    "Removal couldn't be confirmed yet. Check again in a minute.": "尚无法确认移除完成。一分钟后重试。",
    "Moved \(Term.size(max(0, trashedTotal - left))) to the Trash. Empty the Trash to free the space.": "已将 \(Term.size(max(0, trashedTotal - left))) 移到废纸篓。清空废纸篓可释放空间。",
    "Deleted \(permanent.map(\.title).joined(separator: \" and \")).": "已删除 \(permanent.map(\.title).joined(separator: \" and \"))。",

    # ===== Engine 错误 =====
    "could not disable \(label): \(disabled.output.trimmed)": "无法禁用 \(label)：\(disabled.output.trimmed)",
    "disabled \(label), but could not stop it: \(stopped.output.trimmed)": "已禁用 \(label)，但无法停止：\(stopped.output.trimmed)",
    "could not enable \(label): \(enabled.output.trimmed)": "无法启用 \(label)：\(enabled.output.trimmed)",
    "could not start \(label): \(started.output.trimmed)": "无法启动 \(label)：\(started.output.trimmed)",
    "\(domain) \(k) did not change": "\(domain) \(k) 未更改",
    "could not identify Music's application launch entry: \(error)": "无法识别音乐的应用启动项：\(error)",
    "could not show ~/Library": "无法显示 ~/Library",
    "could not hide ~/Library": "无法隐藏 ~/Library",
    "\(tweak.title): \($0)": "\(tweak.title)：\($0)",
    "Simulators: \(run.output.trimmed)": "模拟器：\(run.output.trimmed)",
    "\(item.label) is still \(disabled ? \"on\" : \"off\")": "\(item.label) 仍处于\(disabled ? \"开启\" : \"关闭\")状态",
    "\(journalURL.path) can't be read or moved aside (\(error.localizedDescription)), so RemoveMacAI changes nothing until it is moved or fixed.": "\(journalURL.path) 无法读取或移开（\(error.localizedDescription)），在移动或修复前 RemoveMacAI 不会做任何更改。",

    # ===== CLI 状态输出 =====
    "Features": "功能",
    "Apple Intelligence is off.": "Apple Intelligence 已关闭。",
    " Undo with: \(undo)": " 撤销命令：\(undo)",
    "Turn it off with: ": "关闭命令：",
    "Apple's asset service did not answer, so the sizes are unknown.": "Apple 的资产服务未响应，因此大小未知。",
    "  macOS removes deleted model files itself, so System Settings can count them for a while.": "  macOS 会自行删除模型文件，因此系统设置可能在一段时间内仍统计它们。",
    "there is no feature called \"\(id)\". The names are listed by: removemacai features": "没有名为 “\(id)” 的功能。可用以下命令查看列表：removemacai features",
    "The selected features are off.": "所选功能已关闭。",
    " No models remain in the sets selected for removal.": " 所选删除集合中已无模型。",
    "macOS removes deleted model files itself, so System Settings can count them for a while.": "macOS 会自行删除模型文件，因此系统设置可能在一段时间内仍统计它们。",
    "Check it with: removemacai status    Undo with: \(undo)": "检查命令：removemacai status    撤销命令：\(undo)",
    "The profile is installed. Checking the selected models.": "描述文件已安装。正在检查所选模型。",
    "Checking Apple Intelligence and its models.": "正在检查 Apple Intelligence 及其模型。",
    "Features on": "已开启的功能",
    "Turning it off will:": "关闭将：",
    "  · switch off Siri, Writing Tools, Genmoji, Image Playground, summaries and ChatGPT": "  · 关闭 Siri、写作工具、Genmoji、图像游乐场、摘要和 ChatGPT",
    "  · delete ": "  · 删除 ",
    " of models and stop macOS downloading them again": " 的模型，并阻止 macOS 再次下载",
    "  · request model removal and block downloads (the current model sizes are unknown)": "  · 请求移除模型并阻止下载（当前模型大小未知）",
    "  · stop model downloads (Apple's asset service is unavailable, so removal cannot be requested)": "  · 停止模型下载（Apple 的资产服务不可用，无法请求移除）",
    "  · ask you to approve one profile in System Settings (macOS requires that click)": "  · 请你批准系统设置中的一个描述文件（macOS 要求这一步）",
    "Everything comes back with: \(undo)": "一切可用以下命令还原：\(undo)",
    "could not build the profile: \(error)": "无法构建描述文件：\(error)",
    "Dry run, nothing changed.": "演练模式，未做任何更改。",
    "Profile it would install:  ": "将安装的描述文件：  ",
    "Models it would delete:    ": "将删除的模型：    ",
    " would stay: ": " 将保留：",
    "Turn Apple Intelligence off?": "关闭 Apple Intelligence？",
    "Nothing changed.": "未做任何更改。",
    " The profile is already installed": " 描述文件已安装",
    "Step 1 of 2": "第 1 步，共 2 步",
    "  Approve the profile": "  批准描述文件",
    "could not write \(Profile.file.path): \(error)": "无法写入 \(Profile.file.path)：\(error)",
    "  System Settings is open. Double-click ": "  系统设置已打开。双击 ",
    ", then click ": "，然后点击 ",
    "  The profile is not installed yet. Run this again once it is, and it picks up from here.": "  描述文件尚未安装。安装后重新运行，它将从当前位置继续。",
    " Profile installed": " 描述文件已安装",
    "Step 2 of 2": "第 2 步，共 2 步",
    "Done.": "完成。",
    "I make RemoveMacAI by myself. If it was useful, you can sponsor it: https://github.com/sponsors/omlahore": "RemoveMacAI 由我独立开发。如果对你有用，可以赞助：https://github.com/sponsors/omlahore",
    "Incomplete.": "未完成。",
    " The profile remains installed; model removal is incomplete.": " 描述文件仍保持安装；模型移除未完成。",
    " Apple's asset service is unavailable, so model removal could not be requested.": " Apple 的资产服务不可用，无法请求移除模型。",
    "  Delete the models": "  删除模型",
    "The amount deleted is unknown because the asset service did not report all sizes.": "由于资产服务未报告所有大小，删除量未知。",
    " The remaining model sizes are unknown; removal could not be confirmed.": " 剩余模型大小未知；无法确认移除完成。",
    " of selected models remain.": " 个所选模型仍保留。",
    " Timed out waiting to confirm that the selected models were removed.": " 等待确认所选模型已移除超时。",
    "macOS removes the files itself, so System Settings can count them under Apple Intelligence for a while.": "macOS 会自行删除文件，因此系统设置可能在一段时间内将其计入 Apple Intelligence。",
    "RemoveMacAI hasn't changed anything on this Mac, so there is nothing to undo.": "RemoveMacAI 尚未更改此 Mac 的任何内容，因此无需撤销。",
    "Settings changed outside the profile are back as they were": "描述文件之外的设置已恢复原状",
    "macOS downloads the models again when you turn a feature back on.": "重新开启功能时 macOS 会再次下载模型。",
    "RemoveMacAI isn't turning Apple Intelligence off, so there is nothing to undo.": "RemoveMacAI 未在关闭 Apple Intelligence，因此无需撤销。",
    "System Settings is open. Select ": "系统设置已打开。选择 ",
    "From a terminal instead: sudo profiles remove -identifier \(Profile.identifier)": "或在终端执行：sudo profiles remove -identifier \(Profile.identifier)",
    "The profile is still installed. You can remove it in System Settings any time.": "描述文件仍已安装。你可以随时在系统设置中移除。",
    " Profile removed. Your own settings apply again.": " 描述文件已移除。你的设置重新生效。",
    "error: ": "错误：",
    "The profile is not installed yet. Run this again once it is.": "描述文件尚未安装。安装后请重新运行。",
    " Profile installed": " 描述文件已安装",
    "\(on) of \(Catalog.features.count)": "\(on) / \(Catalog.features.count)",
    "waiting for you in System Settings": "等待你在系统设置中操作",
    "deleting": "删除中",
    " Settings changed": " 设置已更改",

    # ===== CLI 调整项命令 =====
    "done": "已完成",
    "not applied": "未应用",
    "partly": "部分",
    "managed by another profile": "由另一描述文件管理",
    "needs a newer macOS": "需要更新的 macOS",
    "Apply some with: removemacai apply <names>   or a preset: removemacai apply --preset recommended": "应用部分：removemacai apply <名称>   或预设：removemacai apply --preset recommended",
    "there is no tweak called \"\(id)\". The names are listed by: removemacai tweaks": "没有名为 “\(id)” 的调整项。可用以下命令查看列表：removemacai tweaks",
    "name the tweaks to apply, or a preset with --preset": "请指定要应用的调整项，或用 --preset 指定预设",
    "Apply": "应用",
    "remove the RemoveMacAI profile": "移除 RemoveMacAI 描述文件",
    "install the updated profile (macOS asks you to approve it in System Settings)": "安装更新后的描述文件（macOS 会要求你在系统设置中批准）",
    "Models": "模型",
    " delete ": " 删除 ",
    "Nothing to change.": "无需更改。",
    " Everything named is already that way.": " 所列各项已是该状态。",
    "run it in a terminal, or add --yes": "请在终端中运行，或添加 --yes",
    "\(verb) these changes?": "\(verb) 这些更改？",
    "Settings changed": "设置已更改",
    "  Undo everything with: \(Commands.undo)": "  撤销一切：\(Commands.undo)",
    "Background items from other apps": "来自其他应用的后台项目",
    "updater": "更新器",
    "helper": "辅助程序",
    "  (all users)": "  （所有用户）",
    "Turning off a helper can stop its app working, for example a VPN or Docker.": "关闭辅助程序可能导致其应用无法工作，例如 VPN 或 Docker。",
    "Turn one off with: removemacai background off <label>": "关闭某个：removemacai background off <标签>",
    "there is no background item called \"\(name)\"": "没有名为 “\(name)” 的后台项目",
    "name the items, as listed by: removemacai background": "请指定项目，可用以下命令查看列表：removemacai background",
    "Turn off": "关闭",
    "Turn on": "开启",
    "Turned off": "已关闭",
    "Turned on": "已开启",
    "Measuring...": "测量中...",
    "Nothing to clean.": "没有可清理的内容。",
    "Move some to the Trash with: removemacai clean <names>": "用以下命令将部分移到废纸篓：removemacai clean <名称>",
    "\"\(id)\" is not in the list above": "“\(id)” 不在上面的列表中",
    " are deleted right away, not moved to the Trash.": " 会立即删除，不会移到废纸篓。",
    "Dry run, nothing moved.": "演练模式，未移动任何内容。",
    " It would free about \(Term.size(total)).": " 可释放约 \(Term.size(total))。",
    "Move": "移动",
    " to the Trash": "到废纸篓",
    "Nothing moved.": "未移动任何内容。",
    "Moved to the Trash. Empty the Trash to free about \(Term.size(trashed)).": "已移到废纸篓。清空废纸篓可释放约 \(Term.size(trashed))。",
    "Deleted ": "已删除 ",
    " \(result.protected) item(s) macOS protects stayed where they were.": " \(result.protected) 个 macOS 保护的项目留在原处。",
    "there is no tweak called \"\(id)\"": "没有名为 “\(id)” 的调整项",
    "\(id) is a per-user setting, so it can't go in a profile": "\(id) 是用户级设置，不能放入描述文件",
    "could not write \(path): \(error)": "无法写入 \(path)：\(error)",
    "Wrote \(path)": "已写入 \(path)",
    "  Apple Intelligence: ": "  Apple Intelligence：",
    "left alone": "保持原样",
    "  Tweaks: ": "  调整项：",
    "  Per-user tweaks (Finder, Dock, typing) aren't in profiles; run removemacai on each Mac for those.": "  用户级调整项（访达、程序坞、输入）不在描述文件中；请在各 Mac 上运行 removemacai。",
    "there is no preset called \"\(name)\". Use recommended or privacy": "没有名为 “\(name)” 的预设。请使用 recommended 或 privacy",
    "unknown option \(extra)": "未知选项 \(extra)",
    "name the file to write, for example: removemacai export RemoveMacAI.mobileconfig": "请指定要写入的文件，例如：removemacai export RemoveMacAI.mobileconfig",
    "RemoveMacAI needs macOS 26 or newer": "RemoveMacAI 需要 macOS 26 或更高版本",
    " \(feature.title) is kept, but it is switched off. Turn it on in System Settings.": " \(feature.title) 已保留，但处于关闭状态。请在系统设置中开启。",
    "Cancelled, so nothing that needs your password changed.": "已取消，需要你密码的操作未发生任何更改。",
}

def unescape(s):
    return s.replace('\\"', '"').replace('\\\\', '\\')

pat = re.compile(r'"((?:[^"\\]|\\.)*)"')

def repl(m):
    key = unescape(m.group(1))
    if key in TR:
        return '"' + TR[key] + '"'
    return m.group(0)

total_hits = 0
for path in sorted(glob.glob(ROOT + '/**/*.swift', recursive=True)):
    with open(path, encoding='utf-8') as f:
        src = f.read()
    before = src
    src = pat.sub(repl, src)
    # ---------- 上下文精确替换（避免误伤命令参数） ----------
    src = src.replace('Term.green("off")', 'Term.green("关闭")')
    src = src.replace('Term.yellow("on")', 'Term.yellow("开启")')
    src = src.replace('Term.pad("off", 5)', 'Term.pad("关闭", 5)')
    src = src.replace('Term.pad("on", 5)', 'Term.pad("开启", 5)')
    src = src.replace('Term.yellow("none")', 'Term.yellow("无")')
    src = src.replace('Term.dim("none")', 'Term.dim("无")')
    src = src.replace('Term.dim(" (locked)")', 'Term.dim("（已锁定）")')
    if src != before:
        hits = sum(1 for m in pat.finditer(before) if unescape(m.group(1)) in TR)
        total_hits += hits
        with open(path, 'w', encoding='utf-8') as f:
            f.write(src)
        print(f"{hits:3d}  {path.replace(ROOT + '/', '')}")

print("TOTAL replacements:", total_hits)

# ---------- usage 多行字符串整段替换（main.swift） ----------
main_path = ROOT + '/main.swift'
with open(main_path, encoding='utf-8') as f:
    src = f.read()

usage_zh = '''  RemoveMacAI \(version)
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

  '''

pat3 = re.compile(r'let usage = """(.*?)"""', re.S)
new_src, n = pat3.subn(lambda m: 'let usage = """' + usage_zh + '"""', src)
if n:
    with open(main_path, 'w', encoding='utf-8') as f:
        f.write(new_src)
    print("usage replaced:", n)
else:
    print("usage NOT replaced")
