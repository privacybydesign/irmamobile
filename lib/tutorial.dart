// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final wordPair = WordPair.random();
        return MaterialApp(
          title: 'Startup Name Generator',
            theme: ThemeData(
                primaryColor: Colors.white,
            ),
            home: RandomWords(),
        );
    }
}

class RandomWordsState extends State<RandomWords> {
    final _suggestions = <WordPair>[];
    final Set<WordPair> _saved = Set<WordPair>();
    final _biggerFont = const TextStyle(fontSize: 18.0);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Startup Name Generator'),
                actions: <Widget>[      // Add 3 lines from here...
                    IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
                ],
            ),
            body: _buildSuggestions(),
        );
    }

    Widget _buildSuggestions() {
        return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemBuilder: /*1*/ (context, i) {
                if (i.isOdd) return Divider(); /*2*/

                final index = i ~/ 2; /*3*/
                if (index >= _suggestions.length) {
                    _suggestions.addAll(generateWordPairs().take(10)); /*4*/
                }
                return _buildRow(_suggestions[index]);
            });
    }

    Widget _buildRow(WordPair pair) {
        final bool alreadySaved = _saved.contains(pair);
        return ListTile(
            title: Text(
                pair.asPascalCase,
                style: _biggerFont,
            ),
            trailing: Icon(   // Add the lines from here...
                alreadySaved ? Icons.favorite : Icons.favorite_border,
                color: alreadySaved ? Colors.red : null,
            ),
            onTap: () {      // Add 9 lines from here...
                setState(() {
                    if (alreadySaved) {
                        _saved.remove(pair);
                    } else {
                        _saved.add(pair);
                    }
                });
            },
        );
    }

    void _pushSaved() {
        Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (BuildContext context) {
                    final Iterable<ListTile> tiles = _saved.map(
                            (WordPair pair) {
                            return ListTile(
                                title: Text(
                                    pair.asPascalCase,
                                    style: _biggerFont,
                                ),
                            );
                        },
                    );
                    final List<Widget> divided = ListTile
                        .divideTiles(
                        context: context,
                        tiles: tiles,
                    )
                        .toList();
                    return Scaffold(
                        appBar: AppBar(
                            title: Text('Saved Suggestions'),
                        ),
                        body: ListView(children: divided),
                    );
                },
            ),
        );
    }
}

class RandomWords extends StatefulWidget {
    @override
    RandomWordsState createState() => RandomWordsState();
}
