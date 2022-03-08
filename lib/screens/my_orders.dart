import 'package:flutter/material.dart';
import 'package:sodhis_app/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sodhis_app/screens/dashboard.dart';
import 'package:sodhis_app/screens/multislider_home.dart';
import 'package:sodhis_app/utilities/basic_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyOrdersPage extends StatefulWidget {
  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  var _userId;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  _getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id').toString();
    });
  }

  Future _orderLists() async {
    var response = await http.post(
      new Uri.https(BASE_URL, API_PATH + "/my-orders"),
      body: {
        "user_id": _userId,
      },
      headers: {
        "Accept": "application/json",
        "authorization": basicAuth,
      },
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Widget _networkImage(url) {
    return Image(
      image: CachedNetworkImageProvider(url),
    );
  }

  Widget _emptyOrders() {
    return Center(child: Text('No orders found!'));
  }

  Widget _myOrdersBuilder() {
    return FutureBuilder(
      future: _orderLists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var errorCode = snapshot.data['ErrorCode'];
          var response = snapshot.data['Response'];
          if (errorCode == 0) {
            return SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: response.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: <Widget>[
                        SizedBox(
                          height: 12,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/order-details',
                              arguments: <String, String>{
                                'order_id':
                                response[index]['id'].toString(),
                              },
                            );
                          },
                          child: Container(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                              child: Container(
                                color: Color(0xFFf2f2f2),
                                child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(15, 0, 15, 0),
                                    child: Column(children: <Widget>[
                                      SizedBox(
                                        height: 8,
                                      ),
                                      response[index].containsKey("order_date")
                                          ? Container(
                                              alignment: Alignment.bottomLeft,
                                              child: Text(
                                                'Order Date: ' +
                                                    response[index]['order_date'],
                                                style: TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.black),
                                              ),
                                            )
                                          : Text(""),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      response[index].containsKey("title")
                                          ? Container(
                                              alignment: Alignment.bottomLeft,
                                              child: Text(
                                                response[index]['title'],
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.grey[800]),
                                              ),
                                            )
                                          : Text(""),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      response[index].containsKey("total")
                                          ? Container(
                                              alignment: Alignment.bottomLeft,
                                              child: Text(
                                                'Rs ' + response[index]['total'],
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.grey[800]),
                                              ),
                                            )
                                          : Text(""),
                                      SizedBox(
                                        height: 8,
                                      ),
                                    ]),
                                  ),

                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          } else {
            return _emptyOrders();
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text('My Orders'),
          ),
          body: Container(
            child: _myOrdersBuilder(),
          ),
        ), 
        onWillPop: () async{
           return Navigator.pushReplacement(context,
               MaterialPageRoute(builder: (context) => DashboardPage()));
        }
    );
  }
}
