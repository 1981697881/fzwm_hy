import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwm_hy/model/currency_entity.dart';
import 'package:fzwm_hy/model/submit_entity.dart';
import 'package:fzwm_hy/utils/handler_order.dart';
import 'package:fzwm_hy/utils/refresh_widget.dart';
import 'package:fzwm_hy/utils/text.dart';
import 'package:fzwm_hy/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'dart:io';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwm_hy/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:shared_preferences/shared_preferences.dart';

final String _fontFamily = Platform.isWindows ? "Roboto" : "";

class AllocationDetail extends StatefulWidget {
  var FBillNo;

  AllocationDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _RetrievalDetailState createState() => _RetrievalDetailState(FBillNo);
}

class _RetrievalDetailState extends State<AllocationDetail> {
  var _remarkContent = new TextEditingController();
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  GlobalKey<TextWidgetState> textKey = GlobalKey();
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var isSubmit = false;
  var show = false;
  var isScanWork = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var fBarCodeList;
  var stockList = [];
  List<dynamic> stockListObj = [];
  var organizationsList = [];
  List<dynamic> organizationsListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  final scanIcon = Icon(Icons.filter_center_focus);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var fBillNo;
  var organizationsName1;
  var organizationsNumber1;
  var organizationsName2;
  var organizationsNumber2;

