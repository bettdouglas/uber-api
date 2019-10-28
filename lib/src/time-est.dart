import 'package:postgres/postgres.dart';

class TimeEstimator {

  String host;

  PostgreSQLConnection connection = PostgreSQLConnection('uber-db', 5432, 'zindi',username: 'postgres',password: 'alliswell');
  bool get isOpen => !connection.isClosed;

  init()  async {
    try {
      await connection.open();
      if(!connection.isClosed) {
        print('Database is open');
      }      
    } catch (e) {
      print('Error opening db \n $e');
    }    
  }

  Future getTravelTimeBtwnPoints(int source,int dest) async {
    String stmt = "select * from nrb_times where sourceid like '$source' and dstid='$dest'";
    print('Starting query');
    var res = await connection.query(stmt);
    print('Finished query');
    for(var re in res) {
      print(re);
    }
  }

  Future<Map<int,String>> getPlaceNameFromHexClusters(double lat,double lon) async {
    String stmt = """
      SELECT "id","DISPLAY_NAME" from hexclusters where ST_Intersects(geom,ST_GeomFromText('POINT($lon $lat)',4326))
    """;
    var res = await connection.query(stmt);
    return {res[0][0] : res[0][1]};
  }

  Future<List<Map<String,dynamic>>> getUberTravelTime(double startLng,double startLat,double endLng,double endLat,{int year,int quarter}) async {

    String yearString = getTableNameToUse(year,quarter);
    print("Table used => $yearString");
    String stmt = """
      with startend as (select (
        select source."MOVT_ID" from hexclusters as source 
        where ST_Intersects(source.geom,ST_GeomFromText('POINT($startLng $startLat)',4326))
        ) as source_id,
        (select source."MOVT_ID" from hexclusters as source 
        where ST_Intersects(source.geom,ST_GeomFromText('POINT($endLng $endLat)',4326))) as dest_id)
        select * from $yearString join startend on (startend.source_id=$yearString.sourceid and startend.dest_id=$yearString.dstid)
        order by hod::numeric
    """;
    var res = await connection.query(stmt);
    if(res.isEmpty) {
      return [
          {
            "mean" : null,
            "mean_std_dev" : null,
            "geometric" : null,
            "geometric_std_dev" :null
          },
      ];
    }
    for (var re in res) {
      print(mapQueryResults(re));
      // print(re);
    }
    return res.map((re)=>mapQueryResults(re)).toList();
  }

  Future getUberTravelTimeByHour(double startLng,double startLat,double endLng,double endLat,int hod,{int year,int quarter}) async {
    
    String yearString = getTableNameToUse(year,quarter);
    print("Table used => $yearString");

    String stmt = """
      with startend as (select (
        select source."MOVT_ID" from hexclusters as source 
        where ST_Intersects(source.geom,ST_GeomFromText('POINT($startLng $startLat)',4326))
        ) as source_id,
        (select source."MOVT_ID" from hexclusters as source 
        where ST_Intersects(source.geom,ST_GeomFromText('POINT($endLng $endLat)',4326))) as dest_id)
        select * from $yearString join startend on (startend.source_id=$yearString.sourceid and startend.dest_id=$yearString.dstid)
        where hod = '$hod'
        order by hod::numeric
    """;
    var res = await connection.query(stmt);
      if(res.isEmpty) {
        //no hour found for the query
        return {
            "mean" : null,
            "hod": null,
            "mean_std_dev" : null,
            "geometric" : null,
            "geometric_std_dev" :null
          };
    }
    for(var r in res){
      print(mapQueryResults(r));
    }
    return mapQueryResults(res[0]);
  }

  String getTableNameToUse(int year,int quarter) {
    String yearString;

    if(year!=null) {
      assert(year>=2017 && year<=2019,'The amount in years should be less than 2019');
      if(year==2019) {
        yearString = 'nrb_2019';
      } else if (year==2018) {
        yearString = 'nrb_2018';
      } else if(year==2017) {
        yearString = 'nrb_2017';
      }
    } else {
      //default to 2019
      yearString = 'nrb_2019';
    }
    if(quarter!=null) {
      assert(quarter>=1 && quarter<=4,'The quarter duration is greater than four');
      if(quarter==1){
        yearString += '_1';
      } else if(quarter==2) {
        yearString += '_2';
      } else if(quarter==3) {
        yearString += '_3';
      } else {
        yearString += '_4';
      }
    } else {
      //default to third quarter
      yearString += '_3';
    }
    return yearString;
  }

  ///output 
  ///{
  ///"mean": x, => 3
  ///"mean_std_dev":y, => 4
  ///"geometric":z, => 5
  ///"geometric_std_dev" => 6
  ///}
  Map<String,dynamic> mapQueryResults(List<dynamic> list) {
    return {
      "mean" : list[3],
      "hod" : list[2],
      "mean_std_dev" : list[4],
      "geometric" : list[5],
      "geometric_std_dev" : list[6]
    };
  }
}


