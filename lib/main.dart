import 'dart:convert'; // Lib usada para converter o JSON
import 'dart:io'; // Lib usada para manipular arquivos
import 'package:flutter/material.dart';
// Lib usada para saber o local padrão de armazenamento de dados do dispositivo
// sendo usado, pois no android é um, e no iOS é outro. Este package cobre ambos.
// Para utiliza-lo eu adicionei no pubspec.yaml: path_provider: ^1.1.0
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  // Dei um ctrl+o aqui, para ver a lista de métodos que posso dar override
  @override
  void initState() {

    // Chamar o initState padrão antes.
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      newToDo["ok"] = false;
      _toDoController.text = "";
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {

    // Aguardar 1 segundo no loading, só de migué
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      // Função que organiza a lista deixando os checkeds abaixo:
      _toDoList.sort((elementoA, elementoB) {
        if (elementoA["ok"] && !elementoB["ok"]) return 1;
        else if(!elementoA["ok"] && elementoB["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  Widget buildItem (context, index) {

    /* Dismissible é o widget que permite que um item seja 'excluível' arrastando
     * o item para o lado. */
    return Dismissible(

      // A key precisa ser um valor único, foi usado um valor baseado no tempo.
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),

      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),

      direction: DismissDirection.startToEnd, // Direção que se deve mover o item para apagá-lo

      /* A child do Dismissible é o elemento que poderá ser apagado deslizando
       * para o lado. No caso, nosso item da ListView. */
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        // Ícone do item irá variar caso a tarefa esteja ou não conluída:
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]["ok"] = checked;
            _saveData();
          });
        },
      ),

      // Função chamada ao arrastar o item:
      onDismissed: (direction) {

        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida."),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              }
            ),

            duration: Duration(seconds: 2),
          );
          
          // Fazer o snack aparecer no Scafold:
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {

    // Função do pathProvider que retorna o diretório padrão de armazenamento
    // tanto do android quanto do iOS. ela é assíncrona, logo precisa do 'await'.
    final directory = await getApplicationDocumentsDirectory();

    return File("${directory.path}/data.json");
  }

  /* Função que salva os dados da lista no arquivo data.json */
  Future<File> _saveData() async {

    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  /* Função que lê o arquivo data.json */
  Future<String> _readData() async {

    try {

      final file = await _getFile();
      return file.readAsString();

    } catch (e) {

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),

      body: Column(
        children: <Widget>[

          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),

            child: Row(
              children: <Widget>[

                /* Widget Expanded foi utilizado para expandir o textfield. */
                Expanded(

                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),

                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),

          Expanded(

            child: RefreshIndicator(

              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),

              onRefresh: _refresh,
            )
          ),

        ],
      ),
    );
  }
}
