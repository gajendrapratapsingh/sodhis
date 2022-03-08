import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:sodhis_app/components/CustomRadioWidget.dart';
import 'package:sodhis_app/components/RadioItem.dart';
import 'package:sodhis_app/components/ThemeColor.dart';
import 'package:sodhis_app/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sodhis_app/utilities/basic_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:sodhis_app/services/cart_badge.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sodhis_app/services/cart.dart';
import 'package:sodhis_app/components/general.dart';

import 'checkoutview.dart';

class CheckOutNewPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CheckOutNewPage>
    with SingleTickerProviderStateMixin {
  var _userId, takeaway_address;
  var _branchId;
  var _warehouseId;
  var _stockItem;
  var _deliveryType;
  var _dateDropdownVal = 'Today';
  var _timeDropdownVal;

  var type_of_order = "";
  var _placeOrderBtnParent = 'Place Order';
  var _placeOrderBtn = 'Place Order';
  Future _myCartList;
  final nameController = TextEditingController();
  final instructionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var errorCode;
  var response;
  var data, total;
  AnimationController _animationController;
  List dataModel = new List();
  Map<String, dynamic> value = new Map();
  String _paymentMode = "Online Payment";
  bool isPress1 = false;
  bool isPress2 = false;

  String _name;
  List<RadioModel> sampleData = new List<RadioModel>();
  String radioButtonItem = 'Today';
  String radioButtonItem1 = 'OnlIne Delivery';
  int id;
  int id1=1;
  var today, tomorrow;
  String formatted;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    today = DateTime(now.year, now.month, now.day);
    formatted = formatter.format(today);
    _timeDropdownVal = DateFormat('hh:mm:ss').format(DateTime.now());

    print("vdfsvsfvdsfvdsfvdvd"+id1.toString());
    _getUser();
  }

  void dispose() {
    nameController.dispose();
    instructionController.dispose();
    super.dispose();
  }

  _getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id').toString();
      takeaway_address = prefs.getString('takeAwayAddress').toString();
      _branchId = prefs.getInt('branch_id').toString();
      _warehouseId = prefs.getInt('warehouse_id').toString();
      _stockItem = prefs.getString('cart');
      _myCartList = _cartLists();
      _name = prefs.getString('name');
      _deliveryType = prefs.getString('delivery_type');
    });
  }

  showConfirmDialog(id, cancel, done, title, content) {
    print(id);
    final _cart = Provider.of<CartBadge>(context, listen: false);
    // Set up the Button
    Widget cancelButton = FlatButton(
      child: Text(cancel),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget doneButton = FlatButton(
      child: Text(done),
      onPressed: () {
        Navigator.of(context).pop();
        removeItemFromCart(id);
        _cart.showCartBadge(_userId);
      },
    );

    // Set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        cancelButton,
        doneButton,
      ],
    );

    // Show the Dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void removeItemFromCart(cartId) async {
    var response = await http.post(
      new Uri.https(BASE_URL, API_PATH + "/cart-delete"),
      body: {
        "user_id": _userId.toString(),
        "cart_id": cartId.toString(),
      },
      headers: {
        "Accept": "application/json",
        "authorization": basicAuth,
      },
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var errorCode = data['ErrorCode'];
      var errorMessage = data['ErrorMessage'];
      if (errorCode == 0) {
        Fluttertoast.showToast(msg: 'Item removed successfully');
      } else {
        Fluttertoast.showToast(msg: errorMessage);
      }
      setState(() {
        _myCartList = _cartLists();
      });
    } else {
      throw Exception('Something went wrong');
    }
  }

  Iterable<TimeOfDay> getTimes(
      TimeOfDay startTime, TimeOfDay endTime, Duration step) sync* {
    var hour = startTime.hour;
    var minute = startTime.minute;
    do {
      yield TimeOfDay(hour: hour, minute: minute);
      minute += step.inMinutes;
      while (minute >= 60) {
        minute -= 60;
        hour++;
      }
    } while (hour < endTime.hour ||
        (hour == endTime.hour && minute <= endTime.minute));
  }

  timeSlot(date) {
    var currDt = DateTime.now();
    var hourSlot = 10;
    var minuteSlot = 0;
    if (date == 'Today') {
      hourSlot = currDt.hour + 1;
      var minute = currDt.minute;
      minuteSlot = 0;
      if (minute > 30) {
        hourSlot = currDt.hour + 2;
      } else {
        minuteSlot = 30;
      }
    }

    final startTime = TimeOfDay(hour: hourSlot, minute: minuteSlot);
    final endTime = TimeOfDay(hour: 20, minute: 0);
    final step = Duration(minutes: 30);

    final times = getTimes(startTime, endTime, step)
        .map((tod) => tod.format(context))
        .toList();
    return times;
  }

  Future<Null> refreshList() async {
    await Future.delayed(
      Duration(milliseconds: 500),
    );
    setState(() {
      _myCartList = _cartLists();
    });
    //setState(() {});
    return null;
  }

  Future _cartLists() async {
    var response = await http.post(
      new Uri.https(BASE_URL, API_PATH + "/cart"),
      body: {
        "user_id": _userId,
      },
      headers: {
        "Accept": "application/json",
        "authorization": basicAuth,
      },
    );
    if (response.statusCode == 200) {
      data = json.decode(response.body);
      value = json.decode(response.body);
      var result = data['Response'];
      if (data['ErrorCode'] == 0) {
        setState(() {
          dataModel = result["items"];
        });
      }

      //return result;

      return data;
    } else {
      throw Exception('Something went wrong');
    }
  }

  Widget _emptyCart() {
    return Center(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              // height: 150,
              // width: 150,
              margin: const EdgeInsets.only(bottom: 20),
              child: Image.asset("assets/images/empty_cart.png"),
            ),
            Text(
              "No Items Yet!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 30, right: 30, top: 10, bottom: 80),
              child: Text(
                "Browse and add items in your shopping bag.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  changeThemeMode1() {
    if (isPress1) {
      _animationController.forward(from: 0.0);
    } else {
      _animationController.reverse(from: 1.0);
    }
  }

  changeThemeMode2() {
    if (isPress2) {
      _animationController.forward(from: 0.0);
    } else {
      _animationController.reverse(from: 1.0);
    }
  }

  ThemeColor lightMode = ThemeColor(
    gradient: [
      const Color(0xDDFF0080),
      const Color(0xDDFF8C00),
    ],
    backgroundColor: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF000000),
    toggleButtonColor: const Color(0xFFFFFFFF),
    toggleBackgroundColor: const Color(0xFFe7e7e8),
    shadow: const [
      BoxShadow(
        color: const Color(0xFFd8d7da),
        spreadRadius: 5,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  );

  ThemeColor darkMode = ThemeColor(
    gradient: [
      const Color(0xFF8983F7),
      const Color(0xFFA3DAFB),
    ],
    backgroundColor: Colors.grey[300],
    textColor: const Color(0xFFFFFFFF),
    toggleButtonColor: const Color(0xFf34323d),
    toggleBackgroundColor: const Color(0xFF222029),
    shadow: const <BoxShadow>[
      BoxShadow(
        color: const Color(0x66000000),
        spreadRadius: 5,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  );

  void _showCouponModeDialog(context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            height: 60,
            width: 60,
            margin: const EdgeInsets.only(bottom: 20),
            child: Image.asset("assets/images/wallet.png"),
          ),
          content: new Container(
            child: new Wrap(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 20),
                  child: Column(
                    children: [
                      Text(
                        "Insufficient Balance",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Your wallet is low on balance. Kindly recharge to place order.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        margin: new EdgeInsets.only(
                            top: 20, left: 30, right: 30, bottom: 30),
                        child: Align(
                          alignment: Alignment.center,
                          child: ButtonTheme(
                            minWidth: MediaQuery.of(context).size.width,
                            child: RaisedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 48.0),
                              shape: StadiumBorder(),
                              child: Text(
                                "OK",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cartListBuilder() {
    // final _counter = Provider.of<CartBadge>(context);
    final _cartProvider = Provider.of<Cart>(context);
    return FutureBuilder(
      future: _cartProvider.getCartList(_userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          errorCode = snapshot.data['ErrorCode'];
          response = snapshot.data['Response'];
          if (errorCode == 0) {
            return Column(children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(left: 15, right: 15, top: 15),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: Theme.of(context).accentColor,
                            ),
                            title: Text(
                              'Deliver to',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              response['address'] != null
                                  ? response['address'].toString()
                                  : 'No address found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: GestureDetector(
                              child: Text(
                                response['address'] != null
                                    ? 'Change'
                                    : 'Add New',
                                style: TextStyle(
                                  color: Theme.of(context).accentColor,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () {
                                snapshot.data['address'] != null
                                    ? Navigator.pushNamed(
                                        context, '/change-address')
                                    : Navigator.pushNamed(
                                        context, '/addnewaddress');
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(left: 15, right: 15),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              CustomRadioWidget(
                                value: 1,
                                groupValue: id1,
                                onChanged: (val) {
                                  setState(() {
                                    radioButtonItem1 = 'OnlIne Delivery';
                                    id1 = 1;

                                  });
                                },
                              ),
                              Text(
                                "Online pyment",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              CustomRadioWidget(
                                value: 2,
                                groupValue: id1,
                                onChanged: (val) {
                                  setState(() {
                                    radioButtonItem1 = 'Cash On Delivery';
                                    id1 = 2;

                                  });
                                },
                              ),
                              Text(
                                "Cash On Delivery",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),

                            ]),
                      ),
                      /*  Container(
                                  color: Colors.white,
                                  margin: EdgeInsets.only(left: 15, right: 15),
                                  padding: const EdgeInsets.only(left: 25, right: 25),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    underline: Container(
                                      height: 1,
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        child: Text(
                                          'Choose Time',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                          ),
                                        ),
                                        value: '',
                                      ),
                                      for (var i = 0;
                                      i < timeSlot(_dateDropdownVal).length;
                                      i++)
                                        DropdownMenuItem<String>(
                                          child: Text(
                                            timeSlot(_dateDropdownVal)[i],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                            ),
                                          ),
                                          value: timeSlot(_dateDropdownVal)[i],
                                        ),
                                    ],
                                    value: _timeDropdownVal,
                                    onChanged: (String value) {
                                      setState(() {
                                        _timeDropdownVal = value;
                                      });
                                    },
                                  ),
                                ),*/

                      SizedBox(height: 10),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(left: 15, right: 15),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 12, right: 12, bottom: 10),
                          child: Text(
                            'Cart Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        child: ListView.builder(
                          itemCount: response['items'].length,
                          shrinkWrap: true,
                          primary: false,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(
                                      left: 16, right: 16, top: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                  child: Slidable(
                                    actionPane: SlidableDrawerActionPane(),
                                    child: Row(
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/product-details',
                                              arguments: <String, String>{
                                                'product_id': response['items']
                                                        [index]['id']
                                                    .toString(),
                                                'title': response['items']
                                                    [index]['product_name'],
                                              },
                                            );
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(
                                                right: 8,
                                                left: 8,
                                                top: 8,
                                                bottom: 8),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                              //color: Colors.blue.shade200,
                                              image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                          response['items']
                                                                  [index][
                                                              'product_image']),
                                                  fit: BoxFit.cover),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/product-details',
                                                      arguments: <String,
                                                          String>{
                                                        'product_id':
                                                            response['items']
                                                                        [index]
                                                                    ['id']
                                                                .toString(),
                                                        'title': response[
                                                                'items'][index]
                                                            ['product_name'],
                                                      },
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.only(
                                                        right: 8, top: 0),
                                                    child: Text(
                                                      response['items'][index]
                                                          ['product_name'],
                                                      maxLines: 2,
                                                      softWrap: true,
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(0.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Text(
                                                          "\u20B9 " +
                                                              "${response['items'][index]['amount']}",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          children: <Widget>[
                                                            GestureDetector(
                                                              onTap: () async {
                                                                _cartLists();
                                                                setState(() {
                                                                  if (response['items']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'quantity'] >=
                                                                      1) {
                                                                    response['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'quantity']--;
                                                                  }
                                                                });
                                                                var _amount = response['items']
                                                                            [index]
                                                                        [
                                                                        'rate'] *
                                                                    response['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'quantity'];
                                                                if (response['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'quantity'] ==
                                                                    0) {
                                                                  _amount = 0;
                                                                }
                                                                var res =
                                                                    await http
                                                                        .post(
                                                                  new Uri.https(
                                                                      BASE_URL,
                                                                      API_PATH +
                                                                          "/cart-add"),
                                                                  body: {
                                                                    "user_id":
                                                                        _userId
                                                                            .toString(),
                                                                    "product_id":
                                                                        response['items'][index]['id']
                                                                            .toString(),
                                                                    "quantity": response['items'][index]
                                                                            [
                                                                            'quantity']
                                                                        .toString(),
                                                                    "rate": response['items'][index]
                                                                            [
                                                                            'rate']
                                                                        .toString(),
                                                                    "amount":
                                                                        _amount
                                                                            .toString(),
                                                                    "offer_price":
                                                                        response['items'][index]['offer_price']
                                                                            .toString()
                                                                  },
                                                                  headers: {
                                                                    "Accept":
                                                                        "application/json",
                                                                    "authorization":
                                                                        basicAuth
                                                                  },
                                                                );
                                                                if (res.statusCode ==
                                                                    200) {
                                                                  var data = json
                                                                      .decode(res
                                                                          .body);
                                                                  print(data);
                                                                  if (data[
                                                                          'ErrorCode'] ==
                                                                      0) {
                                                                    SharedPreferences
                                                                        prefs =
                                                                        await SharedPreferences
                                                                            .getInstance();
                                                                    prefs.setInt(
                                                                        'cart_count',
                                                                        data['Response']
                                                                            [
                                                                            'count']);
                                                                  }
                                                                }
                                                              },
                                                              child: Container(
                                                                height: 25,
                                                                width: 25,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .grey,
                                                                    width: 2,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(25 /
                                                                              2),
                                                                ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .remove,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 15,
                                                            ),
                                                            Text(response['items']
                                                                        [index]
                                                                    ['quantity']
                                                                .toString()),
                                                            SizedBox(
                                                              width: 15,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () async {
                                                                _cartLists();
                                                                setState(() {
                                                                  response['items']
                                                                          [
                                                                          index]
                                                                      [
                                                                      'quantity']++;
                                                                });
                                                                var res =
                                                                    await http
                                                                        .post(
                                                                  new Uri.https(
                                                                      BASE_URL,
                                                                      API_PATH +
                                                                          "/cart-add"),
                                                                  body: {
                                                                    "user_id":
                                                                        _userId
                                                                            .toString(),
                                                                    "product_id":
                                                                        response['items'][index]['id']
                                                                            .toString(),
                                                                    "quantity": response['items'][index]
                                                                            [
                                                                            'quantity']
                                                                        .toString(),
                                                                    "rate": response['items'][index]
                                                                            [
                                                                            'rate']
                                                                        .toString(),
                                                                    "amount": response['items'][index]
                                                                            [
                                                                            'rate'] *
                                                                        response['items'][index]
                                                                            [
                                                                            'quantity'],
                                                                    "offer_price":
                                                                        response['items'][index]['offer_price']
                                                                            .toString()
                                                                  },
                                                                  headers: {
                                                                    "Accept":
                                                                        "application/json",
                                                                    "authorization":
                                                                        basicAuth
                                                                  },
                                                                );
                                                                if (res.statusCode ==
                                                                    200) {
                                                                  var data = json
                                                                      .decode(res
                                                                          .body);
                                                                  if (data[
                                                                          'ErrorCode'] ==
                                                                      0) {
                                                                    SharedPreferences
                                                                        prefs =
                                                                        await SharedPreferences
                                                                            .getInstance();
                                                                    prefs.setInt(
                                                                        'cart_count',
                                                                        data['Response']
                                                                            [
                                                                            'count']);
                                                                  }
                                                                }
                                                              },
                                                              child: Container(
                                                                height: 25,
                                                                width: 25,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(25 /
                                                                              2),
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .grey,
                                                                    width: 2,
                                                                  ),
                                                                ),
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons.add,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          flex: 100,
                                        )
                                      ],
                                    ),
                                    secondaryActions: <Widget>[
                                      IconSlideAction(
                                        caption: 'Delete',
                                        color: Colors.red,
                                        icon: Icons.delete,
                                        onTap: () {
                                          showConfirmDialog(
                                              response['items'][index]
                                                  ['cart_id'],
                                              'Cancel',
                                              'Remove',
                                              'Remove Item',
                                              'Are you sure want to remove this item?');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        margin: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 15, left: 12, right: 12),
                              child: Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Divider(
                              height: 26,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 12),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "\u20B9 " +
                                          response['total_price'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 12),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Delivery Fee",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "\u20B9 " +
                                          response['delivery_fee'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 12),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "\u20B9 " + response['total'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Container(
                            color: Colors.white,
                            height: 60,
                            width: MediaQuery.of(context).size.width * 0.50,
                            // padding: EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Total Price',
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                      fontSize: 12),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  response['total_price'] != null
                                      ? "\u20B9 " +
                                          response['total_price'].toString()
                                      : 0.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
                              setState(() {
                                _loading = true;
                              });

                              if (id1!=null) {

                                if(id1==1) {
                                  var response1 = await http.post(
                                    new Uri.https(
                                        BASE_URL, API_PATH + "/walletbalance"),
                                    body: {
                                      "user_id": _userId,
                                    },
                                    headers: {
                                      "Accept": "application/json",
                                      "authorization": basicAuth,
                                    },
                                  );
                                  if (response1.statusCode == 200) {
                                    var data = json.decode(response1.body);
                                    if (data['Response'] != null) {
                                      if (int.parse(
                                          double.parse(data['Response']
                                          ['total_balance'])
                                              .round()
                                              .toString()) <
                                          int.parse(response['total_price']
                                              .toString())) {
                                        setState(() {
                                          _loading = false;
                                        });
                                        _showCouponModeDialog(context);
                                      } else {
                                        //if (_timeDropdownVal != '') {
                                        var res = await http.post(
                                          new Uri.https(BASE_URL,
                                              API_PATH + "/createorder"),
                                          body: {
                                            "user_id": _userId.toString(),
                                            "type_of_order": "hd",
                                            "instruction": "",
                                            "discounted_price": "",
                                            "delivery_date": formatted
                                                .toString(),
                                            "delivery_time":
                                            _timeDropdownVal.toString(),
                                            "coupon_code": "",
                                            "coupon_discount": ""
                                          },
                                          headers: {
                                            "Accept": "application/json",
                                            "authorization": basicAuth
                                          },
                                        );
                                        print(json.encode({
                                          "user_id": _userId.toString(),
                                          "type_of_order": "hd",
                                          "instruction": "",
                                          "discounted_price": "",
                                          "delivery_date": formatted.toString(),
                                          "delivery_time":
                                          _timeDropdownVal.toString(),
                                          "coupon_code": "",
                                          "coupon_discount": ""
                                        }));
                                        if (res.statusCode == 200) {
                                          var data = json.decode(res.body);
                                          print(data);
                                          setState(() {
                                            _loading = false;
                                          });
                                          if (data['ErrorCode'] == 0) {
                                            Navigator.of(context)
                                                .pushNamedAndRemoveUntil(
                                                '/order-complete',
                                                    (route) => false);
                                          } else {
                                            Fluttertoast.showToast(
                                                msg: data['ErrorMessage']);
                                          }
                                        }
                                        /* } else {
                                          setState(() {
                                            _loading = false;
                                          });
                                          Fluttertoast.showToast(
                                              msg:
                                              'Please Select Payment Mode');
                                        }*/
                                      }
                                    } else {
                                      setState(() {
                                        _loading = false;
                                      });
                                      _showCouponModeDialog(context);
                                    }
                                  }
                                }
                                else if(id1 ==2){
                                  var res = await http.post(
                                    new Uri.https(BASE_URL,
                                        API_PATH + "/cash-on-delivery"),
                                    body: {
                                      "user_id": _userId.toString(),
                                      "type_of_order": "hd",
                                      "delivery_date": formatted
                                          .toString(),
                                      "delivery_time":
                                      _timeDropdownVal.toString(),
                                    },
                                    headers: {
                                      "Accept": "application/json",
                                      "authorization": basicAuth
                                    },
                                  );
                                  print(json.encode({
                                    "user_id": _userId.toString(),
                                    "type_of_order": "hd",
                                    "delivery_date": formatted
                                        .toString(),
                                    "delivery_time":
                                    _timeDropdownVal.toString(),
                                  }));
                                  if (res.statusCode == 200) {
                                    var data = json.decode(res.body);
                                    print(data);
                                    setState(() {
                                      _loading = false;
                                    });
                                    if (data['ErrorCode'] == 0) {
                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                          '/order-complete',
                                              (route) => false);
                                    } else {
                                      Fluttertoast.showToast(
                                          msg: data['ErrorMessage']);
                                    }
                                  }
                                }

                              } else {
                                setState(() {
                                  _loading = false;
                                });
                                Fluttertoast.showToast(
                                    msg: 'Please Select Payment Mode');
                              }
                            },
                            child: Container(
                              height: 60,
                              color: Theme.of(context).accentColor,
                              width: MediaQuery.of(context).size.width * 0.50,
                              // padding: EdgeInsets.only(left: 10,right: 10,top: 15,bottom: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _placeOrderBtnParent,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          } else {
            return _emptyCart();
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Container(child: CircularProgressIndicator()));
        } else {
          return Center(child: Container(child: CircularProgressIndicator()));
        }
      },
    );
  }

  bool _loading = false;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Shopping Basket'),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: RefreshIndicator(
          child: Container(
            color: Colors.grey[200],
            child: _cartListBuilder(),
          ),
          onRefresh: refreshList,
        ),
      ),
    );
  }
}
