import 'package:angel_hot/angel_hot.dart';
import 'package:hello_angel/src/server.dart';
// import 'package:hello_angel/src/time-est.dart';
String hostName;

main(List<String> args) async {
  print("Db-host should be ${args[0]}");
  if(args[0]==null){
    print('Cannot open connection to the database');
  } else {
    hostName = args[0];
  }
  // var server = createServer(host: args[0]);
  
  var hotReload = HotReloader(createServer, [
    'bin/main.dart'
  ]);
  await hotReload.startServer('localhost',3000);
  // var timeService = TimeEstimator();
  // await timeService.init();
  // if(timeService.isOpen) {
  //   // await timeService.getTravelTimeBtwnPoints(313, 59);
  //   // await timeService.getPlaceNameFromHexClusters(-1.300921, 36.828195);
  //   await timeService.getUberTravelTimeByHour(36.828195, -1.300921, 36.98107,-1.26680,7,year: 2019,quarter: 2);
  // }
}

