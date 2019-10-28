
import 'dart:convert';

import 'package:angel_framework/angel_framework.dart';
import 'package:hello_angel/src/dbhelper.dart';
import 'package:hello_angel/src/time-est.dart';
import 'package:postgres/postgres.dart';

Future<Angel> createServer() async {

  PostgreSQLConnection connection = PostgreSQLConnection('uber-db', 5432, 'gis',username: 'postgres', password: "alliswell");
  await connection.open();
  
  if (!connection.isClosed) {
    print('Database connection is open');
  }
  
  var dbhelper = DBHelper(connection: connection);
  var uberizer = TimeEstimator();
  await uberizer.init();

  var app = Angel();

  // app.logger = Logger("helloangel")
  //   ..onRecord.listen((rec) {
  //     if(rec.error) print(rec.error);
  //     if(rec.stackTrace != null) print(rec.stackTrace.toString());
  //   });

  app.container.registerSingleton(dbhelper);

  app.get('/', (req, res) => res.write('Hello from angel'));

  app.get('headers', (req, res) {
    req.headers.forEach((key, value) {
      // print('$key,$value');
      res.write('$key -> $value');
      res.writeln();
    });
  });

  app.get('getUberTravelTime/:startLat/:startLng/:endLat/:endLng/:year/:quarter', (req,res) async {
    print('getUberTravelTime request');
    var startLat = double.tryParse(req.params['startLat']);
    var startLng = double.tryParse(req.params['startLng']);
    var endLat = double.tryParse(req.params['endLat']);
    var endLng = double.tryParse(req.params['endLng']);
    var year = int.tryParse(req.params['year']);
    var quarter = int.tryParse(req.params['quarter']);

    if(uberizer.isOpen) {
      var list = await uberizer.getUberTravelTime(startLng, startLat, endLng, endLat,year: year,quarter: quarter);
      // print(list);
      list.forEach((f)=>res.writeln(f));
      // res.writeln(list);
    } else {
      res.writeln('Database is not responding or has crashed');
    }
  });

  app.get('getUberTravelTimeByHour/:startLat/:startLng/:endLat/:endLng/:year/:quarter/:hour', (req,res) async {
    print('getUberTravelTime request');

    var startLat = double.tryParse(req.params['startLat']);
    var startLng = double.tryParse(req.params['startLng']);
    var endLat = double.tryParse(req.params['endLat']);
    var endLng = double.tryParse(req.params['endLng']);
    var year = int.tryParse(req.params['year']);
    var quarter = int.tryParse(req.params['quarter']);
    var hour = int.tryParse(req.params['hour']);

    if(uberizer.isOpen){
      var time = await uberizer.getUberTravelTimeByHour(startLng, startLat, endLng, endLat, hour,quarter: quarter,year: year);
      print(time);
      res.writeln(jsonEncode(time));
    } else {
      res.writeln('Database is not responding or has crashed');      
    }

  });

  app.get('/random', (req,res) {
    res.redirect('https://twitter.com/bettdougie');
  });

  app.get('place/fromlatlng/:lat/:lng', (req, res) async {
    var lat = double.tryParse(req.params['lat']);
    var lng = double.tryParse(req.params['lng']);

    if (lat == null || lng == null) {
      res.write(
          'Please enter coordinates in proper format as localhost:3000/place/fromlatlng/-3.45/67.7');
    } else {
      print("Getting placename for lat > $lat, lng > $lng");
      var place = await dbhelper.getPlaceName(lat, lng);
      if (place != null) {
        print(place);
        // res.write('${place.name0},${place.name1},${place.name2},');
        return {
          "COUNTRY" : place.name0,
          "LEVEL1" : place.name1,
          "LEVEL2" : place.name2,
        };
      } else {
        print('Place is null');
        // res.write('Internal server error');
        // res.writeln();
        return {
          "ERROR" : "Invalid coordinates"
        };
      }
    }
  });

  app.addRoute('GET', 'greet', (req, res) async {
    await req.parseBody();
    res.write('Hello there, I am using Angel');
  });

  app.addRoute('GET', 'greet/:id', (req, res) async {
    await req.parseBody();
    int id = int.tryParse(req.params['id']);
    if (id == null) {
      throw AngelHttpException.badRequest(message: 'Bad Request');
    } else {
      res.write('Hello user${req.params['id']}');
    }
  });

  app.addRoute('GET', 'add/:num1/:num2', (req, res) {
    int num1 = int.tryParse(req.params['num1']);
    int num2 = int.tryParse(req.params['num2']);

    if (num1 == null || num2 == null) {
      throw AngelHttpException.badRequest(message: 'Bad Request');
    } else {
      res.write('$num1 + $num2 = ${num1 + num2}');
    }
  });

  var subRouter = Router()..get('/', 'Subroute');

  var subApp = new Angel()
    ..get('/hello', (req, res) {
      res.write('Hello');
    });

  app.mount('/helloo', subApp);

  var oldErrorHandler = app.errorHandler;

  app.errorHandler = (e, reqctx, respctx) {
    if (e.statusCode == 400) {
      respctx.write('Oops!. You forgot to include your name');
    } else {
      return oldErrorHandler(e, reqctx, respctx);
    }
  };

  print('Server created. Starting now');

  return app;
}

Future<bool> validateDouble(RequestContext req, ResponseContext res) async {
  await req.parseBody();
  var lat = double.tryParse(req.params['lat']);
  var lng = double.tryParse(req.params['lng']);

  if (lat == null || -89 < lat || lat > 89) {
    res.write('Invalid latitude value -89 < lat > 89 ');
    return false;
  }
  if (lng == null || -180 < lng || lng > 180) {
    res.write(
        'Invalid longitude value. Please enter valid number in range -180 > longitude < 180');
    return false;
  }
  return true;
}
