
import 'package:hello_angel/src/place.dart';
import 'package:postgres/postgres.dart';
import 'package:meta/meta.dart';

class DBHelper {

  PostgreSQLConnection connection;

  DBHelper({
    @required this.connection
  });
  ///get's the place names of the region involved given latitude and longitude
  Future<Place> getGeoName(double lat,double long) async {
    // String geom = Utils.
    var results = await connection.query('''
    SELECT gadm."NAME_0",gadm."NAME_1",gadm."NAME_2",gadm."NAME_3",gadm."NAME_4",places.name,ST_asText(places.geom) from gadm 
    INNER JOIN places on ST_Intersects(gadm.geom,places.geom)
    where ST_Intersects(gadm.geom,ST_geomfromtext('POINT($long $lat)',4326))
    limit 1
    '''
    );
    print('Returned result is $results');
    return Place.fromSQL(results[0]);
  }

  Future<Place> getPlaceName(double lat,double lng) async {
    var query = '''
      select "NAME_0","NAME_1","NAME_3","NAME_4",ST_astext(ST_geomFromText('POINT($lng $lat)',4326)) from gadm where ST_Intersects(geom,ST_geomFromText('POINT($lng $lat)',4326))
      limit 1
    ''';
    var results = await connection.query(query);
    return Place.fromSQL(results[0]);
  }

  ///get's the place names of the region involved given latitude and longitude
  Future<List<Place>> getGeoNames(double lat,double long,int number) async {
    var results = await connection.query('''
    SELECT gadm."NAME_0",gadm."NAME_1",gadm."NAME_2",gadm."NAME_3",gadm."NAME_4",places.name,ST_asText(places.geom) from gadm 
    INNER JOIN places on ST_Intersects(gadm.geom,places.geom)
    limit $number
    '''
    );
    List<Place> places = [];
    for(var row in results){
      var place = Place.fromSQL(row);
      print(place);
      places.add(place);
    }
    return places;
  }

  Future<List<Place>> testPlacesDepth(Map<String,String> missingPlaces) async {
    List<Place> places = [];
    print('Starting execution at : ${DateTime.now()}');
    var results = await connection.query('''
      SELECT gadm."NAME_0",gadm."NAME_1",gadm."NAME_2",gadm."NAME_3",gadm."NAME_4",places.name,ST_asText(places.geom) from gadm 
      INNER JOIN places on ST_Intersects(gadm.geom,places.geom)
      ''',timeoutInSeconds: 60
      );
    print('Query finished at ${DateTime.now()}');
      for(var result in results){
        var place = Place.fromSQL(result);
        getCountryDepth(missingPlaces, place);
        print(place);
        places.add(place);
      }
    return places;
  }

  static void getCountryDepth(Map<String,String> missingPlaces,Place place){
    if(place.missing!=''){
      missingPlaces.putIfAbsent(place.name0, ()=>place.missing);
    }
  }
}