  _RetrievalDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
      DateTime dateTime = DateTime.now();
      FDate =
          "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
      selectData[DateMode.YMD] = formatDate(DateTime.now(), [
        yyyy,
        "-",
        mm,
        "-",
        dd,
      ]);
      getStockList();
      getOrganizationsList();
    }
  }

  @override
  void initState() {
    super.initState();
    // 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
    EasyLoading.dismiss();
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation,FFlexNumber';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] = "FForbidStatus = 'A'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  //获取组织
  getOrganizationsList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'ORG_Organizations';
    userMap['FieldKeys'] = 'FForbidStatus,FName,FNumber,FDocumentStatus';
    userMap['FilterString'] = "FForbidStatus = 'A' and FDocumentStatus = 'C'";
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    organizationsListObj = jsonDecode(res);
    organizationsListObj.forEach((element) {
      organizationsList.add(element[1]);
    });
  }

  void getWorkShop() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.getString('FWorkShopName') != null) {
        FName = sharedPreferences.getString('FWorkShopName');
        FNumber = sharedPreferences.getString('FWorkShopNumber');
        isScanWork = true;
      } else {
        isScanWork = false;
      }
    });
  }

  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];
  List fNumber = [];

  getOrderList() async {
    EasyLoading.show(status: 'loading...');
    Map<String, dynamic> userMap = Map();
    print(fBillNo);
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'STK_TRANSFERAPPLY';
    userMap['OrderString'] = 'FMaterialId.FNumber ASC';
    userMap['FieldKeys'] =
        'FBillNo,FAPPORGID.FNumber,FAPPORGID.FName,FDate,FEntity_FEntryId,FMATERIALID.FNumber,FMATERIALID.FName,FMATERIALID.FSpecification,FOwnerTypeInIdHead,FOwnerTypeIdHead,FUNITID.FNumber,FUNITID.FName,FQty,FProduceDate,FNote,FID,FOwnerId.FNumber,FOwnerInId.FName,FStockID.FName,FStockID.FNumber,FLot.FNumber,FStockID.FIsOpenLocation,FMATERIALID.FIsBatchManage,FStockInId.FName,FStockInId.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    DateTime dateTime = DateTime.now();
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      this.fOrgID = orderDate[0][8];
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {
            "label": value[6] + "- (" + value[5] + ")",
            "value": value[5],
            "barcode": []
          }
        });
        arr.add({
          "title": "规格型号",
          "name": "FMaterialIdFSpecification",
          "isHide": false,
          "value": {"label": value[7], "value": value[7]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "调拨数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "申请数量",
          "name": "FRemainOutQty",
          "isHide": true,
          "value": {"label": value[12], "value": value[12]}
        });
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[22] != true,
          "value": {"label": value[20], "value": value[20]}
        });
        arr.add({
          "title": "调出仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": value[18], "value": value[19]}
        });
        arr.add({
          "title": "调出仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "", "hide": value[21]}
        });
        arr.add({
          "title": "调入仓库",
          "name": "FStockId",
          "isHide": false,
          "value": {"label": value[24], "value": value[25]}
        });
        arr.add({
          "title": "调出仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "", "hide": value[21]}
        });
        arr.add({
          "title": "最后扫描数量",
          "name": "FLastQty",
          "isHide": false,
          "value": {"label": "0", "value": "0"}
        });
        arr.add({
          "title": "生产日期",
          "name": "FProduceDate",
          "isHide": value[24] != true,
          "value": {
            "label": value[22] == null ? '' : value[22].substring(0, 10),
            "value": value[22] == null ? '' : value[22].substring(0, 10)
          }
        });
        arr.add({
          "title": "有效期至",
          "name": "FExpiryDate",
          "isHide": value[24] != true,
          "value": {
            "label": value[23] == null ? '' : value[23].substring(0, 10),
            "value": value[23] == null ? '' : value[23].substring(0, 10)
          }
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        hobby.add(arr);
      });
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
    }
    getStockList();
    getOrganizationsList();
  }

  void _onEvent(event) async {
    if (checkItem == 'FLoc') {
      _FNumber = event.trim();
      this._textNumber.value = _textNumber.value.copyWith(
        text: event.trim(),
      );
    } else {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var deptData = sharedPreferences.getString('menuList');
      var menuList = new Map<dynamic, dynamic>.from(jsonDecode(deptData));
      fBarCodeList = menuList['FBarCodeList'];
      if (event == "") {
        return;
      }
      if (fBarCodeList == 1) {
        Map<String, dynamic> barcodeMap = Map();
        barcodeMap['FilterString'] = "FBarCodeEn='" + event.trim() + "'";
        barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
        barcodeMap['FieldKeys'] =
            'FID,FInQtyTotal,FOutQtyTotal,FEntity_FEntryId,FRemainQty,FBarCodeQty,FStock,FLoc,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FBatchNo,FStockOrgID.FNumber';
        Map<String, dynamic> dataMap = Map();
        dataMap['data'] = barcodeMap;
        String order = await CurrencyEntity.polling(dataMap);
        var barcodeData = jsonDecode(order);
        if (barcodeData.length > 0) {
          var msg = "";
          var orderIndex = 0;
          print(fNumber);
          for (var value in orderDate) {
            print(value[7]);
            print(barcodeData[0][8]);
            if (value[5] == barcodeData[0][8]) {
              msg = "";
              if (fNumber.lastIndexOf(barcodeData[0][8]) == orderIndex) {
                break;
              }
            } else {
              msg = '条码不在单据物料中';
            }
            orderIndex++;
          }
          ;
          if (msg == "") {
            _code = event;
            this.fOrgID = barcodeData[0][15];
            this.getMaterialList(
                barcodeData,
                barcodeData[0][10],
                barcodeData[0][11],
                barcodeData[0][12],
                barcodeData[0][13],
                barcodeData[0][14],
                barcodeData[0][7]);
            print("ChannelPage: $event");
          } else {
            ToastUtil.showInfo(msg);
          }
        } else {
          ToastUtil.showInfo('条码不在条码清单中');
        }
      } else {
        _code = event;
        this.getMaterialList("", _code, '', '', '', '', '');
        print("ChannelPage: $event");
      }
    }
    checkItem = '';
    print("ChannelPage: $event");
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  getMaterialList(
      barcodeData, code, fsn, fProduceDate, fExpiryDate, fBatchNo, fLoc) async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = _code.split(";");
    Map<String, dynamic> stockMap = Map();
    stockMap['FormId'] = 'BD_STOCK';
    stockMap['FieldKeys'] =
        'FStockID,FName,FNumber,FIsOpenLocation,FFlexNumber';
    stockMap['FilterString'] = "FNumber = '" +
        barcodeData[0][6].split('/')[0] +
        "' and FUseOrgId.FNumber = '" +
        barcodeData[0][15] +
        "'";
    Map<String, dynamic> stockDataMap = Map();
    stockDataMap['data'] = stockMap;
    String res = await CurrencyEntity.polling(stockDataMap);
    var stocks = jsonDecode(res);
    if (stocks.length > 0) {
      if (stocks[0][4] != null) {
        userMap['FilterString'] = "FMaterialId.FNumber='" +
            barcodeData[0][8] +
            "' and FStockID.FNumber='" +
            barcodeData[0][6].split('/')[0] +
            "' and FStockLocId." +
            stocks[0][4] +
            ".FNumber = '" +
            barcodeData[0][7] +
            "' and FLot.FNumber = '" +
            fBatchNo +
            "' and FBaseQty > 0";
      }
    } else {
      userMap['FilterString'] = "FMaterialId.FNumber='" +
          barcodeData[0][8] +
          "' and FStockID.FNumber='" +
          barcodeData[0][6].split('/')[0] +
          "' and FUseOrgId.FNumber = '" +
          deptData[1] +
          "' and FLot.FNumber = '" +
          fBatchNo +
          "' and FBaseQty > 0";
    }
    userMap['FormId'] = 'STK_Inventory';
    userMap['FieldKeys'] =
        'FMATERIALID.FName,FMATERIALID.FNumber,FMATERIALID.FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FMATERIALID.FIsBatchManage,FLot.FNumber,FStockID.FNumber,FStockID.FName,FStockLocId.' +
            stocks[0][4] +
            '.FNumber,FStockLocId.' +
            stocks[0][4] +
            '.FName,FBaseQty,FProduceDate,FExpiryDate,FMATERIALID.FIsKFPeriod';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);

    if (materialDate.length > 0) {
      var number = 0;
      var barCodeScan;
      if (fBarCodeList == 1) {
        barCodeScan = barcodeData[0];
        barCodeScan[4] = barCodeScan[4].toString();
      } else {
        barCodeScan = scanCode;
      }
      var barcodeNum = scanCode[4];
      var residue = double.parse(scanCode[4]);
      var hobbyIndex = 0;
      var errorTitle = "";
      for (var element in hobby) {
        var residue = 0.0;
        //判断是否启用批号
        if (element[5]['isHide']) {
          //不启用
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              if (element[9]['value']['hide']) {
                if (element[9]['value']['label'] == fLoc) {
                  errorTitle = "";
                } else {
                  errorTitle = "仓位不一致";
                  continue;
                }
              }
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                  number++;
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                break;
              }
              //判断条码数量
              if ((double.parse(element[3]['value']['label']) +
                          double.parse(barcodeNum)) >
                      0 &&
                  double.parse(barcodeNum) > 0) {
                //判断物料是否重复 首个下标是否对应末尾下标
                if (fNumber.indexOf(element[0]['value']['value']) ==
                    fNumber.lastIndexOf(element[0]['value']['value'])) {
                  if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                    element[3]['value']['label'] =
                        (double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum))
                            .toString();
                    element[3]['value']['value'] = element[3]['value']['label'];
                    var item = barCodeScan[0].toString() + "-" + barcodeNum;
                    element[0]['value']['kingDeeCode'].add(item);
                    element[0]['value']['scanCode'].add(code);
                    element[10]['value']['label'] = barcodeNum.toString();
                    element[10]['value']['value'] = barcodeNum.toString();
                    barcodeNum =
                        (double.parse(barcodeNum) - double.parse(barcodeNum))
                            .toString();
                    number++;
                    print(2);
                    print(element[0]['value']['kingDeeCode']);
                  }
                } else {
                  if (this.isScanWork) {
                    //判断扫描数量是否大于单据数量
                    if (double.parse(element[3]['value']['label']) >=
                        element[4]['value']['label']) {
                      continue;
                    } else {
                      //判断二维码数量是否大于单据数量
                      if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >=
                          element[4]['value']['label']) {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          var item = barCodeScan[0].toString() +
                              "-" +
                              (element[4]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                  .toString();
                          element[10]['value']['label'] = (element[9]['value']
                                      ['label'] -
                                  double.parse(element[3]['value']['label']))
                              .toString();
                          element[10]['value']['value'] = (element[9]['value']
                                      ['label'] -
                                  double.parse(element[3]['value']['label']))
                              .toString();
                          barcodeNum = (double.parse(barcodeNum) -
                                  (element[4]['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label'])))
                              .toString();
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      (element[4]['value']['label'] -
                                          double.parse(
                                              element[3]['value']['label'])))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          residue = element[4]['value']['label'] -
                              double.parse(element[3]['value']['label']);
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          number++;
                          print(1);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      } else {
                        //数量不超出
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          var item =
                              barCodeScan[0].toString() + "-" + barcodeNum;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                                  double.parse(barcodeNum))
                              .toString();
                          number++;
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    }
                  } else {
                    //判断条码是否重复
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['label']) +
                                  double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      number++;
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  }
                }
              }
              //判断是否可重复扫码
              if (scanCode.length > 4) {
                element[0]['value']['barcode'].add(code);
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        } else {
          if (element[0]['value']['value'] == barcodeData[0][8]) {
            if (element[0]['value']['barcode'].indexOf(code) == -1) {
              //判断是否启用保质期
              if (!element[11]['isHide']) {
                print(element[11]['value']['value'] != fProduceDate &&
                    element[12]['value']['value'] != fExpiryDate);
                if (element[11]['value']['value'] == fProduceDate &&
                    element[12]['value']['value'] == fExpiryDate) {
                  errorTitle = "";
                } else {
                  errorTitle = "保质期不一致";
                  continue;
                }
              }
              //判断是否启用仓位
              if (element[9]['value']['hide']) {
                if (element[9]['value']['label'] == fLoc) {
                  errorTitle = "";
                } else {
                  errorTitle = "仓位不一致";
                  continue;
                }
              }
              //启用批号
              if (scanCode[5] == "N") {
                if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                  if (element[5]['value']['value'] == "") {
                    element[5]['value']['label'] = fBatchNo;
                    element[5]['value']['value'] = fBatchNo;
                  }
                  element[3]['value']['label'] =
                      (double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum))
                          .toString();
                  element[3]['value']['value'] = element[3]['value']['label'];
                  var item = barCodeScan[0].toString() + "-" + barcodeNum;
                  element[0]['value']['kingDeeCode'].add(item);
                  element[0]['value']['scanCode'].add(code);
                  element[10]['value']['label'] = barcodeNum.toString();
                  element[10]['value']['value'] = barcodeNum.toString();
                  barcodeNum =
                      (double.parse(barcodeNum) - double.parse(barcodeNum))
                          .toString();
                  number++;
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
                break;
              }
              if (element[5]['value']['value'] == fBatchNo) {
                //判断条码数量
                if ((double.parse(element[3]['value']['label']) +
                            double.parse(barcodeNum)) >
                        0 &&
                    double.parse(barcodeNum) > 0) {
                  //判断物料是否重复 首个下标是否对应末尾下标
                  if (fNumber.indexOf(element[0]['value']['value']) ==
                      fNumber.lastIndexOf(element[0]['value']['value'])) {
                    if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                      element[3]['value']['label'] =
                          (double.parse(element[3]['value']['label']) +
                                  double.parse(barcodeNum))
                              .toString();
                      element[3]['value']['value'] =
                          element[3]['value']['label'];
                      var item = barCodeScan[0].toString() + "-" + barcodeNum;
                      element[10]['value']['label'] = barcodeNum.toString();
                      element[10]['value']['value'] = barcodeNum.toString();
                      element[0]['value']['kingDeeCode'].add(item);
                      element[0]['value']['scanCode'].add(code);
                      barcodeNum =
                          (double.parse(barcodeNum) - double.parse(barcodeNum))
                              .toString();
                      number++;
                      print(2);
                      print(element[0]['value']['kingDeeCode']);
                    }
                  } else {
                    if (this.isScanWork) {
                      //判断扫描数量是否大于单据数量
                      if (double.parse(element[3]['value']['label']) >=
                          element[4]['value']['label']) {
                        continue;
                      } else {
                        //判断二维码数量是否大于单据数量
                        if ((double.parse(element[3]['value']['label']) +
                                double.parse(barcodeNum)) >=
                            element[4]['value']['label']) {
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            var item = barCodeScan[0].toString() +
                                "-" +
                                (element[4]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label']))
                                    .toString();
                            element[10]['value']['label'] = (element[9]['value']
                                        ['label'] -
                                    double.parse(element[3]['value']['label']))
                                .toString();
                            element[10]['value']['value'] = (element[9]['value']
                                        ['label'] -
                                    double.parse(element[3]['value']['label']))
                                .toString();
                            barcodeNum = (double.parse(barcodeNum) -
                                    (element[4]['value']['label'] -
                                        double.parse(
                                            element[3]['value']['label'])))
                                .toString();
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['label']) +
                                        (element[4]['value']['label'] -
                                            double.parse(
                                                element[3]['value']['label'])))
                                    .toString();
                            element[3]['value']['value'] =
                                element[3]['value']['label'];
                            residue = element[4]['value']['label'] -
                                double.parse(element[3]['value']['label']);
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            number++;
                            print(1);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        } else {
                          //数量不超出
                          //判断条码是否重复
                          if (element[0]['value']['scanCode'].indexOf(code) ==
                              -1) {
                            element[3]['value']['label'] =
                                (double.parse(element[3]['value']['label']) +
                                        double.parse(barcodeNum))
                                    .toString();
                            element[3]['value']['value'] =
                                element[3]['value']['label'];
                            var item =
                                barCodeScan[0].toString() + "-" + barcodeNum;
                            element[0]['value']['kingDeeCode'].add(item);
                            element[0]['value']['scanCode'].add(code);
                            barcodeNum = (double.parse(barcodeNum) -
                                    double.parse(barcodeNum))
                                .toString();
                            number++;
                            print(2);
                            print(element[0]['value']['kingDeeCode']);
                          }
                        }
                      }
                    } else {
                      //判断条码是否重复
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['label']) +
                                    double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        number++;
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    }
                  }
                }
                //判断是否可重复扫码
                if (scanCode.length > 4) {
                  element[0]['value']['barcode'].add(code);
                }
              } else {
                if (element[5]['value']['value'] == "") {
                  element[5]['value']['label'] = fBatchNo;
                  element[5]['value']['value'] = fBatchNo;
                  //判断条码数量
                  if ((double.parse(element[3]['value']['label']) +
                              double.parse(barcodeNum)) >
                          0 &&
                      double.parse(barcodeNum) > 0) {
                    //判断物料是否重复 首个下标是否对应末尾下标
                    if (fNumber.indexOf(element[0]['value']['value']) ==
                        fNumber.lastIndexOf(element[0]['value']['value'])) {
                      if (element[0]['value']['scanCode'].indexOf(code) == -1) {
                        element[3]['value']['label'] =
                            (double.parse(element[3]['value']['label']) +
                                    double.parse(barcodeNum))
                                .toString();
                        element[3]['value']['value'] =
                            element[3]['value']['label'];
                        var item = barCodeScan[0].toString() + "-" + barcodeNum;
                        element[10]['value']['label'] = barcodeNum.toString();
                        element[10]['value']['value'] = barcodeNum.toString();
                        element[0]['value']['kingDeeCode'].add(item);
                        element[0]['value']['scanCode'].add(code);
                        barcodeNum = (double.parse(barcodeNum) -
                                double.parse(barcodeNum))
                            .toString();
                        number++;
                        print(2);
                        print(element[0]['value']['kingDeeCode']);
                      }
                    } else {
                      if (this.isScanWork) {
                        //判断扫描数量是否大于单据数量
                        if (double.parse(element[3]['value']['label']) >=
                            element[4]['value']['label']) {
                          continue;
                        } else {
                          //判断二维码数量是否大于单据数量
                          if ((double.parse(element[3]['value']['label']) +
                                  double.parse(barcodeNum)) >=
                              element[4]['value']['label']) {
                            //判断条码是否重复
                            if (element[0]['value']['scanCode'].indexOf(code) ==
                                -1) {
                              var item = barCodeScan[0].toString() +
                                  "-" +
                                  (element[4]['value']['label'] -
                                          double.parse(
                                              element[3]['value']['label']))
                                      .toString();
                              element[10]['value']['label'] = (element[9]
                                          ['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                  .toString();
                              element[10]['value']['value'] = (element[9]
                                          ['value']['label'] -
                                      double.parse(
                                          element[3]['value']['label']))
                                  .toString();
                              barcodeNum = (double.parse(barcodeNum) -
                                      (element[4]['value']['label'] -
                                          double.parse(
                                              element[3]['value']['label'])))
                                  .toString();
                              element[3]['value']['label'] =
                                  (double.parse(element[3]['value']['label']) +
                                          (element[4]['value']['label'] -
                                              double.parse(element[3]['value']
                                                  ['label'])))
                                      .toString();
                              element[3]['value']['value'] =
                                  element[3]['value']['label'];
                              residue = element[4]['value']['label'] -
                                  double.parse(element[3]['value']['label']);
                              element[0]['value']['kingDeeCode'].add(item);
                              element[0]['value']['scanCode'].add(code);
                              number++;
                              print(1);
                              print(element[0]['value']['kingDeeCode']);
                            }
                          } else {
                            //数量不超出
                            //判断条码是否重复
                            if (element[0]['value']['scanCode'].indexOf(code) ==
                                -1) {
                              element[3]['value']['label'] =
                                  (double.parse(element[3]['value']['label']) +
                                          double.parse(barcodeNum))
                                      .toString();
                              element[3]['value']['value'] =
                                  element[3]['value']['label'];
                              var item =
                                  barCodeScan[0].toString() + "-" + barcodeNum;
                              element[10]['value']['label'] =
                                  barcodeNum.toString();
                              element[10]['value']['value'] =
                                  barcodeNum.toString();
                              element[0]['value']['kingDeeCode'].add(item);
                              element[0]['value']['scanCode'].add(code);
                              barcodeNum = (double.parse(barcodeNum) -
                                      double.parse(barcodeNum))
                                  .toString();
                              number++;
                              print(2);
                              print(element[0]['value']['kingDeeCode']);
                            }
                          }
                        }
                      } else {
                        //判断条码是否重复
                        if (element[0]['value']['scanCode'].indexOf(code) ==
                            -1) {
                          element[3]['value']['label'] =
                              (double.parse(element[3]['value']['label']) +
                                      double.parse(barcodeNum))
                                  .toString();
                          element[3]['value']['value'] =
                              element[3]['value']['label'];
                          var item =
                              barCodeScan[0].toString() + "-" + barcodeNum;
                          element[10]['value']['label'] = barcodeNum.toString();
                          element[10]['value']['value'] = barcodeNum.toString();
                          element[0]['value']['kingDeeCode'].add(item);
                          element[0]['value']['scanCode'].add(code);
                          barcodeNum = (double.parse(barcodeNum) -
                                  double.parse(barcodeNum))
                              .toString();
                          number++;
                          print(2);
                          print(element[0]['value']['kingDeeCode']);
                        }
                      }
                    }
                  }
                  //判断是否可重复扫码
                  if (scanCode.length > 4) {
                    element[0]['value']['barcode'].add(code);
                  }
                }
              }
            } else {
              number++;
              ToastUtil.showInfo('该标签已扫描');
              break;
            }
          }
        }
      }
      setState(() {
        EasyLoading.dismiss();
      });
      if (number == 0 && this.fBillNo == "") {
        for (var value in materialDate) {
          List arr = [];
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[0] + "- (" + value[1] + ")",
              "value": value[1],
              "barcode": [_code],
              "kingDeeCode": [barCodeScan[0].toString() + "-" + barcodeNum],
              "scanCode": [barCodeScan[0].toString() + "-" + barcodeNum],
              "codeList": []
            }
          });
          Map<String, dynamic> barcodeMap = Map();
          barcodeMap['FilterString'] = "FMATERIALID.FNUMBER='" +
              value[1] +
              "' and FRemainQty>0 and FBatchNo='" +
              value[6] +
              "' and FStock='" +
              value[7] +
              "/" +
              value[8] +
              "'";
          barcodeMap['FormId'] = 'QDEP_Cust_BarCodeList';
          barcodeMap['FieldKeys'] =
              'FID,FInQtyTotal,FOutQtyTotal,FRemainQty,FBarCodeQty,FStock,FLoc,FMATERIALID.FNUMBER,FOwnerID.FNumber,FBarCode,FSN,FProduceDate,FExpiryDate,FStockOrgID.FNumber,FBarCodeEn';
          Map<String, dynamic> barcodeDataMap = Map();
          barcodeDataMap['data'] = barcodeMap;
          String order = await CurrencyEntity.polling(barcodeDataMap);
          var barcodeData = jsonDecode(order);
          if (barcodeData.length > 0) {
            for (var codeItem in barcodeData) {
              if (codeItem[0] == barCodeScan[0]) {
                codeItem.add(0);
                arr[0]['value']['codeList'].add(codeItem);
              } else {
                codeItem.add(1);
                arr[0]['value']['codeList'].add(codeItem);
              }
            }
          }
          arr.add({
            "title": "规格型号",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[2], "value": value[2]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[3], "value": value[3]}
          });
          arr.add({
            "title": "调拨数量",
            "name": "FRemainOutQty",
            "isHide": false,
            "value": {"label": barcodeNum, "value": barcodeNum}
          });
          arr.add({
            "title": "申请数量",
            "name": "FRealQty",
            "isHide": true,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[5] != true,
            "value": {"label": value[6], "value": value[6]}
          });
          arr.add({
            "title": "调出仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": value[8], "value": value[7]}
          });
          arr.add({
            "title": "调出仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": value[9], "value": value[10], "hide": false}
          });
          arr.add({
            "title": "调入仓库",
            "name": "FStockID",
            "isHide": false,
            "value": {"label": "", "value": "", "dimension": stocks[0][4]}
          });
          arr.add({
            "title": "调入仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": true}
          });
          arr.add({
            "title": "最后扫描数量",
            "name": "FLastQty",
            "isHide": false,
            "value": {
              "label": barcodeNum.toString(),
              "value": barcodeNum.toString()
            }
          });
          arr.add({
            "title": "生产日期",
            "name": "FProduceDate",
            "isHide": value[14] != true,
            "value": {
              "label": value[12] == null ? '' : value[12].substring(0, 10),
              "value": value[12] == null ? '' : value[12].substring(0, 10)
            }
          });
          arr.add({
            "title": "有效期至",
            "name": "FExpiryDate",
            "isHide": value[14] != true,
            "value": {
              "label": value[13] == null ? '' : value[13].substring(0, 10),
              "value": value[13] == null ? '' : value[13].substring(0, 10)
            }
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          hobby.add(arr);
        }
        ;
      }
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
    }
  }

  Widget _item(title, var data, selectData, hobby, {String? label, var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () => data.length > 0
                ? _onClickItem(data, selectData, hobby,
                    label: label, stock: stock)
                : {ToastUtil.showInfo('无数据')},
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              MyText(selectData.toString() == "" ? '暂无' : selectData.toString(),
                  color: Colors.grey, rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  Widget _dateItem(title, model) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18);
              }),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (FDate == '' || FDate == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(FDate))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() async {
          switch (model) {
            case DateMode.YMD:
              Map<String, dynamic> userMap = Map();
              selectData[model] = '${p.year}-${p.month}-${p.day}';
              FDate = '${p.year}-${p.month}-${p.day}';
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby,
      {String? label, var stock}) {
    Pickers.showSinglePicker(
      context,
      data: data,
      selectData: selectData,
      pickerStyle: DefaultPickerStyle(),
      suffix: label,
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        print('longer >>> 返回数据类型：${p.runtimeType}');
        setState(() {
          if (hobby == 'organizations1') {
            organizationsName1 = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber1 = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else if (hobby == 'organizations2') {
            organizationsName2 = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                organizationsNumber2 = organizationsListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else {
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[12]['value']['hide'] = stockListObj[elementIndex][3];
                hobby['value']['dimension'] = stockListObj[elementIndex][4];
              }
              elementIndex++;
            });
          }
        });
      },
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 5) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                this._textNumber.text =
                                    this.hobby[i][j]["value"]["label"];
                                this._FNumber =
                                    this.hobby[i][j]["value"]["label"];
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                    text: this.hobby[i][j]["value"]["label"],
                                  );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else if (j == 8) {
            comList.add(
              _item('调入仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if (j == 9) {
            comList.add(
              Visibility(
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                visible: this.hobby[i][j]["value"]["hide"],
                child: Column(children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                        title: Text(this.hobby[i][j]["title"] +
                            '：' +
                            this.hobby[i][j]["value"]["label"].toString()),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: new Icon(Icons.filter_center_focus),
                                tooltip: '点击扫描',
                                onPressed: () {
                                  this._textNumber.text = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  this._FNumber = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  checkItem = 'FLoc';
                                  this.show = false;
                                  checkData = i;
                                  checkDataChild = j;
                                  scanDialog();
                                  print(this.hobby[i][j]["value"]["label"]);
                                  if (this.hobby[i][j]["value"]["label"] != 0) {
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: this
                                          .hobby[i][j]["value"]["label"]
                                          .toString(),
                                    );
                                  }
                                },
                              ),
                            ])),
                  ),
                  divider,
                ]),
              ),
            );
          } else if (j == 13) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new MaterialButton(
                              color: Colors.blue,
                              textColor: Colors.white,
                              child: new Text('选择条码'),
                              onPressed: () async {
                                await _showMultiChoiceModalBottomSheet(
                                    context, this.hobby[i]);
                                setState(() {});
                              },
                            ),
                            new MaterialButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString()),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                    ]),
                  ),
                ),
                divider,
              ]),
            );
          }
        }
      }
      tempList.add(
        SizedBox(height: 6, width: 320, child: ColoredBox(color: Colors.grey)),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }

  //调出弹窗 扫码
  void scanDialog() {
    showDialog<Widget>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  /*  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('输入数量',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),*/
                  Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Card(
                          child: Column(children: <Widget>[
                        TextField(
                          style: TextStyle(color: Colors.black87),
                          keyboardType: TextInputType.text,
                          controller: this._textNumber,
                          decoration: InputDecoration(hintText: "输入"),
                          onChanged: (value) {
                            setState(() {
                              this._FNumber = value;
                            });
                          },
                        ),
                      ]))),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          setState(() {
                            this.hobby[checkData][checkDataChild]["value"]
                                ["label"] = _FNumber;
                            this.hobby[checkData][checkDataChild]['value']
                                ["value"] = _FNumber;
                          });
                        },
                        child: Text(
                          '确定',
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).then((val) {
      print(val);
    });
  }

  Widget _getModalSheetHeaderWithConfirm(String title,
      {required Function onCancel, required Function onConfirm}) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              onCancel();
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
          ),
          IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.blue,
              ),
              onPressed: () {
                onConfirm();
              }),
        ],
      ),
    );
  }

  Future<List<int>?> _showMultiChoiceModalBottomSheet(
      BuildContext context, List<dynamic> options) async {
    List selected = [];
    var selectList = options[0]["value"]["codeList"];
    for (var select in selectList) {
      if (select[15] == 0) {
        selected.add(select);
      } else {
        selected.remove(select);
      }
    }
    return showModalBottomSheet<List<int>?>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context1, setState) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
              ),
            ),
            height: MediaQuery.of(context).size.height / 2.0,
            child: Column(children: [
              _getModalSheetHeaderWithConfirm(
                '条码选择',
                onCancel: () {
                  Navigator.of(context).pop();
                },
                onConfirm: () async {
                  options[0]["value"]["kingDeeCode"] = [];
                  options[0]["value"]["scanCode"] = [];
                  options[0]["value"]["barcode"] = [];
                  var count = 0.0;
                  for (var select in selectList) {
                    if (select[15] == 0) {
                      options[0]["value"]["kingDeeCode"].add(
                          select[0].toString() + "-" + select[4].toString());
                      options[0]["value"]["scanCode"].add(
                          select[0].toString() + "-" + select[4].toString());
                      options[0]["value"]["barcode"].add(select[14]);
                      count += select[4];
                    }
                  }
                  options[3]["value"]["label"] = count;
                  options[3]["value"]["value"] = count;
                  Navigator.of(context).pop(); /*selected.toList()*/
                },
              ),
              Divider(height: 1.0),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      trailing: Icon(
                          selectList[index][15] == 0
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Theme.of(context).primaryColor),
                      title: Text(selectList[index][0].toString() +
                          '*' +
                          selectList[index][5] +
                          '*' +
                          selectList[index][6] +
                          '*' +
                          selectList[index][4].toString() +
                          '*' +
                          selectList[index][15].toString()),
                      onTap: () {
                        setState(() {
                          if (selectList[index][15] == 1) {
                            var number = 0;
                            for (var element in hobby) {
                              if (element[0]['value']['barcode'].indexOf(selectList[index][14]) == -1) {
                                number++;
                              }
                            }
                            if(number>0){
                              selectList[index][15] = 0;
                              selected.add(selectList[index]);
                            }else{
                              ToastUtil.showInfo('该条码已被其他项使用');
                            }
                          } else {
                            selectList[index][15] = 1;
                            selected.remove(selectList[index]);
                          }

                          print(selectList[index]);
                          /*if (selected.contains(index)) {
                            selected.remove(index);
                          } else {
                            selected.add(index);
                          }*/
                        });
                      },
                    );
                  },
                  itemCount: selectList.length,
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'STK_TransferDirect';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FBillTypeID'] = {"FNUMBER": "ZJDB01_SYS"};
      Model['FDate'] = FDate;
      //获取登录信息
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      //判断有源单 无源单
      if (this.isScanWork) {
        Model['FStockOrgId'] = {"FNumber": orderDate[0][8].toString()};
        Model['FStockOutOrgId'] = {"FNumber": orderDate[0][8].toString()};
      } else {
        Model['FStockOrgId'] = {"FNumber": this.fOrgID};
        Model['FStockOutOrgId'] = {"FNumber": this.fOrgID};
      }
      Model['FOwnerTypeIdHead'] = "BD_OwnerOrg";
      Model['FTransferBizType'] = "InnerOrgTransfer";
      Model['FOwnerTypeOutIdHead'] = "BD_OwnerOrg";
      Model['FTransferDirect'] = "GENERAL";
      Model['FOwnerOutIdHead'] = {"FNumber": this.organizationsNumber1};
      Model['FOwnerIdHead'] = {"FNumber": this.organizationsNumber2};
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[6]['value']['value'] != '0') {
          Map<String, dynamic> FEntityItem = Map();

          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FOwnerTypeId'] = "BD_OwnerOrg";
          FEntityItem['FOwnerId'] = {"FNumber": this.organizationsNumber2};
          FEntityItem['FOwnerTypeOutId'] = "BD_OwnerOrg";
          FEntityItem['FOwnerOutId'] = {"FNumber": this.organizationsNumber1};
          FEntityItem['FKeeperTypeId'] = "BD_KeeperOrg";
          FEntityItem['FKeeperId'] = {"FNumber": deptData[0]};
          FEntityItem['FKeeperTypeOutId'] = "BD_KeeperOrg";
          ;
          FEntityItem['FKeeperOutId'] = {"FNumber": deptData[0]};

          FEntityItem['FMaterialId'] = {
            "FNumber": element[0]['value']['value']
          };
          FEntityItem['FUnitID'] = {"FNumber": element[2]['value']['value']};
          FEntityItem['FBaseUnitId'] = {
            "FNumber": element[2]['value']['value']
          };
          FEntityItem['FSrcStockId'] = {
            "FNumber": element[6]['value']['value']
          };
          if (element[8]['value']['dimension'] != null) {
            FEntityItem['FSrcStockLocId'] = {
              "FSRCSTOCKLOCID__" + element[8]['value']['dimension']: {
                "FNumber": element[7]['value']['value']
              }
            };
          }
          FEntityItem['FDestStockId'] = {
            "FNumber": element[8]['value']['value']
          };
          if (element[8]['value']['dimension'] != null) {
            FEntityItem['FDestStockLocId'] = {
              "FDESTSTOCKLOCID__" + element[8]['value']['dimension']: {
                "FNumber": element[9]['value']['value']
              }
            };
          }
          FEntityItem['FLot'] = {"FNumber": element[5]['value']['value']};
          FEntityItem['FQty'] = element[3]['value']['value'];
          /*FEntityItem['FEntity_Link'] = [
            {
              "FEntity_Link_FRuleId": "DeliveryNotice-OutStock",
              "FEntity_Link_FSTableName": "T_STK_TRANSFERAPPLYENTRY",
              "FEntity_Link_FSBillId": orderDate[hobbyIndex][15],
              "FEntity_Link_FSId": orderDate[hobbyIndex][4],
              "FEntity_Link_FSALBASEQTY": element[8]['value']['value']
            }
          ];*/
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,仓库');
        return;
      }
      Model['FBillEntry'] = FEntity;
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      var saveData = jsonEncode(dataMap);
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "STK_TransferDirect",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(context, submitMap, 1, "STK_TransferDirect",
                SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(context, submitMap, 1,
                    "STK_TransferDirect", SubmitEntity.audit(submitMap))
                .then((auditResult) async {
              if (auditResult) {
                var errorMsg = "";
                if (fBarCodeList == 1) {
                  for (int i = 0; i < this.hobby.length; i++) {
                    if (this.hobby[i][3]['value']['value'] != '0') {
                      var kingDeeCode =
                          this.hobby[i][0]['value']['kingDeeCode'];
                      for (int j = 0; j < kingDeeCode.length; j++) {
                        Map<String, dynamic> dataCodeMap = Map();
                        dataCodeMap['formid'] = 'QDEP_Cust_BarCodeList';
                        Map<String, dynamic> orderCodeMap = Map();
                        orderCodeMap['NeedReturnFields'] = [];
                        orderCodeMap['IsDeleteEntry'] = false;
                        Map<String, dynamic> codeModel = Map();
                        var itemCode = kingDeeCode[j].split("-");
                        codeModel['FID'] = itemCode[0];
                        for (var j = 0; j < 2; j++) {
                          if (j == 0) {
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FOutQty'] = itemCode[1];
                            codeFEntityItem['FEntryStockID'] = {
                              "FNUMBER": this.hobby[i][6]['value']['value']
                            };
                            if (this.hobby[i][8]['value']['dimension'] !=
                                null) {
                              codeFEntityItem['FStockLocID'] = {
                                "FSTOCKLOCID__" +
                                    this.hobby[i][8]['value']['dimension']: {
                                  "FNumber": this.hobby[i][7]['value']['value']
                                }
                              };
                            }

                            var codeFEntity = [codeFEntityItem];
                            codeModel['FEntity'] = codeFEntity;
                            orderCodeMap['Model'] = codeModel;
                            dataCodeMap['data'] = orderCodeMap;
                            print(dataCodeMap);
                            String codeRes =
                                await SubmitEntity.save(dataCodeMap);
                            var barcodeRes = jsonDecode(codeRes);
                            if (!barcodeRes['Result']['ResponseStatus']
                                ['IsSuccess']) {
                              errorMsg += "错误反馈：" +
                                  itemCode[1] +
                                  ":" +
                                  barcodeRes['Result']['ResponseStatus']
                                      ['Errors'][0]['Message'];
                            }
                            print(codeRes);
                          } else {
                            codeModel['FOwnerID'] = {
                              "FNUMBER": this.organizationsNumber2
                            };
                            codeModel['FStockOrgID'] = {
                              "FNUMBER": orderDate[i][8].toString()
                            };
                            codeModel['FStockID'] = {
                              "FNUMBER": this.hobby[i][8]['value']['value']
                            };
                            /*codeModel['FLastCheckTime'] = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd,]);*/
                            Map<String, dynamic> codeFEntityItem = Map();
                            codeFEntityItem['FBillDate'] = FDate;
                            codeFEntityItem['FInQty'] = itemCode[1];
                            //codeFEntityItem['FEntryBillNo'] = orderDate[i][0];
                            codeFEntityItem['FEntryStockID'] = {
                              "FNUMBER": this.hobby[i][8]['value']['value']
                            };
                            if (this.hobby[i][8]['value']['dimension'] !=
                                null) {
                              codeFEntityItem['FStockLocID'] = {
                                "FSTOCKLOCID__" +
                                    this.hobby[i][8]['value']['dimension']: {
                                  "FNumber": this.hobby[i][9]['value']['value']
                                }
                              };
                            }
                            var codeFEntity = [codeFEntityItem];
                            codeModel['FEntity'] = codeFEntity;
                            orderCodeMap['Model'] = codeModel;
                            dataCodeMap['data'] = orderCodeMap;
                            print(dataCodeMap);
                            String codeRes =
                                await SubmitEntity.save(dataCodeMap);
                            var barcodeRes = jsonDecode(codeRes);
                            if (!barcodeRes['Result']['ResponseStatus']
                                ['IsSuccess']) {
                              errorMsg += "错误反馈：" +
                                  itemCode[1] +
                                  ":" +
                                  barcodeRes['Result']['ResponseStatus']
                                      ['Errors'][0]['Message'];
                            }
                            print(codeRes);
                          }
                        }
                      }
                    }
                  }
                }
                if (errorMsg != "") {
                  ToastUtil.errorDialog(context, errorMsg);
                  this.isSubmit = false;
                }
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.FBillNo = '';
                  ToastUtil.showInfo('提交成功');
                  Navigator.of(context).pop("refresh");
                });
              } else {
                //失败后反审
                HandlerOrder.orderHandler(context, submitMap, 0,
                        "STK_TransferDirect", SubmitEntity.unAudit(submitMap))
                    .then((unAuditResult) {
                  if (unAuditResult) {
                    this.isSubmit = false;
                  } else {
                    this.isSubmit = false;
                  }
                });
              }
            });
          } else {
            this.isSubmit = false;
          }
        });
      } else {
        setState(() {
          this.isSubmit = false;
          ToastUtil.errorDialog(
              context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
        });
      }
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }

  /// 确认提交提示对话框
  Future<void> _showSumbitDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("是否提交"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('不了'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                  saveOrder();
                },
              )
            ],
          );
        });
  }

  //扫码函数,最简单的那种
  Future scan() async {
    String cameraScanResult = await scanner.scan(); //通过扫码获取二维码中的数据
    getScan(cameraScanResult); //将获取到的参数通过HTTP请求发送到服务器
    print(cameraScanResult); //在控制台打印
  }

//用于验证数据(也可以在控制台直接打印，但模拟器体验不好)
  void getScan(String scan) async {
    _onEvent(scan);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: scan,
            tooltip: 'Increment',
            child: Icon(Icons.filter_center_focus),
          ),
          appBar: AppBar(
            title: Text("调拨"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  /*Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("单号：$FBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),*/
                  _dateItem('日期：', DateMode.YMD),
                  _item('调出货主', this.organizationsList, this.organizationsName1,
                      'organizations1'),
                  _item('调入货主', this.organizationsList, this.organizationsName2,
                      'organizations2'),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "备注",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._remarkContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _remarkContent.value = TextEditingValue(
                                    text: value,
                                    selection: TextSelection.fromPosition(
                                        TextPosition(
                                            affinity: TextAffinity.downstream,
                                            offset: value.length)));
                              });
                            },
                          ),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: this._getHobby(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async =>
                            this.isSubmit ? null : _showSumbitDialog(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
