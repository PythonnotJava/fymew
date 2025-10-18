part of 'prefabrication.dart';

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.blue.shade100,
      end: Colors.purple.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _colorAnimation.value ?? Colors.blue.shade100,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

class YearlyWidget extends StatelessWidget {
  const YearlyWidget({super.key});

  static Map<String, String> getInfo(List<MusicInfoReader> favors) {
    final sortedList = List<MusicInfoReader>.from(favors)
      ..sort(
        (a, b) => parseCustomDateTime(
          a.loadTime,
        ).compareTo(parseCustomDateTime(b.loadTime)),
      );

    int len = sortedList.length;
    if (len == 0) {
      return {"收藏量": '暂无收藏', "提示": '还没有添加任何歌曲到收藏哦~ 🎧'};
    } else if (len == 1) {
      return {
        "收藏量": '1',
        "收藏中唯一的歌曲是": sortedList.first.title,
        "收藏中唯一的歌曲收藏的时间是": sortedList.first.loadTime,
      };
    } else {
      return {
        "收藏量": len.toString(),
        "收藏中最早收藏的歌曲是": sortedList.first.title,
        "收藏中最早收藏的歌曲时间是": sortedList.first.loadTime,
        "收藏中最晚收藏的歌曲是": sortedList.last.title,
        "收藏中最晚收藏的歌曲时间是": sortedList.last.loadTime,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Provider.of<PlayerController>(
      context,
      listen: false,
    );
    final favorInfos = getInfo(playerController.favors);
    final hasNoFavor = favorInfos["收藏量"] == "暂无收藏";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          '🎵 年度总结',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: hasNoFavor
                        ? _buildEmptyView()
                        : _buildInfoCards(favorInfos),
                  ),
                  const SizedBox(height: 30),
                  _buildSummary(days: registerDays(), total: mgrSrcData.length),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- 构建信息卡片 ----------
  Widget _buildInfoCards(Map<String, String> info) {
    final List<Widget> cards = [];

    info.forEach((key, value) {
      if (key == "收藏量") {
        cards.add(
          _buildStatCard(
            icon: Icons.favorite,
            title: "收藏曲目",
            subtitle: value == "暂无收藏" ? "暂无数据" : "$value 首",
            color: Colors.pinkAccent,
          ),
        );
      } else if (key.contains("最早")) {
        cards.add(
          _buildStatCard(
            icon: Icons.history,
            title: key.replaceAll("收藏中", ""),
            subtitle: value,
            color: Colors.orangeAccent,
          ),
        );
      } else if (key.contains("最晚")) {
        cards.add(
          _buildStatCard(
            icon: Icons.auto_awesome,
            title: key.replaceAll("收藏中", ""),
            subtitle: value,
            color: Colors.cyanAccent,
          ),
        );
      } else if (key.contains("唯一")) {
        cards.add(
          _buildStatCard(
            icon: Icons.music_note,
            title: key,
            subtitle: value,
            color: Colors.deepPurpleAccent,
          ),
        );
      }
    });

    return Column(children: cards);
  }

  /// ---------- 无收藏时的展示 ----------
  Widget _buildEmptyView() {
    return Column(
      children: const [
        Icon(Icons.library_music_outlined, color: Colors.white70, size: 80),
        SizedBox(height: 16),
        Text("你还没有收藏任何歌曲", style: TextStyle(color: Colors.white, fontSize: 18)),
        SizedBox(height: 6),
        Text("去发现属于你的音乐吧 🎶", style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Icon(Icons.music_note_rounded, size: 90, color: Colors.white),
        SizedBox(height: 12),
        Text(
          "你的 2025 音乐年报 🎧",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "回顾这一年的音乐旅程",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 26,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                "$title\n$subtitle",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary({required int days, required int total}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "Fymew 已陪你走过",
            style: TextStyle(
              color: Colors.lightBlue[100],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$days 天",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlue[100],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "你共收藏了 $total 首歌曲 🎧",
            style: TextStyle(color: Colors.lightBlue[100]),
          ),
        ],
      ),
    );
  }
}
