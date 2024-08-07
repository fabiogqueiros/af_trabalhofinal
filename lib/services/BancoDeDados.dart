import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BancoDados {
  static final BancoDados _instancia = BancoDados.internal();
  static Database? _bd;

  factory BancoDados() => _instancia;

  BancoDados.internal();

  Future<Database> get bd async {
    if (_bd == null) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _bd = await iniciaBanco();
    }
    return _bd!;
  }

  // configura a foreign key
  static Future<void> foreignKey(Database bd) async {
    await bd.execute('PRAGMA foreign_keys = ON');
  }

  Future<Database> iniciaBanco() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String caminho = join(await getDatabasesPath(), 'gamesTracker.db');

    const String scriptUser =
        "CREATE TABLE user(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR NOT NULL, email VARCHAR NOT NULL, password VARCHAR NOT NULL);";
    const String scriptGenre =
        "CREATE TABLE genre(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR NOT NULL);";
    const String scriptGame =
        "CREATE TABLE game(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, name VARCHAR NOT NULL UNIQUE, description TEXT NOT NULL, release_date VARCHAR NOT NULL, FOREIGN KEY(user_id) REFERENCES user(id));";
    const String scriptGameGenre =
        "CREATE TABLE game_genre(game_id INTEGER NOT NULL, genre_id INTEGER NOT NULL, FOREIGN KEY(game_id) REFERENCES game(id), FOREIGN KEY(genre_id) REFERENCES genre(id));";
    const String scriptReview =
        "CREATE TABLE review(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, game_id INTEGER NOT NULL, score REAL NOT NULL, description TEXT, date VARCHAR NOT NULL, FOREIGN KEY(user_id) REFERENCES user(id), FOREIGN KEY(game_id) REFERENCES game(id));";

    return await openDatabase(caminho, version: 1, onConfigure: foreignKey,
        onCreate: (bd, version) async {
      await bd.execute(scriptUser);
      await bd.execute(scriptGenre);
      await bd.execute(scriptGame);
      await bd.execute(scriptGameGenre);
      await bd.execute(scriptReview);
      // print("criou o banco");
    });
  }

  /* funções do crud */
  // insere
  Future<void> insereUser(String nome, String email, String password) async {
    final banco = await bd;
    Map<String, dynamic> user = {
      'name': nome,
      'email': email,
      'password': password
    };
    await banco.insert('user', user,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> insereGenre(String nome) async {
    final banco = await bd;
    Map<String, dynamic> genre = {'name': nome};
    await banco.insert('genre', genre,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> insereGame(
      int userId, String name, String description, String releaseDate) async {
    final banco = await bd;
    Map<String, dynamic> game = {
      'user_id': userId,
      'name': name,
      'description': description,
      'release_date': releaseDate
    };
    int gameId = await banco.insert('game', game,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return gameId;
  }

  Future<void> insereGameGenre(int gameId, int genreId) async {
    final banco = await bd;
    Map<String, dynamic> gameGenre = {'game_id': gameId, 'genre_id': genreId};
    await banco.insert('game_genre', gameGenre,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> insereReview(int userId, int gameId, double score,
      String description, String date) async {
    final banco = await bd;
    Map<String, dynamic> review = {
      'user_id': userId,
      'game_id': gameId,
      'score': score,
      'description': description,
      'date': date
    };
    await banco.insert('review', review,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // gets
  // retorna senha e usuário - login
  Future<Map<String, dynamic>?> getUserLogin(
      String name, String email, String password) async {
    final banco = await bd;
    String script = 'name = ? AND email = ? AND password = ?';
    List<Map<String, dynamic>> user = await banco
        .query('user', where: script, whereArgs: [name, email, password]);

    if (user.isNotEmpty) {
      return user.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserNavLogin(
      String email, String password) async {
    final banco = await bd;
    String script = 'email = ? AND password = ?';
    List<Map<String, dynamic>> user =
        await banco.query('user', where: script, whereArgs: [email, password]);

    if (user.isNotEmpty) {
      return user.first;
    } else {
      return null;
    }
  }

  // retorna id do usuário
  Future<List<int>?> getUserId() async {
    final banco = await bd;
    final results = await banco.query('user', columns: ['id']);
    final ids = results.map((row) => row['id'] as int).toList();

    if (ids.isNotEmpty) {
      return ids;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>> getDescriptionGame(int id, String name) async {
    final banco = await bd;
    String script = 'id = ? AND name = ?';
    List<Map<String, dynamic>> description = await banco.query('game',
        columns: ['description'], where: script, whereArgs: [id, name]);

    return description.first;
  }

  Future<List<Map<String, dynamic>>?> getDescriptionReview(
      int id, String name) async {
    final banco = await bd;
    String script = 'id = ? AND name = ?';
    List<Map<String, dynamic>> description = await banco.query('review',
        columns: ['description', 'score'],
        where: script,
        whereArgs: [id, name]);

    if (description.isNotEmpty) {
      return description;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getJogos() async {
    final banco = await bd;
    return await banco.query('game', columns: ['name', '']);
  }

  Future<void> deleteGameByName(String name) async {
    final banco = await bd;
    await banco.transaction((txn) async {
      // Primeiro, exclua os registros relacionados de game_genre e review
      await txn.delete('game_genre', where: 'game_id IN (SELECT id FROM game WHERE name = ?)', whereArgs: [name]);
      await txn.delete('review', where: 'game_id IN (SELECT id FROM game WHERE name = ?)', whereArgs: [name]);
      // Em seguida, exclua o jogo
      await txn.delete('game', where: 'name = ?', whereArgs: [name]);
    });
  }

  Future<void> deleteAllData() async {
    final db = await bd;
    await db.delete('user');
    await db.delete('genre');
    await db.delete('game');
    await db.delete('game_genre');
    await db.delete('review');
  }

  Future<void> insereGenresIniciais() async {
    List<String> generos = [
      "Ação",
      "Suspense",
      "Corrida",
      "Estratégia",
      "Esportes",
      "Plataforma"
    ];
    for (String genero in generos) {
      await insereGenre(genero);
    }
  }
}
