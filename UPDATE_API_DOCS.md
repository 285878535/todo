# 即刻清单 - 更新检测 API 文档

## 📋 API 概述

用于检测应用新版本的 RESTful API 接口。

---

## 🌐 接口地址

```
POST https://api.deepauto.xyz/app/check-update
```

### 请求头 (Headers)

```
Content-Type: application/json
```

---

## 📤 请求参数 (Request Body)

```json
{
  "app_id": "com.example.todo",
  "current_version": "1.0.0",
  "platform": "android",
  "build_number": 1
}
```

### 参数说明

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `app_id` | String | 是 | 应用唯一标识符 (Package Name / Bundle ID) |
| `current_version` | String | 是 | 当前应用版本号，格式：`主版本.次版本.修订号` |
| `platform` | String | 是 | 平台类型：`android`、`ios`、`macos` |
| `build_number` | Integer | 是 | 构建号（版本内部版本号） |

---

## 📥 响应格式 (Response)

### 成功响应 (200 OK)

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "has_update": true,
    "latest_version": "1.1.0",
    "latest_build": 2,
    "update_url": "https://deepauto.xyz/downloads/jike-todo-1.1.0.apk",
    "release_notes": "1. 修复了一些bug\n2. 添加了新功能\n3. 优化了性能",
    "force_update": false,
    "min_version": "1.0.0",
    "file_size": "20.5 MB",
    "release_date": "2025-01-15"
  }
}
```

### 响应字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `code` | Integer | 是 | 状态码：200 表示成功 |
| `message` | String | 是 | 响应消息 |
| `data.has_update` | Boolean | 是 | 是否有新版本可用 |
| `data.latest_version` | String | 是 | 最新版本号 |
| `data.latest_build` | Integer | 是 | 最新构建号 |
| `data.update_url` | String | 是 | 下载链接（APK/IPA 文件地址） |
| `data.release_notes` | String | 是 | 更新说明（支持换行符 `\n`） |
| `data.force_update` | Boolean | 是 | **是否强制更新**（⚠️ 重要：设置为 true 时，用户必须更新才能使用应用） |
| `data.min_version` | String | 是 | 最低支持版本（低于此版本强制更新） |
| `data.file_size` | String | 否 | 安装包大小（可选） |
| `data.release_date` | String | 否 | 发布日期（可选，格式：YYYY-MM-DD） |

---

## 🎯 业务逻辑说明

### 1. 版本判断逻辑

服务端应该比较以下信息来判断是否有新版本：

```python
# 伪代码示例
def has_update(current_version, latest_version):
    # 比较版本号 (例如：1.0.0 vs 1.1.0)
    return compare_version(current_version, latest_version) < 0
```

### 2. 强制更新逻辑（⚠️ 重要）

当 `force_update: true` 时，应用会：
- **阻止用户使用应用**
- 显示不可关闭的更新对话框
- 用户只能选择"立即更新"
- 无法通过返回键或点击外部关闭对话框
- 必须下载并安装新版本才能使用

建议在以下情况设置 `force_update: true`：
- 修复严重的安全漏洞
- 修复导致数据丢失的 Bug
- API 接口重大变更，旧版本无法正常工作
- 用户版本低于 `min_version`

```python
def should_force_update(current_version, min_version):
    # 当前版本低于最低支持版本时，强制更新
    return compare_version(current_version, min_version) < 0
```

### 3. 平台区分

不同平台可能有不同的更新包和下载链接：

- **Android**: `.apk` 文件
- **iOS**: App Store 链接或企业分发链接
- **macOS**: `.dmg` 或 `.pkg` 文件

---

## 💡 示例场景

### 场景 1: 有新版本可用

**请求：**
```json
{
  "app_id": "com.example.todo",
  "current_version": "1.0.0",
  "platform": "android",
  "build_number": 1
}
```

**响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "has_update": true,
    "latest_version": "1.1.0",
    "latest_build": 2,
    "update_url": "https://deepauto.xyz/downloads/jike-todo-1.1.0.apk",
    "release_notes": "✨ 新功能\n• 添加了背景自定义功能\n• 优化了任务统计页面\n\n🐛 Bug 修复\n• 修复了横屏显示问题\n• 修复了通知权限问题",
    "force_update": false,
    "min_version": "1.0.0",
    "file_size": "20.5 MB",
    "release_date": "2025-01-15"
  }
}
```

### 场景 2: 已是最新版本

