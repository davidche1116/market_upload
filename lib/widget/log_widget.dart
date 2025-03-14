import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:market_upload/utils/log_util.dart';

ListQueue<OutputEvent> _outputEventBuffer = ListQueue();

class LogWidget extends StatefulWidget {
  const LogWidget({super.key});

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class RenderedEvent {
  final int id;
  final Level level;
  final TextSpan span;
  final String lowerCaseText;

  RenderedEvent(this.id, this.level, this.span, this.lowerCaseText);
}

class _LogWidgetState extends State<LogWidget> {
  final ListQueue<RenderedEvent> _renderedBuffer = ListQueue();
  List<RenderedEvent> _filteredBuffer = [];

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  Level _filterLevel = Level.trace;
  double _logFontSize = 12;

  var _currentId = 0;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      var scrolledToBottom =
          _scrollController.offset >=
          _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });

    LogUtil.streamOutput.stream.listen((onData) {
      _outputEventBuffer.addAll(LogUtil.memoryOutput.buffer);
      LogUtil.memoryOutput.buffer.clear();

      _renderedBuffer.clear();
      for (var event in _outputEventBuffer) {
        _renderedBuffer.add(_renderEvent(event));
      }
      _refreshFilter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _renderedBuffer.clear();
    for (var event in _outputEventBuffer) {
      _renderedBuffer.add(_renderEvent(event));
    }
    _refreshFilter();
  }

  void _refreshFilter() {
    var newFilteredBuffer =
        _renderedBuffer.where((it) {
          var logLevelMatches = it.level.index >= _filterLevel.index;
          if (!logLevelMatches) {
            return false;
          } else if (_filterController.text.isNotEmpty) {
            var filterText = _filterController.text.toLowerCase();
            return it.lowerCaseText.contains(filterText);
          } else {
            return true;
          }
        }).toList();
    setState(() {
      _filteredBuffer = newFilteredBuffer;
    });

    if (_followBottom) {
      Future.delayed(Duration.zero, _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 4),
          Expanded(child: _buildLogContent()),
          _buildBottomBar(),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _followBottom ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: FloatingActionButton(
            mini: true,
            clipBehavior: Clip.antiAlias,
            onPressed: _scrollToBottom,
            child: const Icon(Icons.arrow_downward),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        const Text(
          "日志信息",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Spacer(),
        Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "字体调节",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _logFontSize++;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _logFontSize--;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: TextField(
                style: const TextStyle(fontSize: 12),
                controller: _filterController,
                onChanged: (s) => _refreshFilter(),
                decoration: InputDecoration(
                  labelText: "日志过滤",
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            PopupMenuButton<Level>(
              initialValue: _filterLevel,
              onSelected: (Level value) {
                setState(() {
                  _filterLevel = value;
                  _refreshFilter();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterLevel.toString().split('.').last,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<Level>>[
                    PopupMenuItem<Level>(
                      value: Level.trace,
                      child: _buildLevelMenuItem("Trace"),
                    ),
                    PopupMenuItem<Level>(
                      value: Level.debug,
                      child: _buildLevelMenuItem("Debug"),
                    ),
                    PopupMenuItem<Level>(
                      value: Level.info,
                      child: _buildLevelMenuItem("Info"),
                    ),
                    PopupMenuItem<Level>(
                      value: Level.warning,
                      child: _buildLevelMenuItem("Warning"),
                    ),
                    PopupMenuItem<Level>(
                      value: Level.error,
                      child: _buildLevelMenuItem("Error"),
                    ),
                    PopupMenuItem<Level>(
                      value: Level.fatal,
                      child: _buildLevelMenuItem("Fatal"),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelMenuItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1600,
        child: ListView.builder(
          shrinkWrap: true,
          controller: _scrollController,
          itemBuilder: (context, index) {
            var logEntry = _filteredBuffer[index];
            return Text.rich(
              logEntry.span,
              key: Key(logEntry.id.toString()),
              style: TextStyle(fontSize: _logFontSize),
            );
          },
          itemCount: _filteredBuffer.length,
        ),
      ),
    );
  }

  void _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );

    _scrollListenerEnabled = true;
  }

  RenderedEvent _renderEvent(OutputEvent event) {
    var parser = AnsiParser();

    var text = event.lines.join('\n');
    parser.parse(text);

    return RenderedEvent(
      _currentId++,
      event.level,
      TextSpan(children: parser.spans),
      text.toLowerCase(),
    );
  }
}

class AnsiParser {
  static const parserText = 0, parserBracket = 1, parserCode = 2;

  AnsiParser();

  Color? foreground;
  Color? background;
  late List<TextSpan> spans;

  void parse(String s) {
    spans = [];
    var state = parserText;
    late StringBuffer buffer;
    var text = StringBuffer();
    var code = 0;
    late List<int> codes;

    for (var i = 0, n = s.length; i < n; i++) {
      var c = s[i];

      switch (state) {
        case parserText:
          if (c == '\u001b') {
            state = parserBracket;
            buffer = StringBuffer(c);
            code = 0;
            codes = [];
          } else {
            text.write(c);
          }
          break;

        case parserBracket:
          buffer.write(c);
          if (c == '[') {
            state = parserCode;
          } else {
            state = parserText;
            text.write(buffer);
          }
          break;

        case parserCode:
          buffer.write(c);
          var codeUnit = c.codeUnitAt(0);
          if (codeUnit >= 48 && codeUnit <= 57) {
            code = code * 10 + codeUnit - 48;
            continue;
          } else if (c == ';') {
            codes.add(code);
            code = 0;
            continue;
          } else {
            if (text.isNotEmpty) {
              spans.add(createSpan(text.toString()));
              text.clear();
            }
            state = parserText;
            if (c == 'm') {
              codes.add(code);
              // coloring
              handleCodes(codes);
            } else {
              text.write(buffer);
            }
          }
          break;
      }
    }
    spans.add(createSpan(text.toString()));
  }

  void handleCodes(List<int> codes) {
    if (codes.isEmpty) {
      codes.add(0);
    }
    switch (codes[0]) {
      case 0:
        foreground = getColor(0, true);
        background = getColor(0, false);
        break;
      case 38:
        foreground = getColor(codes[2], true);
        break;
      case 39:
        foreground = getColor(0, true);
        break;
      case 48:
        background = getColor(codes[2], false);
        break;
      case 49:
        background = getColor(0, false);
    }
  }

  Color? getColor(int colorCode, bool foreground) {
    Color? color;
    switch (colorCode) {
      case 0:
        color = foreground ? Colors.black : Colors.transparent;
        break;
      case 12:
        color = (Colors.indigo[700])!;
        break;
      case 208:
        color = (Colors.orange[700])!;
        break;
      case 196:
        color = (Colors.red[700])!;
        break;
      case 199:
        color = (Colors.pink[700])!;
        break;
    }
    return color;
  }

  TextSpan createSpan(String text) {
    // in my test phone,only iOS has align issue
    if (Platform.isIOS && text.startsWith("│")) {
      text = '\u001b$text';
    }
    return TextSpan(
      text: text,
      style: TextStyle(color: foreground, backgroundColor: background),
    );
  }
}
