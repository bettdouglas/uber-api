import 'package:latlong/latlong.dart';

class Place {

  String name0,name1,name2,name3,name4;
  LatLng point;
  String missing = '';

  Place({
    this.name0,this.name1,this.name2,this.name3,this.name4,this.point
  }){
    testMissing();
  }

  factory Place.fromSQL(List<dynamic> data){
    print(data.length);
    return Place(
      name0: data[0] ?? 'EMPTY',
      name1: data[1] ?? 'EMPTY',
      name2: data[2] ?? 'EMPTY',
      name3: data[3] == null ? 'EMPTY' : data[3],
      // name4: data[4] ?? 'EMPTY',
      // place: data[5] ?? 'NOT NAMED',
      point: Utils.fromSQLPoint(data[4])
    );
  }

  Map<String,dynamic> toMap() {
    return {
      "adm0" : name0,
      "adm1" : name1,
      "adm2" : name2,
      "adm3" : name3,
      "adm4" : name4,
      "coord" : Utils.stringFromLatLng(point)
    };
  }

  void testMissing(){
      if(this.name0=='EMPTY'){
        missing+='<NAME0>';
      }
      if(this.name1=='EMPTY'){
        missing+='<NAME1>';
      }
      if(this.name2=='EMPTY'){
        missing+='<NAME2>';
      }
      if(this.name3=='EMPTY'){
        missing+='<NAME3>';
      }
      if(this.name4=='EMPTY'){
        missing+='<NAME4>';
      }
    }

  @override
  String toString() {
    if(this.name1=='EMPTY'){
      return '''
        $name0
        Coordinates: $point
      ''';
    }
    if(this.name2=='EMPTY'){
      return '''
        $name0,$name1
        Coordinates: $point
      ''';
    }
    if(this.name3=='EMPTY'){
      return '''
        $name0,$name1,$name2
        Coordinates: $point
      ''';
    }
    if(this.name4=='EMPTY'){
      return '''
        $name0,$name1,$name2,$name3
        Coordinates: $point
      ''';
    }
    return '''
        $name0,$name1,$name2,$name3,$name4
        Coordinates: $point
      ''';
  }
    
}

class Utils {
  static LatLng fromSQLPoint(String geom) {

    String latt,longg;
    try {
      longg = geom.substring(geom.indexOf('(')+1,geom.indexOf(' '));
    }catch (e) {
      print(geom);
    }
    
    try {
      latt = geom.substring(geom.indexOf(' ')+1,geom.indexOf(')'));
    }catch (e) {
      print(geom);
    }

    
    double lat = double.parse(latt) ?? double.nan;
    double long = double.parse(longg) ?? double.nan;

    print('long: $long,lat: $lat');
    return LatLng(lat,long);
  }


  static String stringFromLatLng(LatLng point) {
    return 'POINT(${point.longitude} ${point.latitude}';
  }


}
