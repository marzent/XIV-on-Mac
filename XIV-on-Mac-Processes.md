# XIV-on-Mac 主要流程說明

本文檔整理了 XIV-on-Mac 專案中四個主要流程的程式起始點、函數呼叫順序與流程。基於程式碼分析，流程分為啟動器自動更新、遊戲登入、遊戲更新（game 與 boot 分開）以及遊戲啟動。

## 1. 啟動器自動更新流程

**起始點：** `AppDelegate.applicationDidFinishLaunching(_:)`

**函數呼叫順序與流程：**
1. 初始化 Sparkle 更新器（`sparkle.updater`）。
2. 呼叫 `sparkle.updater.checkForUpdatesInBackground()` 在背景檢查更新。
3. 如果有可用更新，Sparkle 處理下載、驗證和安裝新版本的 XIV on Mac 應用程式。
4. 使用者收到安裝提示，Sparkle 管理整個更新過程。

## 2. 遊戲登入流程

**起始點：** `LaunchController.doLogin(_:)`（由使用者點擊登入按鈕觸發）

**函數呼叫順序與流程：**
1. 呼叫 `problemConfigurationCheck()` 檢查配置問題；如果有嚴重問題，返回。
2. 顯示登入表單，設定憑證（`Settings.credentials`）。
3. 異步執行：
   - 檢查遊戲安裝：`FFXIVApp().installed`。
   - 設定 Discord 存在：`DiscordBridge.setPresence()`。
   - 確保圖形後端：`GraphicsInstaller.ensureBackend()`。
   - 檢查登入維護：`Frontier.loginMaintenance`（發出 GET 請求至 https://frontier.ffxiv.com/worldStatus/login_status.json?_={timestamp}）。
   - 建立登入結果：`LoginResult(repair)`（呼叫 XIVLauncher 原生登入函數）。
   - 檢查登入狀態（`loginResult.state`），處理 NoService 或 NoTerms。
   - 如果修復模式，顯示修復表單並呼叫 `repairController?.repair(loginResult)`。
   - 如果有待處理修補，呼叫 `startPatch(loginResult.pendingPatches!)`。
   - 檢查遊戲維護：`Frontier.gameMaintenance`（發出 GET 請求至 https://frontier.ffxiv.com/worldStatus/gate_status.json?lang={language}&_={timestamp}）。
   - 更新 Dalamud：檢查 `loginResult.dalamudInstallState`。
   - 啟動遊戲：`loginResult.startGame(dalamudInstallState == .ok)`。
4. 關閉登入表單和主視窗，啟動附加元件：`AddOn.launchNotify()`。
5. 監控遊戲退出代碼。

## 3. 遊戲更新流程

### Game 資料夾檔案與版本更新

**起始點：** `LaunchController.startPatch(_:)`（在登入過程中，如果 `loginResult.pendingPatches` 不為空）

**函數呼叫順序與流程：**
1. 呼叫 `PatchController.install(_:)` 處理每個修補。
2. 下載修補檔案到 `Patch.dir`。
3. 驗證修補：呼叫 XIVLauncher 的 `install()` 函數。
4. 安裝修補：更新 `FFXIVRepo.ver`。
5. 移除修補檔案（如果不保留）。
6. 安裝完成後，呼叫 `FFXIVRepo.verToBck()` 備份版本，關閉修補視窗。

### Boot 資料夾檔案與版本更新

**起始點：** `LaunchController.checkBoot()`（在 `loadView()` 中異步呼叫）

**函數呼叫順序與流程：**
1. 呼叫 XIVLauncher 的 `Patch.bootPatches` 獲取 boot 修補。
2. 如果有修補且遊戲已安裝，呼叫 `startPatch(bootPatches)`。
3. 遵循 game 修補的相同安裝流程（見上文）。
4. 安裝後，啟用登入按鈕；如果自動登入，呼叫 `doLogin()`。

## 4. 遊戲啟動流程

**起始點：** `LoginResult.startGame(_:)`（在登入成功後呼叫）

**函數呼叫順序與流程：**
1. 將 `LoginResult` 編碼為 JSON。
2. 呼叫 XIVLauncher 原生函數 `XIVLauncher.startGame(loginResultJSON, _dalamudOk)`。
3. 原生庫處理啟動遊戲可執行檔（透過 Wine），返回 `ProcessInformation`。
4. 關閉登入表單和主視窗。
5. 啟動附加元件：`AddOn.launchNotify()`。
6. 監控遊戲退出代碼。

## 附註
- Boot 修補總是在登入前檢查，並與 game 修補分離。
- 維護檢查從 Frontier API 獲取狀態，影響登入和啟動。
- XIVLauncher.NativeAOT submodule 提供原生函數支援登入、修補和啟動。</content>
<parameter name="filePath">/Users/plusone/WorkSpace/GitRepository/XIV-on-Mac/XIV-on-Mac-Processes.md