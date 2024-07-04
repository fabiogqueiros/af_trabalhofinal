// ignore: depend_on_referenced_packages
import "package:shared_preferences/shared_preferences.dart";
import 'package:flutter/material.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  //TextEditingController nomeController = TextEditingController();
  String nome = "";
  String email = "";

  void _init() async{
    final prefs = await SharedPreferences.getInstance();
    bool hasData = prefs.containsKey("nome");
    if(!hasData) hasData = prefs.containsKey("email");//Email vai ser obrigatorio
    //Se tem dado ele busca
    if(hasData) _recover();
  }
  void _recover() async{
    final prefs = await SharedPreferences.getInstance();
    nome = prefs.getString("nome")!;
    email = prefs.getString("email")!;
    setState((){});
  }


  /*void _save() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("nome", nomeController.text);

  }*/
  void _remove() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("nome");
    prefs.remove("email");
  }



  void navEntrar(context){
    if(email == "") {
      Navigator.pushNamed(context, "entrar");
    } else {
      Navigator.pushNamed(context, "dashboard");
    }
  }
  void navCadastrar(context){
    if(email != ""){
      //Fazer algum alerta na tela
    }
    else{
      Navigator.pushNamed(context, "cadastrar");
    }
  }
  void navPular(context){
    if(email == ""){
      Navigator.pushNamed(context, "dashboard");//arguments ...
    }
    else{
      Navigator.pushNamed(context, "dashboard");//arguments ...
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inicio"),),
      body: Column(
        children: [
          Text("Bem vindo $nome"),
          TextButton(onPressed: () => navEntrar(context), child: const Text("Entrar")),
          TextButton(onPressed: () => navCadastrar(context), child: const Text("Cadastrar")),
          TextButton(onPressed: () => navPular(context), child: const Text("Pular")),
        ],
      ),
    );
  }
}