# Fymew
## 开发背景

睡觉的时候，想听一些安静的歌曲，于是我开启了定时器并把一些歌曲放到了歌单中。
但是每种歌曲只能播放一次。
为了再听一次歌曲 A，我不得不把 A 加入队列。于是我又点开了一次手机（或者点击耳机的上一首）。
手机的微光和胳膊的挪动再次搅动了我好不容易陷入的模糊困意。
我准备或者即将再次陷入睡意模糊时，又想听那首歌曲了。

于是陷入了恶性循环：定时器停了，我还是没睡着。🤡

---

### 开始了解

> 不想看文档？
> 快速理解 Fymew：用于管理本地音乐文件，与其他播放器操作几乎一致。
> 不同的是，它支持像 `AABABSDAASACABCAD` 这样的自定义播放队列顺序。

---

## Fymew 是什么

**Fymew**（音：/faɪ mjuː/）是 *Fly Music* 的近音提取，意为「轻盈、自由地听音乐」。

> 注意：
>
> * Fymew 仅支持 **MP3** 与 **FLAC** 格式
> * 若音源缺失或被误删，会使用默认音乐代替
> * 仅能在「乐库模式」下删除歌曲
> * 部分功能需要联网，并会动态更新
> * 所有歌曲以 **本地路径** 作为唯一标识

---

## Fymew 的管理方式

Fymew 的核心包括三个界面：

* 主页
* 乐库
* 用户栏

---

## 主页

![i1](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/主页.jpg)

界面从上到下依次为：

1. 用户信息区
2. 功能区
3. 底部导航栏

核心功能区包含 3 个面板：
**工具箱**、**收藏**、**队列**

---

### 工具箱

![i2](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/工具箱子.jpg)

点击「工具箱」后，会弹出毛玻璃界面，每个按钮都是一个功能：

#### 网络载入

从任意合法源载入歌曲（包括在线试听）。
支持临时播放、加入乐库或下载保存。

![i3](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/网络载入.jpg)

> 网络载入仅读不写：
> 若无歌手或封面信息，则使用默认元数据。

#### 定时关闭

可以设置 1~180 分钟的播放定时器，到时自动关闭。
新的定时会覆盖旧定时，销毁可取消。

![i4](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/定时器.jpg)
![i5](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/任务面板栏定时器.jpg)

#### 调试日志

若遇到 bug，可打开查看并反馈。

#### 抽卡

从乐库随机抽一首歌曲推荐，并生成卡片。

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/抽卡.jpg)

#### 歌曲封装

永久保存一首来自合法网络源的歌曲，可自动生成并修改歌曲信息。
封面支持 PNG、JPG 链接检测。

![i6](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/音乐封装引导.jpg)
![i7](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/音乐封装以及播放.jpg)

---

### 我的收藏

收藏歌曲视为一个永久歌单，会循环播放。
仅能通过左滑移除收藏。

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/收藏.jpg)

* 右上角按钮：查看收藏信息
* 左滑：取消收藏

---

### 我的队列

队列是优先级最高的临时歌单。
无论当前播放来源为何（收藏、乐库或网络），**下一首都优先播放队列中的歌曲**。

> 注：
>
> * 仅在「顺序播放」模式下可设置队列
> * 用于实现如 `AABABABASDCSWWAACACAS` 的自定义播放逻辑
> * 支持拖动排序、移除、清空
> * 队列播放完后自动清空
> * 正在播放的歌曲若被移除，则跳到下一首
> * 删除乐库歌曲时，对应收藏项会被删除，但队列不受影响

<table style="width:100%;">
  <tr>
    <td align="center" width="33%">
      <strong>操作演示：自定义队列</strong><br>
      <img src="https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/自定义队列.jpg" alt="i8" style="width:100%; height:auto;">
    </td>
    <td align="center" width="33%">
      <strong>操作演示：移动队列卡片</strong><br>
      <img src="https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/可以移动队列.jpg" alt="i9" style="width:100%; height:auto;">
    </td>
    <td align="center" width="33%">
      <strong>操作演示：移除队列的某首歌曲</strong><br>
      <img src="https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/从队列移除.jpg" alt="i10" style="width:100%; height:auto;">
    </td>
  </tr>
