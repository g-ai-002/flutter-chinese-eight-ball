# 中式黑八 🎱

基于 Flutter + Flame 的中式黑八台球游戏，支持 Android、Windows 与 Web。真实物理、开放球台首球定组、三档 AI、自由球摆放、瞄准辅助与运行时合成音效，全部本地运行。

## 功能

- 🎯 标准九尺台：2.54 × 1.27 米台面、57.15 mm 球径、六个袋口与开球线
- ⚙️ 真实物理：固定子步长积分、等质量弹性碰撞、库边反弹、滚动摩擦、落袋判定
- 📖 完整规则：开球重摆、开放球台首球定组、犯规交换球权与自由球、黑八胜负
- 🤖 人机对战：入门 / 进阶 / 高手三档，AI 枚举进球线路并用真实物理试算挑杆
- 👥 双人同屏：同屏轮流击球，适合面对面切磋
- 🖱️ 操作：拖动球台瞄准、点击球体吸附球心、力度滑杆与 0.3° 微调
- 💡 瞄准辅助：幽灵球撞击点、目标球去向与库边落点，可随时关闭
- 🎨 三套球台配色（翡翠台呢 / 午夜蓝 / 酒红呢）与深浅色主题
- ✨ Flame 渲染：台呢渐变、木框、袋口、球体高光、出杆球杆与落袋动画
- 🔊 运行时合成音效（出杆 / 撞击 / 落袋 / 犯规 / 终局）与背景音乐，支持震动反馈
- 📱 响应式：手机 / 折叠屏 / 平板 / Windows 窗口自适应，宽屏侧栏、窄屏底部控制
- 🌓 简体中文界面，Windows 优先 `Microsoft YaHei UI`，Web 使用 soup_fonts 思源黑体
- 🧾 日志按天写入用户目录，设置页可查看最近日志

## 下载

v0.1.0（最新发布）：[Gitea Release](http://192.168.31.120:3020/GTech/flutter-chinese-eight-ball/releases/tag/v0.1.0)

| 平台 | 产物 |
| --- | --- |
| Android (arm64) | `flutter-chinese-eight-ball-0.1.0-android-aarch64.apk` |
| Windows (x64, Win10+) | `flutter-chinese-eight-ball-0.1.0-windows-x86_64.zip` |
| Web | `flutter-chinese-eight-ball-0.1.0-web.zip`（解压后起静态服务器） |

Web 产物同时发布到 `tea-pages` 分支（`index.html`、`v0.1.0/` 与 `debug/`），可直接部署为静态站点。

## 开发

```bash
flutter pub get
flutter analyze
flutter test
```

构建产物由 CI 生成：在 GitHub Actions / Gitea Actions 里手动运行 `build` 工作流，选中 `v*` Tag 时按该 Tag 的版本构建 Android / Windows / Web 并发布 Release，运行 `main` 则产出预览产物。音频在运行时合成、Web 字体来自 soup_fonts，仓库不存放字体与音频文件。

本地无需安装 Android SDK 等大型工具链。

## 日志位置

- Windows：`文档/FlutterChineseEightBall/logs/app_yyyyMMdd.log`
- Android：应用外部存储目录下的 `FlutterChineseEightBall/logs/`
- Web：仅保留内存日志，可在设置页查看

## 目录结构

```
lib/
├── core/            # 纯 Dart 游戏核心：向量、球、台面、物理、规则、AI、对局控制
├── flame/           # Flame 球台渲染与游戏循环
├── pages/           # 首页、对局页、设置页、规则页与共享组件
├── providers/       # 用户偏好
├── services/        # 日志、存储、音效、音乐与运行时音频合成
├── theme/           # 主题与球台配色
└── utils/           # 常量、格式化、平台与窗口
test/                # 物理、规则、AI、控制器、界面、日志、音效测试
```

## 规则要点

开球后球台开放，首个合法落袋的球决定双方球组（1-7 全色、9-15 花色）。清空本方七颗球后合法打进 8 号黑八获胜；母球落袋、空杆、先碰对方球或碰撞后无球碰库均判犯规，对手获得自由球。
