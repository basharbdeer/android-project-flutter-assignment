import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_me/LogInApp.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LogInApp.instance(),
      child: MaterialApp(
        title: 'Startup Name Generator',
        initialRoute: '/',
        routes: {
          '/': (context) => RandomWords(),
          '/login': (context) => LoginScreen(),
        },
        theme: ThemeData(
          // Add the 3 lines from here...
          primaryColor: Colors.red,
        ),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  var user;
  var _saved = Set<WordPair>();
  var canDrag = true;
  SnappingSheetController sheetController = SnappingSheetController();
  @override
  Widget build(BuildContext context) {
    user = Provider.of<LogInApp>(context);
    var func = _loginScreen;
    var icon = Icons.login;
    //user.signOut();
    if (user.status == Status.Authenticated) {
      icon = Icons.exit_to_app;
      func = _logOut;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text('Startup Name Generator'),
          actions: [
            IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
            IconButton(icon: Icon(icon), onPressed: func),
          ],
        ),
        body: GestureDetector(
            child: SnappingSheet(
              snappingSheetController: sheetController,
              snapPositions: [
                SnapPosition(
                    positionPixel: 220,
                    snappingCurve: Curves.bounceOut,
                    snappingDuration: Duration(milliseconds: 350)),
                SnapPosition(
                    positionFactor: 1.1,
                    snappingCurve: Curves.easeInBack,
                    snappingDuration: Duration(milliseconds: 1)),
              ],
              lockOverflowDrag: true,
              child: _buildSuggestions(),
              sheetBelow: user.status == Status.Authenticated
                  ? SnappingSheetContent(
                      draggable: canDrag,
                      child: Container(
                        color: Colors.white,
                        child: ListView(
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              Column(children: [
                                Row(children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      color: Colors.grey,
                                      height: 60,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Flexible(
                                              flex: 3,
                                              child: Center(
                                                child: Text(
                                                    "Welcome back, " +
                                                        user.getUserName(),
                                                    style: TextStyle(
                                                        fontSize: 16.0)),
                                              )),
                                          IconButton(
                                            icon: Icon(Icons.keyboard_arrow_up),
                                            onPressed: null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                                Row(children: <Widget>[
                                  FutureBuilder(
                                    future: user.getImageUrl(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<String> snapshot) {
                                      return CircleAvatar(
                                        radius: 50.0,
                                        backgroundImage: snapshot.data != null
                                            ? NetworkImage(snapshot.data)
                                            : null,
                                      );
                                    },
                                  ),
                                  Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(user.getUserName(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15))),
                                ]),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      RaisedButton(
                                        onPressed: () async {
                                          FilePickerResult result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: [
                                              'png',
                                              'jpg',
                                              'gif',
                                              'bmp',
                                              'jpeg',
                                              'webp'
                                            ],
                                          );
                                          File file;
                                          if (result != null) {
                                            file =
                                                File(result.files.single.path);
                                            await user.uploadNewImage(file);
                                          } else {
                                            // User canceled the picker
                                          }
                                        },
                                        textColor: Colors.white,
                                        padding: EdgeInsets.only(
                                            left: 5.0,
                                            top: 3.0,
                                            bottom: 5.0,
                                            right: 8.0),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                Color(0xFF0D47A1),
                                                Color(0xFF1976D2),
                                                Color(0xFF42A5F5),
                                              ],
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(5.0),
                                          child: const Text('Change Avatar',
                                              style: TextStyle(fontSize: 17)),
                                        ),
                                      ),
                                    ]),
                              ]),
                            ]),
                      ),
                      //heightBehavior: SnappingSheetHeight.fit(),
                    )
                  : null,
            ),
            onTap: () => {
                  setState(() {
                    if (canDrag == false) {
                      canDrag = true;
                      sheetController.snapToPosition(SnapPosition(
                        positionFactor: 0.323,
                      ));
                    } else {
                      canDrag = false;
                      sheetController.snapToPosition(SnapPosition(
                          positionFactor: 0.089,
                          snappingCurve: Curves.easeInBack,
                          snappingDuration: Duration(milliseconds: 1)));
                    }
                  })
                }));
  }

  Widget _buildSuggestions() {
    //_suggestions.addAll(generateWordPairs().take(20));
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        //separatorBuilder: (BuildContext context, int i) => Divider(),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }

          final int index = i ~/ 2;
          //final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = (_saved.contains(pair));
    final alreadySavedData =
        (user.status == Status.Authenticated && user.getData().contains(pair));
    final isSaved = (alreadySaved || alreadySavedData);
    if (alreadySaved && !alreadySavedData) {
      user.addpair(pair.toString(), pair.first, pair.second);
    }
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        // NEW from here...
        isSaved ? Icons.favorite : Icons.favorite_border,
        color: isSaved ? Colors.red : null,
      ),
      onTap: () {
        // NEW lines from here...
        setState(() {
          if (isSaved) {
            _saved.remove(pair);
            user.removepair(pair.toString());
          } else {
            _saved.add(pair);
            user.addpair(pair.toString(), pair.first, pair.second);
          }
        });
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        final TextStyle _biggerFont = const TextStyle(fontSize: 18);
        final user = Provider.of<LogInApp>(context);
        final GlobalKey<ScaffoldState> _scaffoldKey =
            new GlobalKey<ScaffoldState>();
        var favorites = _saved;
        if (user.status == Status.Authenticated) {
          favorites = _saved.union(user.getData());
        } else {
          favorites = _saved;
        }

        final tiles = favorites.map(
          (WordPair pair) {
            return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
                trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await user.removepair(pair.toString());
                      setState(() => _saved.remove(pair));
                    }));
          },
        );
        final divided = ListTile.divideTiles(
          context: context,
          tiles: tiles,
        ).toList();

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text('Saved Suggestions'),
          ),
          body: ListView(children: divided),
        );
      });
    }));
  }

  void _loginScreen() {
    //final user = Provider.of<LogInApp>(context,listen:true);
    // bool pressed=false;
    Navigator.pushNamed(context, '/login');
  }

  void _logOut() async {
    // final user = Provider.of<LogInApp>(context,listen:false);
    sheetController.snapToPosition(SnapPosition(positionFactor: 0.089));
    canDrag = false;
    await user.signOut();
    _saved.clear();
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  var scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LogInApp>(context);
    var _validate = true;
   // var contexts;
    TextEditingController _email = TextEditingController(text: "");
    TextEditingController _password = TextEditingController(text: "");
    TextEditingController _confirm = TextEditingController(text: "");
    return Scaffold(
        key: scaffoldKey,
        //resizeToAvoidBottomInset:true,
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          title: Text('Login'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(25.0),
                child: (Text(
                  'Welcome to Startup Names Generator, please log in below',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ))),
            const SizedBox(height: 40),
            TextField(
              controller: _email,
              obscureText: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 40),
            user.status == Status.Authenticating
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ButtonTheme(
                      minWidth: 300.0,
                      height: 35.0,
                      child: RaisedButton(
                        color: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Colors.red)),
                        onPressed: () async {
                          if (!await user.signIn(_email.text, _password.text)) {
                            scaffoldKey.currentState.showSnackBar(SnackBar(
                                content: Text(
                                    "There was an error logging into the app")));
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Log in',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ButtonTheme(
                minWidth: 300.0,
                height: 35.0,
                child: RaisedButton(
                  color: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: Colors.green)),
                  onPressed: () async {
                    //
                   // contexts = context;
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return AnimatedPadding(
                          padding: MediaQuery.of(context).viewInsets,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.decelerate,
                          child: Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                      'Please confirm your password below:'),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: 350,
                                    child: TextField(
                                      controller: _confirm,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Password',
                                        errorText: _validate
                                            ? null
                                            : 'Passwords must match',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ButtonTheme(
                                    minWidth: 350.0,
                                    height: 50,
                                    child: RaisedButton(
                                        color: Colors.green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            side: BorderSide(
                                                color: Colors.green)),
                                        child: Text(
                                          'Confirm',
                                          style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.white),
                                        ),
                                        onPressed: () async {
                                          if (_confirm.text == _password.text) {
                                            //do that
                                            // await user.signOut();
                                            await user.signUp(
                                                _email.text, _password.text);
                                            //await user.signIn(_email.text, _password.text);
                                            Navigator.pushNamed(
                                                context, '/login');
                                            Navigator.pushNamed(context, '/');
                                          } else {
                                            setState(() {
                                              _validate = false;
                                              FocusScope.of(context)
                                                  .requestFocus(FocusNode());
                                            });
                                          }
                                        }),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    //
                    //Navigator.pop(context);
                  },
                  child: Text('New user? Click to sign up',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
            ),
          ],
        ));
  }
}