</table>

---

### 轮播面板

轮播面板可随时更新，分为以下几类：

* **歌曲推荐**：支持试听与下载
* **年度总结**：信息展示
* **新闻面板**：嵌入网页内容

<table style="width:100%;">
  <tr>
    <td align="center" width="50%">
      <strong>操作演示：音乐推荐试听</strong><br>
      <img src="https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/音乐推荐试听.jpg" alt="i9" style="width:100%; height:auto;">
    </td>
    <td align="center" width="50%">
      <strong>操作演示：年度听歌报告</strong><br>
      <img src="https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/年度听歌报告.jpg" alt="i10" style="width:100%; height:auto;">
    </td>
  </tr>
</table>

---

### 任务面板

右下角浮动按钮，可查看：

* 定时器状态
* 内存占用
* 系统信息等

---

## 乐库

> 乐库用于管理本地音乐（仅引用，不复制本体）。
> 若歌曲被删除，则自动清理对应记录。
> 网络下载的歌曲保存在应用本地。
>
> ⚠ 删除操作仅能在乐库模式下进行；
> ⚠ 建议在软件关闭后再删除本地文件。

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/乐库.jpg)

### 功能概览

* **头像**：跳转用户界面
* **搜索栏**：支持模糊匹配，如「字 xx y」可匹配「歌曲的名字 xx yy」
* **定位按钮**：跳转到当前播放的乐库歌曲
* **网络载入**：同主页功能

---

### 乐库的歌曲卡片

点击卡片播放（可单击或双击，依用户设置）。
右侧 dot 按钮可展开更多操作：

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/乐库卡片选项.jpg)

* 加入队列
* 隐藏 / 展示浮动球
* 收藏歌曲
* 删除记录（非删除本地文件）
* 临时置顶 / 永久置顶
* 清空队列
* 查看信息（调试）

---

## 播放器设置

播放音乐时，会同步到浮动球播放器。
点击浮动球最右侧设置按钮，弹出详细控制面板：

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/播放器设置.jpg)

功能包括：

* 播放模式：顺序 / 随机 / 单曲循环（队列优先）
* 临时重播：优先级高于队列
* 删除乐库记录（需在乐库模式）
* 随机跳转进度
* 设置界面背景（主页、乐库、收藏、队列）支持 GIF
* 调整播放速度（0.5x~2x）

---

## 用户界面

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/用户面板.jpg)

功能说明：

* 点击头像：更换头像
* 点击名字：修改昵称
* 修改背景：设置个性化壁纸
* 卡片播放模式：单击 / 双击
* 音频模式：支持「阻断模式」「独占模式」
* 启动前清理缓存：清理临时文件夹（不建议频繁使用）
* 关于：软件信息说明

---

## 系统 SMTC

Fymew 在系统通知栏中注册了音乐播放器（SMTC）。
某些安卓魔改系统可能出现兼容性问题。
右上角 `v` 按钮可展开进度条。

![i](https://www.robot-shadow.cn/src/pkg/Fymew/fymew_guide/系统播放器.jpg)

---

## 声明与致谢

### 声明

- 本项目中仅代码为完全开源的，**资源文件并不代表开源可商用**，仅为测试时用，一切商用与本项目无关
- 本项目为完全安卓的项目，代码中仍保留部分Windows的功能。本来想win+Android的，结果写着写着不支持了，其他平台（IOS可能支持，但是没注册plist文件）没测试
- 如果在开发非安卓平台遇到`soeasy_player`的字段bug（原项目名字），请根据情况替换为fymew

### 致谢内容

- [media_kit库](https://pub.dev/packages/media_kit)，太TM好用了
- [思源字体（SourceHanSansSC）](https://github.com/adobe-fonts/source-han-sans)，很美观的一款中英文字体
- AI平台的指导（包含logo设计、2D翻模、安卓开发从0到有）
- Github托管，为我软件提供了资源托管
