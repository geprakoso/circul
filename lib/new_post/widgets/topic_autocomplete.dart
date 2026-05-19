import 'package:flutter/material.dart';

import '../../mock_data.dart';

const _softText = Color(0xFF8C8F93);

class TopicAutocomplete extends StatefulWidget {
  const TopicAutocomplete({
    super.key,
    required this.topic,
    required this.onChanged,
  });

  final String topic;
  final ValueChanged<String> onChanged;

  @override
  State<TopicAutocomplete> createState() => TopicAutocompleteState();
}

class TopicAutocompleteState extends State<TopicAutocomplete> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.topic);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant TopicAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.topic,
        selection: TextSelection.collapsed(offset: widget.topic.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<String> _optionsFor(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    final topicTitles = topics.map((topic) => topic.title).toList()
      ..sort((a, b) => _topicKey(a).compareTo(_topicKey(b)));

    if (query.isEmpty) return topicTitles;

    return topicTitles.where((title) {
      final key = _topicKey(title);
      return key.startsWith(query) || key.contains(query);
    });
  }

  String _topicKey(String title) {
    return title
        .replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsFor,
      onSelected: (value) {
        widget.onChanged(value);
        _controller.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return SizedBox(
              width: 214,
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                cursorColor: Colors.white,
                maxLines: 1,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: _softText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Topik baru',
                  hintStyle: TextStyle(
                    color: _softText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onTap: () {
                  if (textEditingController.selection.isValid) return;
                  textEditingController.selection = TextSelection.collapsed(
                    offset: textEditingController.text.length,
                  );
                },
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 270,
              constraints: const BoxConstraints(maxHeight: 240),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF222426),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF34373A)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: optionList.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF303336)),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            color: kCirculGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
