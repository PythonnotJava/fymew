import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

class DraggableExpandableContainer extends StatefulWidget {
  const DraggableExpandableContainer({super.key});

  @override
  DraggableExpandableContainerState createState() => DraggableExpandableContainerState();
}

class DraggableExpandableContainerState extends State<DraggableExpandableContainer> {
  bool _expanded = false;
  List<String> logos = ['事件', '调试', '网络'];

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _onLogoTap(String name) {
    debugPrint('点击了 $name');
  }

  /// 从容器中移除图标，但是至少有一个图标
  void _removeLogo(int index) {
    if (logos.length > 1) {
      setState(() {
        logos.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('容器栏中至少保留一个图标')),
      );
    }
  }

  void _addLogo(String name) {
    setState(() {
      logos.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAccept: (name) {
        if (!logos.contains(name)) _addLogo(name);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: _expanded ? MediaQuery.of(context).size.width : 300,
          height: _expanded ? MediaQuery.of(context).size.height : 200,
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_expanded ? 0 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                spreadRadius: 4,
              )
            ],
          ),
          child: GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ReorderableWrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (int i = 0; i < logos.length; i++)
                    LongPressDraggable<int>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildLogo(logos[i]),
                      ),
                      onDragEnd: (details) {
                        final renderBox = context.findRenderObject() as RenderBox;
                        final containerOffset = renderBox.localToGlobal(Offset.zero);
                        final containerRect = Rect.fromLTWH(
                            containerOffset.dx,
                            containerOffset.dy,
                            renderBox.size.width,
                            renderBox.size.height);
                        if (!containerRect.contains(details.offset)) {
                          _removeLogo(i);
                        }
                      },
                      child: DragTarget<int>(
                        onAccept: (fromIndex) {
                          setState(() {
                            final temp = logos[fromIndex];
                            logos[fromIndex] = logos[i];
                            logos[i] = temp;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return _buildLogo(logos[i]);
                        },
                      ),
                    ),
                  // 添加按钮
                  GestureDetector(
                    onTap: () {
                      _addLogo('新图标${logos.length + 1}');
                    },
                    child: _buildAddLogo(),
                  ),
                ],
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final item = logos.removeAt(oldIndex);
                    logos.insert(newIndex, item);
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(Icons.apps),
        ),
        SizedBox(height: 4),
        Text(name),
      ],
    );
  }

  Widget _buildAddLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.add, color: Colors.black),
        ),
        SizedBox(height: 4),
        Text('添加'),
      ],
    );
  }
}

void main() => runApp(MaterialApp(
  home: Scaffold(
    body: Center(child: DraggableExpandableContainer()),
  ),
));