**请求：**
```json
{
  "app_id": "com.example.todo",
  "current_version": "1.1.0",
  "platform": "android",
  "build_number": 2
}
```

**响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "has_update": false,
    "latest_version": "1.1.0",
    "latest_build": 2,
    "update_url": "",
    "release_notes": "",
    "force_update": false,
    "min_version": "1.0.0"
  }
}
```

### 场景 3: 强制更新 ⚠️

**请求：**
```json
{
  "app_id": "com.example.todo",
  "current_version": "0.9.0",
  "platform": "android",
  "build_number": 1
}
```

**响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "has_update": true,
    "latest_version": "1.1.0",
    "latest_build": 2,
    "update_url": "https://deepauto.xyz/downloads/jike-todo-1.1.0.apk",
    "release_notes": "⚠️ 重要更新\n\n此版本修复了严重的安全问题，请务必更新！\n\n修复内容：\n• 修复了数据泄露风险\n• 更新了加密算法\n• 强化了权限管理",
    "force_update": true,
    "min_version": "1.0.0",
    "file_size": "20.5 MB",
    "release_date": "2025-01-15"
  }
}
```

**应用行为：**
1. ✅ 启动应用后 2 秒自动检测更新
2. ⚠️ 检测到 `force_update: true`
3. 🔒 显示不可关闭的对话框（无法返回、无法点击外部关闭）
4. 📱 用户只能点击"立即更新"按钮
5. 🌐 在浏览器中打开下载链接
6. ⏳ 对话框保持显示，直到用户安装新版本并重启应用
7. 🚫 用户无法使用应用的任何功能

---

## 🛠️ 服务端实现建议

### 数据库表结构

```sql
CREATE TABLE app_versions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    app_id VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL,
    build_number INT NOT NULL,
    platform ENUM('android', 'ios', 'macos') NOT NULL,
    download_url VARCHAR(500) NOT NULL,
    release_notes TEXT,
    file_size VARCHAR(20),
    release_date DATE,
    min_version VARCHAR(20),
    force_update BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_app_platform (app_id, platform),
    INDEX idx_version (version, build_number)
);
```

### Node.js 示例 (Express)

```javascript
app.post('/app/check-update', async (req, res) => {
  const { app_id, current_version, platform, build_number } = req.body;
  
  // 查询最新版本
  const latestVersion = await db.query(
    'SELECT * FROM app_versions WHERE app_id = ? AND platform = ? AND is_active = true ORDER BY build_number DESC LIMIT 1',
    [app_id, platform]
  );
  
  if (!latestVersion) {
    return res.json({
      code: 404,
      message: 'Version not found',
      data: null
    });
  }
  
  // 比较版本号
  const hasUpdate = compareVersion(current_version, latestVersion.version) < 0;
  const forceUpdate = compareVersion(current_version, latestVersion.min_version) < 0;
  
  res.json({
    code: 200,
    message: 'success',
    data: {
      has_update: hasUpdate,
      latest_version: latestVersion.version,
      latest_build: latestVersion.build_number,
      update_url: latestVersion.download_url,
      release_notes: latestVersion.release_notes,
      force_update: forceUpdate,
      min_version: latestVersion.min_version,
      file_size: latestVersion.file_size,
      release_date: latestVersion.release_date
    }
  });
});
```

---

## 🔒 安全建议

1. **HTTPS**: 必须使用 HTTPS 加密传输
2. **限流**: 对同一 IP 或设备限制请求频率
3. **签名验证**: 可以添加请求签名验证，防止恶意请求
4. **CDN**: 更新包文件建议使用 CDN 加速下载

---

## 📝 更新说明格式建议

为了让用户更好地了解更新内容，建议使用以下格式：

```
✨ 新功能
• 添加了自定义背景功能
• 支持横屏全屏时钟模式
• 新增清新绿主题

🚀 优化改进
• 优化了任务列表性能
• 改进了通知提醒逻辑

🐛 Bug 修复
• 修复了任务完成弹窗问题
• 修复了主题切换异常
• 修复了深色模式显示问题
```

---

## 📞 联系方式

如有问题，请联系开发者：
- 应用 ID: `com.example.todo`
- API 基础地址: `https://api.deepauto.xyz`
- 服务器域名: `deepauto.xyz`

---

## 📅 版本历史

| 版本 | 构建号 | 发布日期 | 说明 |
|------|--------|----------|------|
| 1.0.0 | 1 | 2025-01-01 | 首次发布 |

